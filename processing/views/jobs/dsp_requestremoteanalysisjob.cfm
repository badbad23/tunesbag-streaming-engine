<!--- 

	request new dropbox analysis jobs

	max rows = 20
	
	so 5 seconds max, = 140 seconds timeout (plus 40% backup)
	
 --->

<cfsetting requesttimeout="140" />

<cfset stReq = application.beanFactory.getBean( 'Communication' ).TalkToMasterServer( type = 'remoteanalysis.next', data = {} ) />

<!--- ok? --->
<cfif NOT stReq.result>
	<i>no job found</i>
	<cfexit method="exittemplate" />
</cfif>

<cfset aJobs = stReq.aJobs />

<!--- loop over jobs --->
<cfloop from="1" to="#arrayLen( aJobs )#" index="ii">
	
	<cfset stJob = aJobs[ ii ] />
	
	<cfthread action="run" name="t#ii#" stJob="#stJob#">
		
		<cfset stJob = attributes.stJob />
	
		<cftry>
		<cfset stParse = application.beanFactory.getBean( 'RemoteAnalysis' ).analyzeRemoteFile(
			iUser_ID			= stJob.iUser_ID,
			iAudio_Format		= stJob.iAudio_Format,
			iStoreType_ID		= stJob.iStoreType_ID,
			sHTTPLocation		= stJob.sHTTPLocation,
			sHTTPLocationAlt	= stJob.sHTTPLocationAlt,
			iHTTPRange			= 0
			) />
			
		<!--- <cfdump var="#stParse#"> --->
		
		<!--- return result to master host --->
		<cfif stParse.result>
		
			<cfset stReq = application.beanFactory.getBean( 'Communication' ).TalkToMasterServer( type = 'remoteanalysis.result', data = {
				result		= true,
				iUser_ID	= stJob.iUser_ID,
				iDropBox_ID	= stJob.iDropBox_ID,
				jMeta		= SerializeJSON( stParse.STPARSE.metainformation )
				} ) />
				
			<!--- <cfdump var="#stReq#"> --->
		
		<cfelse>
			
			<!--- return an error --->
			
		</cfif>
		
		<cfcatch type="any">
		<cfdump var="#cfcatch#">
		</cfcatch>
		</cftry>
	
	</cfthread>
	
	thread <cfoutput>#ii# (uid #stJob.iUser_ID#)</cfoutput> started.<br />
	
	<cfthread action="sleep" duration="50" />
	
</cfloop>

<i>done</i>

<meta http-equiv="refresh" content="15" />