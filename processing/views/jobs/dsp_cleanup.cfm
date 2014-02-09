<!--- 

	cleanup database

 --->

<cfquery name="qDeleteOldConverJobs" datasource="tb_incoming" result="stResult">
DELETE FROM
	convertjobs
WHERE
	handled = 1
	AND
	done = 1
	AND
	errorno = 0
	AND
	dt_started < <cfqueryparam cfsqltype="cf_sql_timestamp" value="#DateAdd( 'd', -10, Now() )#" />
;
</cfquery>

<cfdump var="#stResult#">

<cfquery name="qDeleteOldS3Uploads" datasource="tb_incoming" result="stResult">
DELETE FROM
	s3uploadqueue
WHERE
	handled = 1
	AND
	done = 1
	AND
	success = 1
	AND
	dt_created < <cfqueryparam cfsqltype="cf_sql_timestamp" value="#DateAdd( 'd', -10, Now() )#" />
;
</cfquery>

<cfdump var="#stResult#">

<cfquery name="qDeleteOldMasterCommunication" datasource="tb_incoming" result="stResult">
DELETE FROM
	logmastercomm
WHERE
	(dt_created < <cfqueryparam cfsqltype="cf_sql_timestamp" value="#DateAdd( 'd', -10, Now() )#" />)
;
</cfquery>

<cfdump var="#stResult#">

<cfquery name="qDeleteOldUploadedItems" datasource="tb_incoming" result="stResult">
DELETE FROM
	uploaded_items
WHERE
	handled = 1
	AND
	done = 1
	AND
	handleerrorcode = 0
	AND
	dt_created < <cfqueryparam cfsqltype="cf_sql_timestamp" value="#DateAdd( 'd', -10, Now() )#" />
;
</cfquery>

<cfdump var="#stResult#">


<cfdirectory action="list" directory="/mnt/tunesbag/" recurse="true" name="qFiles" filter="*.mp3" />

<cfloop query="qFiles">
	
	<cfset sFile = qFiles.directory & '/' & qFiles.name />
	
	<cffile action="delete" file="#sFile#" />
	
</cfloop>