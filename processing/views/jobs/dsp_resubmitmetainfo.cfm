<!--- 
	
	check items where the meta data has to be submitted again

 --->

<cfset stUpdateItem = {} />

<cfquery name="qSelectUnfinishedJobs" datasource="tb_incoming">
SELECT
	*
FROM
	uploaded_items
WHERE
	done = 0
	AND
	status = 500
	AND
	handled = 1
ORDER BY
	dt_created
LIMIT
	50
;
</cfquery>

<cfoutput query="qSelectUnfinishedJobs">
	<cfset stSubmitMetaInfo = getProperty( 'beanFactory' ).getBean( 'Storage' ).submitMetaInfoToMaster( sEntrykey = qSelectUnfinishedJobs.entrykey, bResubmitRequest = true) />
	
	<cfdump var="#stSubmitMetaInfo#">
	
	<!--- did it work? --->
	<cfif stSubmitMetaInfo.result>
		
		<cfset stUpdateItem = { done = 1 } />
		<cfset getProperty( 'beanFactory' ).getBean( 'UploadComponent' ).UpdateItemProperties( sEntrykey = qSelectUnfinishedJobs.entrykey, stUpdate = stUpdateItem ) />
		
		<!--- delete the file from the local disk --->
		<cftry>
			<cffile action="delete" file="#qSelectUnfinishedJobs.filelocation#">
			
			<cfcatch type="any"></cfcatch>
		</cftry>
	<cfelse>
		
		<!--- set as "in BAD transition" state (505) and notify support--->
		<cfset stUpdateItem = { status = 505, done = 0 } />
		<cfset getProperty( 'beanFactory' ).getBean( 'UploadComponent' ).UpdateItemProperties( sEntrykey = qSelectUnfinishedJobs.entrykey, stUpdate = stUpdateItem ) />
	
		<cfmail from="support@tunesbag.com" to="support@tunesbag.com" type="html" subject="[ERR] Sending meta info failed">
		<cfdump var="#stSubmitMetaInfo#" label="response">
		<cfdump var="#qSelectUnfinishedJobs.entrykey#" label="uploadkey">
		</cfmail>
	
	</cfif>
</cfoutput>

done.