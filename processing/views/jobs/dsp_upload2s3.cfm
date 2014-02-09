<!--- 

	upload in the queue to s3

 --->

<!--- call uploads to AWS S3 --->

<cfsetting requesttimeout="2000">

<cfquery name="q_select_open_s3_jobs" datasource="tb_incoming">
SELECT
	id,
	filelocation,
	dt_created,
	done,
	handled,
	uploadkey
FROM
	s3uploadqueue
WHERE
	1 = 1
	AND
	handled = 0
ORDER BY
	/* get tried = 0, created = oldest first */
	tries,
	dt_created
LIMIT
	/* limit to three hits */
	3
;
</cfquery>

<cfdump var="#q_select_open_s3_jobs#">

<cfif q_select_open_s3_jobs.recordcount IS 0>
	<cfexit method="exittemplate">
</cfif>

<!--- set handled --->
<cfquery name="q_update_set_handled" datasource="tb_incoming">
UPDATE
	s3uploadqueue
SET
	handled = 1,
	/* update number of tries */
	tries = tries + 1
WHERE
	id IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#ValueList( q_select_open_s3_jobs.id )#" list="true">)
;
</cfquery>

<cfoutput query="q_select_open_s3_jobs">
	
	 <p>Handling #htmleditformat( q_select_open_s3_jobs.filelocation )# ...</p>
	
	<cfset oStorage = getProperty( 'beanFactory' ).getBean( 'Storage' ) />
	
	<cfset stUploadResult = oStorage.PerformS3Upload( sUploadkey = q_select_open_s3_jobs.uploadkey ) />
	
	<cfdump var="#stUploadResult#">
	
	<!--- success or file already handled ... continue in both cases --->
	<cfif (stUploadResult.result) OR (stUploadResult.error IS 1002)>
		
		<!--- done! --->
		<cfquery name="qUpdateSuccess" datasource="tb_incoming">
		UPDATE
			s3uploadqueue
		SET
			success = 1,
			done = 1
		WHERE
			uploadkey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#q_select_open_s3_jobs.uploadkey#">
		;
		</cfquery>
		
		<!--- inform the master about the uploaded item --->
		<cfset stSubmitMetaInfo = getProperty( 'beanFactory' ).getBean( 'Storage' ).submitMetaInfoToMaster( sEntrykey = q_select_open_s3_jobs.uploadkey) />
		
		<cfdump var="#stSubmitMetaInfo#">
		
		<!--- did it work? --->
		<cfif stSubmitMetaInfo.result>
			
			<cfset stUpdateItem = { done = 1 } />
			<cfset getProperty( 'beanFactory' ).getBean( 'UploadComponent' ).UpdateItemProperties( sEntrykey = q_select_open_s3_jobs.uploadkey, stUpdate = stUpdateItem ) />
			
			<!--- delete the file from the local disk --->
			<cftry>
				<cffile action="delete" file="#q_select_open_s3_jobs.filelocation#">
				
				<cfcatch type="any"></cfcatch>
			</cftry>
		<cfelse>
			
			<!--- set as "in transition" state --->
			<cfset stUpdateItem = { status = 500, done = 0 } />
			<cfset getProperty( 'beanFactory' ).getBean( 'UploadComponent' ).UpdateItemProperties( sEntrykey = q_select_open_s3_jobs.uploadkey, stUpdate = stUpdateItem ) />
		
			<cfmail from="support@tunesbag.com" to="support@tunesbag.com" type="html" subject="[ERR] Sending meta info failed">
			<cfdump var="#stSubmitMetaInfo#" label="response">
			<cfdump var="#q_select_open_s3_jobs.uploadkey#" label="uploadkey">
			</cfmail>
		
		</cfif>
		
	<cfelse>
	
		<!--- set as NOT handled to force re-upload --->
		<cfquery name="q_update_reforce_upload" datasource="tb_incoming" result="stUpdate">
		UPDATE
			s3uploadqueue
		SET
			success = 0,
			done = 0,
			handled = 0,
			response = <cfqueryparam cfsqltype="cf_sql_varchar" value="#stUploadResult.errormessage#">
		WHERE
			uploadkey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#q_select_open_s3_jobs.uploadkey#">
		;
		</cfquery>		
		
		<cfdump var="#stUpdate#">
	
	</cfif>
	
</cfoutput>