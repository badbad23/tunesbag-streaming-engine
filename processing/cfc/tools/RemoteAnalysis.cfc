<!--- 

	remote analysis of files helper

 --->
<cfcomponent output="false">
	
	<cfinclude template="/inc/scripts.cfm">
	
	<cffunction name="init" returntype="any" output="false">
		<cfreturn this />
	</cffunction>

	<cffunction access="public" name="analyzeRemoteFile" output="false" returntype="struct"
			hint="Generic routine for analyzing remote files">
		<cfargument name="iUser_ID" type="numeric" required="true"
			hint="User ID" />
		<cfargument name="iAudio_Format" type="numeric" required="true"
			hint="The audio format of the source" />
		<cfargument name="iStoreType_ID" type="numeric" required="true"
			hint="Which service?" />
		<cfargument name="sHTTPLocation" type="string" required="false" default=""
			hint="Information about the location (http?)" />
		<cfargument name="sHTTPLocationAlt" type="string" required="false" default=""
			hint="Information about the location (http?) This is the same url in case of dropbox but we need to use a different token as the first one will be used for the first try reading 20kb" />			
		<cfargument name="iHTTPRange" type="numeric" required="false" default="0"
			hint="Only get a certain piece of the file for the analysis" />
		<cfargument name="bAlternativeTry" type="boolean" required="false" default="false"
			hint="Is this already an alternative try using more data?" />
			
		<cfset var stReturn = GenerateReturnStruct() />
		
		<!--- alternative try allowed? --->
		<cfset local.bAlternativeTryAllowed = true />
		
		<cfif Len( arguments.sHTTPLocation ) IS 0>
			<cfreturn application.udf.SetReturnStructErrorCode( stReturn, 404, 'Invalid HTTP Path' ) />
		</cfif>
		
		<cflog application="false" file="tb_parse_remote_file" text="#arguments.iUser_ID# Parsing storage type: #iStoreType_ID# alt try: #arguments.bAlternativeTry# format: #arguments.iAudio_Format# src: #arguments.shttplocation#" />
		
		<cfset local.sTempFile = getTempDirectory() & 'ext_analysis_' & CreateUUID() & '.mp3' />
		
		<!--- any special handling? --->
		<cfswitch expression="#arguments.iAudio_Format#">
			<cfcase value="#application.const.I_AUDIO_FORMAT_M4A#,#application.const.I_AUDIO_FORMAT_OGG#,#application.const.I_AUDIO_FORMAT_WMA#" delimiters=",">
				<!--- always request the entire file --->
				<cfset arguments.iHTTPRange = 0 />
				
				<!--- just one try --->
				<cfset local.bAlternativeTryAllowed = false />
			</cfcase>
		</cfswitch>
	
		<cftry>
			
			<cfhttp url="#arguments.sHTTPLocation#" charset="utf-8" method="get" result="local.stHTTP">
				
				<!--- read from the beginning --->
				<cfif Val( arguments.iHTTPRange ) GT 0>
					<cfhttpparam type="Header" name="Range" value="bytes=0-#arguments.iHTTPRange#" />
				</cfif>
				
			</cfhttp>
		
			<cfcatch type="any">
				
				<cflog application="false" file="tb_parse_remote_file" log="Application" type="information" text="#arguments.iUser_ID#: REMOTE CALL FAILED #cfcatch.toString()#" />
				
				<cfreturn SetReturnStructErrorCode( stReturn, 500, 'Could not load file, invalid result' ) />

			</cfcatch>
		</cftry>
		
		<!--- file ok? (2xx responses) --->
		<cfif NOT StructKeyExists( local.stHTTP, 'status_code' ) OR Left(Val( local.stHTTP.status_code ), 1) NEQ 2 OR NOT StructKeyExists( local.stHTTP, 'FileContent')>
			<cflog application="false" file="tb_parse_remote_file" log="Application" type="information" text="#arguments.iUser_ID#: REMOTE CALL FAILED #SerializeJSON( local.stHTTP )#" />
				
			<cfreturn SetReturnStructErrorCode( stReturn, 404, 'Could not load file, invalid result' ) />
		</cfif>
		
		<!--- write to disk --->
		<cffile action="write" output="#local.stHTTP.FileContent#" file="#local.sTempFile#" />
		
		<!---
			
			try to analyze
			
			use the appropriate analyzer for each format
			
			- mp3
			- ogg
			- wma
			- m4a
			- flac
			
			--->
		<cfswitch expression="#arguments.iAudio_Format#">
			<cfcase value="#application.const.I_AUDIO_FORMAT_WMA#,#application.const.I_AUDIO_FORMAT_OGG#">
				
				<!--- parse WMA --->
				<cfif arguments.iAudio_Format IS application.const.I_AUDIO_FORMAT_WMA>
					<cfset local.stParse = application.beanFactory.getBean( 'WMAReader' ).ParseWMAFile( local.sTempFile ) />
				<cfelse>
					<cfset local.stParse = application.beanFactory.getBean( 'OGGReader' ).ParseOGGFile( local.sTempFile ) />					
				</cfif>
				
				<cfset stReturn.stParse = local.stParse />
				
				<cfif NOT local.stParse.result>
					
					<!--- error while parsing file? give it one more try using more data ... only if not already done --->
					<cfif local.bAlternativeTryAllowed AND local.stParse.error IS application.err.AUDIO_UNABLE_TO_PARSE_FILE AND NOT arguments.bAlternativeTry>
						
						<!--- read full file ... reason might be a photo or something like that which is too big for the first read --->
						<cfset arguments.iHTTPRange = 0 />						
						<cfset arguments.bAlternativeTry = true />
						
						<cflog application="false" file="tb_parse_remote_file" text="#arguments.iUser_ID# Failed. Trying to re-run the call with more data" />
						
						<!--- remove the old temp file --->
						<cfif FileExists( local.sTempFile )>
							<cffile action="delete" file="#local.sTempFile#" />
						</cfif>
						
						<!--- an alternative location given? --->
						<cfif Len( arguments.sHTTPLocationAlt )>
							<cfset arguments.sHTTPLocation = arguments.sHTTPLocationAlt />
						</cfif>
						
						<!--- run the call one more time --->
						<cfreturn analyzeRemoteFile( argumentCollection = arguments ) />
					
					<cfelse>
						
						<!--- delete tmp file --->				
						<cftry>
							<cffile action="delete" file="#local.sTempFile#" />
							<cfcatch type="any"></cfcatch>
						</cftry>
						
						<!--- return the error --->
						<cfreturn local.stParse />
						
					</cfif>
				
				<cfelse>
					
					<!--- success! --->
				
				</cfif>
				
				
			</cfcase>
			<cfcase value="#application.const.I_AUDIO_FORMAT_M4A#">
				
				<!--- parse this m4a --->
				<cfset local.stParse = application.beanFactory.getBean( 'M4AReader' ).ParseM4AFile( local.sTempFile ) />
				
				<cfset stReturn.stParse = local.stParse />
				
				<cfif NOT local.stParse.result>
					
					<!--- error while parsing file? give it one more try using more data ... only if not already done --->
					<cfif local.bAlternativeTryAllowed AND local.stParse.error IS application.err.AUDIO_UNABLE_TO_PARSE_FILE AND NOT arguments.bAlternativeTry>
						
						<!--- read full file ... reason might be a photo or something like that which is too big for the first read --->
						<cfset arguments.iHTTPRange = 0 />						
						<cfset arguments.bAlternativeTry = true />
						
						<cflog application="false" file="tb_parse_remote_file" text="#arguments.iUser_ID# Failed. Trying to re-run the call with more data" />
						
						<!--- remove the old temp file --->
						<cffile action="delete" file="#local.sTempFile#" />
						
						<!--- an alternative location given? --->
						<cfif Len( arguments.sHTTPLocationAlt )>
							<cfset arguments.sHTTPLocation = arguments.sHTTPLocationAlt />
						</cfif>
						
						<!--- run the call one more time --->
						<cfreturn analyzeRemoteFile( argumentCollection = arguments ) />
					
					<cfelse>
						
						<!--- delete tmp file --->				
						<cffile action="delete" file="#local.sTempFile#" />
						
						<!--- return the error --->
						<cfreturn local.stParse />
						
					</cfif>
				
				<cfelse>
					
					<!--- success! --->
				
				</cfif>
			
			</cfcase>
			<cfcase value="#application.const.I_AUDIO_FORMAT_MP3#">
				
				<!--- parse this mp3 --->
				<cfset local.stParse = application.beanFactory.getBean( 'MP3Reader' ).ParseMP3File( local.sTempFile ) />
				
				<cfset stReturn.stParse = local.stParse />
				
				<cfif NOT local.stParse.result>
					
					<!--- error while parsing file? give it one more try using more data ... only if not already done --->
					<cfif local.stParse.error IS application.err.AUDIO_UNABLE_TO_PARSE_FILE AND NOT arguments.bAlternativeTry>
						
						<!--- read full file ... reason might be a photo or something like that which is too big for the first read --->
						<cfset arguments.iHTTPRange = 0 />						
						<cfset arguments.bAlternativeTry = true />
						
						<cflog application="false" file="tb_parse_remote_file" text="#arguments.iUser_ID# Failed. Trying to re-run the call with more data" />
						
						<!--- an alternative location given? --->
						<cfif Len( arguments.sHTTPLocationAlt )>
							<cfset arguments.sHTTPLocation = arguments.sHTTPLocationAlt />
						</cfif>
						
						<!--- delete original file --->
						<cffile action="delete" file="#local.sTempFile#" />
						
						<!--- run the call one more time --->
						<cfreturn analyzeRemoteFile( argumentCollection = arguments ) />
					
					<cfelse>
						
						<!--- return the error --->
						<cfreturn local.stParse />
						
					</cfif>
				
				<cfelse>
					
					<!--- success! --->
				
				</cfif>
			
			</cfcase>
			<!--- <cfcase value="#application.const.I_AUDIO_FORMAT_M4A#">
			
				<!--- try to read the WMA file --->
				<cfset local.stParse = application.beanFactory.getBean( 'M4AParser' ).ParseM4aFile( local.sTempFile ) />
				
				<cfmail from="post@hansjoergposch.com" to="office@tunesBag.com" subject="parse wma" type="html">
				<cfdump var="#local.stParse#">
				</cfmail>
				
			</cfcase> --->
			<cfdefaultcase>
				<!--- TODO: Handle --->
				<cfset stReturn.unknown = arguments.iAudio_Format />
			</cfdefaultcase>
		</cfswitch>
		
		<!--- invalid file? --->
		<cfif NOT StructKeyExists( stReturn, 'stParse' )>
			<!--- remove the tmp file --->
			<cffile action="delete" file="#local.sTempFile#" />
			
			<cfreturn SetReturnStructErrorCode( stReturn, 500, 'Could not load file, invalid result' ) />
		</cfif>
		
		<!--- fix the track length ... if below 10, use 0 --->
		<cfif Val( stReturn.stParse.METAINFORMATION.TRACKLENGTH ) LTE 10>
			<cfset stReturn.stParse.METAINFORMATION.TRACKLENGTH = 0 />
		</cfif>
		
		<!--- remove the tmp file --->
		<cfif FileExists( local.sTempFile )>
			<cffile action="delete" file="#local.sTempFile#" />
		</cfif>
		
		<cfreturn SetReturnStructSuccessCode(stReturn) />
	
	</cffunction>
	
</cfcomponent>>