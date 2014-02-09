<!--- 
	
	is a job running?

 --->

<cfsetting requesttimeout="120" />


<!--- TODO: is this a PUID generation engine? --->

<cfset oTools = getProperty( 'beanFactory' ).getBean( 'Tools' ) />

<cfif oTools.isPUIDJobRunning()>
	job is running
	<cfexit method="exittemplate" />
</cfif>

<!--- request an MP3 from master ... --->

<cfset stPUIDJob = application.beanFactory.getBean( 'Communication' ).TalkToMasterServer( type = 'puid.generate.request', data = {} ) />


<!--- <cfdump var="#stPUIDJob#"> --->
<cfif NOT stPUIDJob.result OR NOT StructKeyExists( stPUIDJob, 'slink' )>
	<cfexit method="exittemplate">
</cfif>

<cfset stCalc = oTools.calculatePUID( sMP3Location = stPUIDJob.sLink, sMediaitemkey = stPUIDJob.sEntrykey ) />

<cfif NOT stCalc.result>
	
	<!--- 505 = not possible to generate PUID at the moment --->
	<cfif stCalc.error NEQ 505>
		
		<cflog application="false" file="tb_generate_puid_failure" text="#SerializeJSON( stCalc )# #SerializeJSON(stPUIDJob  )#" type="information" />
		<!--- <cfmail from="support@tunesBag.com" to="support@tunesBag.com" subject="PUID generation failed" type="html">
		<cfdump var="#stCalc#" label="stCalc">
		<cfdump var="#stPUIDJob#" label="stPUIDJob">
		</cfmail> --->
	</cfif>
	<cfexit method="exittemplate">
</cfif>

<!--- submit result to master server --->
<cfset stSubmitAnswer = application.beanFactory.getBean( 'Communication' ).TalkToMasterServer( type = 'puid.submit.result', data = { sMediaitemkey = stPUIDJob.sEntrykey, sPUID = stCalc.SPUID} ) />

<cfdump var="#stSubmitAnswer#">

done.