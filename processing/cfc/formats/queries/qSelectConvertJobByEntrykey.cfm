<cfquery name="qSelectConvertJobByEntrykey" datasource="tb_incoming">
SELECT
	*
FROM
	convertjobs
WHERE
	entrykey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.entrykey#">
;
</cfquery>
