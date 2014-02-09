<!--- 

	tunesBag storage handling component

	upload to s3

 --->

<cfcomponent output="false" hint="general incoming routines">
	
	<cfinclude template="/inc/scripts.cfm">

	<cffunction access="public" name="init" returntype="processing.cfc.storage.storage" output="false">
		<cfreturn this />
	</cffunction>
	
	<cffunction access="public" name="submitMetaInfoToMaster" output="false" returntype="struct" hint="submit meta info to master server">
		<cfargument name="sEntrykey" type="string" required="true"
			hint="entrykey of the upload process" />
		<cfargument name="bResubmitRequest" type="boolean" required="false" default="false"
			hint="is this just a resubmit request?" />
		
		<cfset var stReturn = GenerateReturnStruct() />
		<cfset var qUploadedItem = application.beanFactory.getBean( 'UploadComponent' ).GetItemByEntrykey( sEntrykey = arguments.sEntrykey ) />
		<cfset var stMetaInfo = {} />
		<cfset var sArtworkfileContent = '' />
		<cfset var stData = {} />
		<cfset var sCol = '' />
		<cfset var local = {} />
		
		<cfif (qUploadedItem.recordcount IS 0)>
			<cfreturn SetReturnStructErrorCode(stReturn, 404, 'Job not found' ) />
		</cfif>
		
		<!--- 
		
			if not just resubmitting, check if the file still exists
		
		 --->
		<!--- <cfif NOT arguments.bResubmitRequest> --->
		
			<cfif NOT FileExists( qUploadedItem.location )>
				<cfreturn SetReturnStructErrorCode(stReturn, 404, 'File not found' ) />
			</cfif>
			
		<!--- </cfif> --->
		
		<cftry>
			
		<!--- 
		
			replace NULL characters in the text
			
			http://forums.adobe.com/thread/53705
		 --->
		<cfset QuerySetCell( qUploadedItem, 'ORIGINALID3TAGS', REReplace(qUploadedItem.ORIGINALID3TAGS,'[\x0]','','ALL'), 1) />
		<cfset QuerySetCell( qUploadedItem, 'ORIGINALID3TAGS', REReplace(qUploadedItem.ORIGINALID3TAGS,'[\x14]','','ALL'), 1) />
		<cfset QuerySetCell( qUploadedItem, 'ORIGINALID3TAGS', REReplace(qUploadedItem.ORIGINALID3TAGS,'[\x1]','','ALL'), 1) />
		<cfset QuerySetCell( qUploadedItem, 'ORIGINALID3TAGS', REReplace(qUploadedItem.ORIGINALID3TAGS,'[\x2]','','ALL'), 1) />
			
		<cfwddx action="wddx2cfml" input="#qUploadedItem.ORIGINALID3TAGS#" output="stMetaInfo" />
		
		<cfcatch type="any">
			
			<!--- an error occured --->			
			<cfmail from="support@tunesBag.com" to="support@tunesBag.com" subject="unable to wddx2cml ..." type="html">
				<cfdump var="#qUploadedItem.ORIGINALID3TAGS#">
				<cfdump var="#arguments#">
			</cfmail>
			
			<cfrethrow>
		</cfcatch>
		</cftry>
		
		<cfloop list="#qUploadedItem.columnlist#" index="sCol">
			<cfset stData[ sCol ] = qUploadedItem[ sCol ][ qUploadedItem.currentrow ] />
		</cfloop>
	
		<cfset StructAppend( stData, stMetaInfo, false ) />
	
		<!--- set hashvalue of file which is added to the library --->
		<cfset stData.hashvalue = application.beanFactory.getBean( 'Tools' ).getFileHash( qUploadedItem.location ) />
		
		<cfset stGenericAddCheck = application.beanFactory.getBean( 'Communication' ).TalkToMasterServer( type = 'item.add.success', data = stData ) />
		
		<cfreturn stGenericAddCheck />
	
	</cffunction>
	
	<cffunction access="public" name="PerformS3Upload" output="false" returntype="struct" hint="try to upload file to s3">
		<cfargument name="sUploadkey" type="string" required="true"
			hint="entrykey of the upload process" />
			
		<cfset var qSelectJob = 0 />
		<cfset var stReturn = GenerateReturnStruct() />
		<cfset var cfhttp = 0 />
		<cfset var sHTTPResult = '' />
		<cfset var binaryFileData = 0 />
		<cfset var stUploadStorageRequest = {} />
		<cfset var stStorageInfo = {} />
		<cfset var qInsertUploadLog = 0 />
		
		<cfinclude template="queries/qSelectS3Job.cfm">
	
		<cfif (qSelectJob.recordcount IS 0)>
			<cfreturn SetReturnStructErrorCode(stReturn, 1002, 'File already handled') />
		</cfif>
		
		<cfif NOT FileExists( qSelectJob.filelocation )>
			<cflog application="false" file="tb_s3_error" log="Application" type="warning" text="error: #qSelectJob.uploadkey# ... Files does not exist #qSelectJob.filelocation#" />
			<cfreturn SetReturnStructErrorCode(stReturn, 1002, 'File ' & qSelectJob.filelocation & ' does not exist.' ) />
		</cfif>
		
		<!--- read the media file --->
		<cffile action="readBinary" file="#qSelectJob.filelocation#" variable="binaryFileData">
		
		<!--- generate signature --->
		<cfset stUploadStorageRequest = {
				userkey = qSelectJob.userkey,
				uploadkey = qSelectJob.uploadkey,
				hashvalue = application.beanFactory.getBean( 'Tools' ).getFileHash( qSelectJob.filelocation )
				} />	
			
		<!--- get the storage info from the master server --->					
		<cfset stStorageInfo = application.beanFactory.getBean( 'Communication' ).TalkToMasterServer( type = 'item.add.requeststoragepath', data = stUploadStorageRequest ) />
		
		<cfset stReturn.stStorageInfo = stStorageInfo />
		
		<cfif NOT stStorageInfo.result>
			<cfreturn stStorageinfo />
		</cfif>
		
		<!--- log information received by master --->
		<cfquery name="qInsertUploadLog" datasource="tb_incoming">
		UPDATE
			s3uploadqueue
		SET
			s3uploadinfo = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#SerializeJSON( stStorageInfo )#">
		WHERE
			uploadkey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qSelectJob.uploadkey#">
		;
		</cfquery>
				
		<cftry>
			
			<cfhttp method="PUT" url="#stStorageInfo.sURL#" timeout="240" result="cfhttp">
				  <!--- auth + date have just been generated --->
			  	  <cfhttpparam type="header" name="Authorization" value="#stStorageInfo.Authorization#">
				  <cfhttpparam type="header" name="Date" value="#stStorageInfo.sDate#">
				  <!--- file + content type --->
				  <cfhttpparam type="header" name="Content-Type" value="#stStorageInfo.contenttype#">
				  <cfhttpparam type="body" value="#binaryFileData#">
			</cfhttp>
			
			<cfset sHTTPResult = cfhttp.StatusCode />
			
			<cfset stReturn.stHttp = cfhttp />
			
			<!--- error? --->
			<cfif FindNoCase('200', sHTTPResult) IS 1>
			
				<!--- neverything's fine --->	
				<cflog application="false" file="tb_s3_success" log="Application" type="information" text="success: #qSelectJob.uploadkey# (#stStorageInfo.sURL#)" />
			
			<cfelse>
			
				<!--- an error occured! --->
				<cflog application="false" file="tb_s3_error" log="Application" type="warning" text="error: #qSelectJob.uploadkey# (#SerializeJSON( cfhttp )#)" />
			
				<cfreturn SetReturnStructErrorCode(stReturn, 1100, 'Upload error ' & cfhttp.StatusCode) />
			
			</cfif>
		
			<cfcatch type="any">
				
				<!--- failed ... --->
				<cflog application="false" file="tb_s3_error" log="Application" type="fatal" text="error: #qSelectJob.uploadkey# (#SerializeJSON( cfcatch )#)" />

				<cfreturn SetReturnStructErrorCode(stReturn, 1100, 'Upload error ' & cfcatch.Message ) />
				
			</cfcatch>
		</cftry>
		
		<cfreturn SetReturnStructSuccessCode( stReturn ) />	
	
	</cffunction>	
	
</cfcomponent>