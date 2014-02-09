<!--- 

	handle incoming files
	
	this component communicates with the master server
	and updates the master with status information etc
	
	mostly based on the original upload.cfc

 --->

<cfcomponent output="false" hint="general incoming routines">
	
	<cfinclude template="/inc/scripts.cfm">

	<cffunction access="public" name="init" returntype="processing.cfc.incoming.incoming" output="false">
		<cfreturn this />
	</cffunction>
	
	<cffunction access="public" name="InsertNewUploadItemNotification" output="false" returntype="struct"
			hint="insert new record in the database with information about an uploaded track, inform the master server about that">
		<cfargument name="userkey" type="string" required="true" />
		<cfargument name="runkey" type="string" required="true" />
		<cfargument name="librarykey" type="string" required="true" />
		<cfargument name="authkey" type="string" required="true"
			hint="authentification key" />
		<cfargument name="ip" type="string" required="true"
			hint="client IP" />
		<cfargument name="location" type="string" required="true"
			hint="the location of the file on the local hdd" />
		<cfargument name="location_metainfo" type="string" required="false" default=""
			hint="pointer to file with meta info (e.g. iTunes ratings etc)" />
		<cfargument name="filesize" type="numeric" required="true">
		<cfargument name="source" type="string" required="false" default=""
			hint="the source of this file (e.g. pointtourl, email or an app key)" />
		<cfargument name="priority" type="numeric" default="0" required="false"
			hint="the priority of this track" />
		<cfargument name="autoadd2plist" type="string" required="false" default=""
			hint="automatically add to the plist with this name" />
		
		<cfset var stReturn = GenerateReturnStruct() />
		<cfset var sJobkey = CreateUUID() />
		<cfset var stData = { userkey = arguments.userkey, runkey = arguments.runkey, librarykey = arguments.librarykey, authkey = arguments.authkey,
								location = arguments.location, filesize = arguments.filesize, jobkey = sJobkey, ip = arguments.ip } />
		<cfset var qInsertUploadedFile = 0 />
		<cfset var sOriginalHashValue = '' />
		<cfset var stGenericAddCheck = {} />
		<cfset var bHTTPError = false />
		<cfset var stUpdate = {} />
		<cfset var oQueue = application.beanFactory.getBean( 'QueueComponent' ) />
		
		<!--- check if the file exists (or if it is a valid http file ) --->
		<cfif FindNoCase( 'http://', arguments.location) IS 0 AND NOT FileExists( arguments.location )>
			<cfreturn SetReturnStructErrorCode( stReturn, 4000 ) />
		</cfif>		
		
		<!--- is it a http file? if yes, check for certain basic criteria right now --->
		<cfif FindNoCase( 'http://', arguments.location) GT 0>
			
			<cfset bHTTPError = NOT CheckPointToURLData( arguments.location ).result />
			
			<!--- return error --->
			<cfif bHTTPError>
				<cfreturn SetReturnStructErrorCode( stReturn, 4001 ) />
			</cfif>
			
		</cfif>		
		
		<!--- valid file extension? --->
		<cfif ListFindNoCase( 'mp3,wma,m4a,ogg,mp4', ListLast(arguments.location, '.')) IS 0>
			<cfreturn SetReturnStructErrorCode( stReturn, 4101 ) />
		</cfif>
		
		<!--- get *original* hash value of the file / URL location --->
		<cfif arguments.source IS 'pointtourl'>
			<cfset sOriginalHashValue = Hash( arguments.location, 'SHA' ) />
		<cfelse>
			<cfset sOriginalHashValue = application.beanFactory.getBean( 'Tools' ).getFileHash( arguments.location ) />
		</cfif>
		
		<!--- perform a lookup for this hash value as well --->
		<cfset stData.originalFileHashValue = sOriginalHashValue />
					
		<!--- inform master about uploaded track ... check against the permissions --->			
		<cfset stGenericAddCheck = application.beanFactory.getBean( 'Communication' ).TalkToMasterServer( type = 'item.add.checkrequest', data = stData ) />
		
		<cfif NOT stGenericAddCheck.result>
			<cfreturn stGenericAddCheck />
		</cfif>
		
		<cfset stReturn.stGenericAddCheck = stGenericAddCheck/>

		<!--- check against the maximal filesize allowed --->
		<cfif arguments.FileSize GT (stGenericAddCheck.stQuota.maxfilesize)>
			<!--- too big file --->
			<cfreturn SetReturnStructErrorCode(stReturn, 4101, 'Filesize exceeds limit' ) />
		</cfif>
		
		<!--- file with the same hashvalue already in the queue? --->	
		<cfif CheckFileWithSameHashValueAlreadyInTheQueue( userkey = arguments.userkey, sOriginalFileHashValue = sOriginalHashValue )>
			<cfreturn SetReturnStructErrorCode(stReturn, 4005, 'Already in the queue' ) />
		</cfif>
		
		<!--- insert information ... --->
		<cfinclude template="queries/qInsertUploadedFile.cfm">
		<cfset stReturn.sJobkey = sJobkey />
			
		<cfreturn SetReturnStructSuccessCode(stReturn) />

	</cffunction>
	
	<cffunction access="public" name="CheckFileWithSameHashValueAlreadyInTheQueue" returntype="boolean"
			hint="as the name says ...">
		<cfargument name="userkey" type="string" required="true" />
		<cfargument name="sOriginalFileHashValue" type="string" required="true" />
		
		<cfset var qSelectAlreadyInQueue = 0 />
		
		<cfquery name="qSelectAlreadyInQueue" datasource="tb_incoming">
		SELECT
			COUNT(id) AS count_items
		FROM
			uploaded_items
		WHERE
			userkey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userkey#">
			AND
			OriginalHashValue = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.sOriginalFileHashValue#">
			AND
			/* not yet done */
			done = 0
		;
		</cfquery>
		
		<cfreturn (qSelectAlreadyInQueue.count_items GT 0) />
	
	</cffunction>
	
	<cffunction access="public" name="CheckPointToURLData" output="false" returntype="struct"
			hint="check a http location if the file is OK">
		<cfargument name="location" type="string" required="true"
			hint="location to URL">
	
		<cfset var stReturn = GenerateReturnStruct() />
		<cfset var sURL = Trim( arguments.location ) />
		<cfset var cfhttp = 0 />
		<cfset var bError = true />
			
		<cftry>
	
			<cflock name="#ReturnUniqueCFLockName#" timeout="10" throwontimeout="true">
				<cfhttp method="head" url="#sURL#" timeout="5" redirect="true" result="cfhttp"></cfhttp>
			</cflock>
			
			<!--- not 200, no audio and too big --->
			<cfset bError = (cfhttp.ResponseHeader.Status_code NEQ 200) OR
								 (ListFirst(cfhttp.MimeType, '/') NEQ 'audio') OR
								 (cfhttp.ResponseHeader['Content-Length'] GT 18749312) />
								 
			<cfset stReturn.cfhttp = cfhttp />
			
			<cfif bError>
				<cfreturn SetReturnStructErrorCode( stReturn, 4001 ) />
			</cfif>
			
		<cfcatch type="any">
			
			<cfreturn SetReturnStructErrorCode( stReturn, 4001 ) />
			
		</cfcatch>
		</cftry>
		
		<cfreturn SetReturnStructSuccessCode(stReturn) />
		
	</cffunction>

	
</cfcomponent>