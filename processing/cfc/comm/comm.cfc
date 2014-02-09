<!--- 

	communications

 --->

<cfcomponent output="false" hint="general incoming routines">
	
	<cfinclude template="/inc/scripts.cfm">

	<cffunction access="public" name="init" returntype="processing.cfc.comm.comm" output="false">
		<cfreturn this />
	</cffunction>
	
	<cffunction access="public" name="CalcRequestHash" output="false" returntype="string">
		<cfargument name="data" type="struct" required="true"
			hint="data to sign" />
			
		<cfset var sResult = '' />
		<cfset var sIndex = '' />
		<cfset var ii = 0 />
		<cfset var sKeys = ListSort( StructKeyList( arguments.data ), 'textnocase') />
				
		<cfloop from="1" to="#ListLen( sKeys)#" index="ii">
			
			<cfset sIndex = ListGetAt( sKeys, ii ) />
			
			<cfset sResult = sResult & lcase( sIndex) & lcase( arguments.data[ sIndex ] ) />
		</cfloop>
		
		<cfset sResult = Hash( sResult & 'is9g9u9q+ßvvlwr', 'sha1' ) />
		
		<cfreturn sResult />
			
	</cffunction>
	
	<cffunction access="public" name="TalkToMasterServer" output="false" returntype="struct"
			hint="generic routine to communicate with master">
		<cfargument name="type" type="string" required="true" hint="type of information">
		<cfargument name="data" type="struct" required="true" hint="information to transmit (string only)">
		<cfargument name="delayed" type="boolean" default="false" required="false"
			hint="submit this information immediately or submit it later ... not supported yet" />
		
		<cfset var stReturn = GenerateReturnStruct() />
		<cfset var cfhttp = 0 />
		<cfset var a_str_url = '' />
		<cfset var stResponse = {} />
		<cfset var sIndex = '' />
		<cfset var inet = CreateObject("java", "java.net.InetAddress") />
		<cfset var sContent = '' />
		<cfset var sSignature = '' />
		<cfset var local = {} />
		
		<cfset inet = inet.getLocalHost()>
		
		<!--- add all parameters to the data structure --->
		<cfset arguments.data.type = arguments.type />
		<cfset arguments.data.hostname = inet.getHostName() />
		<cfset arguments.data.hostip = inet.getHostAddress() />
				
		<!--- sign the request ... --->
		<cfset sSignature =	CalcRequestHash( arguments.data ) />
		
		<!--- log! --->
		<cflog application="false" file="tb_comm_to_master" log="Application" text="#GetMasterServer()# #SerializeJSON( arguments.data )#" type="information" />
		
		<cftry>
			<cflock name="#createUUID()#" timeout="30" throwontimeout="true">
			
				<!--- transmit information --->
				
				<!--- todo: use real server --->
				<cfhttp charset="utf-8" username="tb" password="tb2009"
						method="post" result="cfhttp" url="#GetMasterServer()#/james/?event=remote.incoming.request&signature=#sSignature#" redirect="false">
					
					<!--- submit the signature in the header --->
					<!--- <cfhttpparam type="header" name="X-Signature" value="#sSignature#"> --->
					
					<!--- submit all fields as FORM fields --->
					<cfloop list="#StructKeyList( arguments.data )#" index="sIndex">
						<cfhttpparam type="formfield" name="#sIndex#" value="#arguments.data[ sIndex ]#" />
					</cfloop>
					
				</cfhttp>
				
				<!--- perform a check --->
				<cfif FindNoCase( '200', cfhttp.StatusCode ) NEQ 1>
					<cfreturn SetReturnStructErrorCode(stReturn, 1100, cfhttp.FileContent ) />
				</cfif>
				
				<cfset stResponse = DeserializeJSON( cfhttp.FileContent ) />
				
				<!--- log request (but not all of them ...) --->
				<cfif ListFindNoCase( 'slave.queuestatus', arguments.type ) IS 0>
					<cfquery name="local.qInsertLog" datasource="tb_incoming">
					INSERT INTO
						logmastercomm
						(
						dt_created,
						masterserver,
						requesttype,
						request,
						response
						)
					VALUES
						(
						<cfqueryparam cfsqltype="cf_sql_timestamp" value="#Now()#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#Left( GetMasterServer(), 20 )#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#Left( arguments.type, 50)#">,
						<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#SerializeJSON( arguments.data )#">,
						<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#cfhttp.FileContent#">					
						)
					;
					</cfquery>
				</cfif>
				
				<!--- structure? return it ... --->
				<cfif IsStruct( stResponse )>
					<cfreturn stResponse />
				</cfif>
				
			</cflock>
		<cfcatch type="any">
			
			<!--- ignore connection refused --->
			<cfif cfcatch.Message NEQ 'Connection refused'>
				<cfmail from="office@tunesbag.com" to="office@tunesbag.com" subject="communication error" type="html">
				<p>URL: #GetMasterServer()#/james/?event=remote.incoming.request&signature=#sSignature#</p>
				<cfdump var="#cfcatch#">
				<cfdump var="#cfhttp#">
				</cfmail>
			</cfif>
			
			<cfreturn SetReturnStructErrorCode(stReturn, 1100, cfcatch.Message ) />
			
		</cfcatch>
		</cftry>
		
		<cfreturn SetReturnStructSuccessCode(stReturn) />

	</cffunction>
	
</cfcomponent>