<!--- 

	convert files to mp3 / reduce bitrate

 --->

<cfinclude template="/inc/scripts.cfm">

<cfsetting requesttimeout="2000">

<cfset a_converter = getProperty( 'beanFactory' ).getBean( 'AudioConverter' ) />

<cfset a_struct_jobs = a_converter.GetNextOpenConvertJobs() />

<cfif NOT a_struct_jobs.result>
	no open jobs.
	<cfexit method="exittemplate">
</cfif>

<!--- query with next jobs --->
<cfset q_select_open_convert_jobs = a_struct_jobs.q_select_open_convert_jobs />

<cfdump var="#q_select_open_convert_jobs#">

<cfloop query="q_select_open_convert_jobs">
	
	<!--- set job as handled --->
	
	
	<!--- write the given jobs to a shell script and execute! --->
	<cfset a_str_tmp_file = GetTBTempDirectory() & '/converts/convert_job_' & CreateUUID() & '.sh' />
	
	<cfif NOT DirectoryExists( GetDirectoryFromPath( a_str_tmp_file ) )>
		<cfdirectory action="create" directory="#GetDirectoryFromPath( a_str_tmp_file )#">
	</cfif>
	
	<!--- create valid script (not only the command lines) --->
<cfsavecontent variable="a_str_shell_script">##!/bin/bash
<cfoutput>#q_select_open_convert_jobs.shellscript#</cfoutput>
</cfsavecontent>

	<!--- create script --->
	<cffile action="write" output="#a_str_shell_script#" addnewline="false" file="#a_str_tmp_file#">
	
	<!--- execute and don't wait for the end ... will report end to the server --->
	<cfexecute name="sh" arguments="#a_str_tmp_file#" timeout="0"></cfexecute>
	
</cfloop>

done.