<cfquery name="qSelectJobAlreadyExists" datasource="tb_incoming">
SELECT
	COUNT(id) AS count_id
FROM
	convertjobs
WHERE
	uploadkey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.uploadkey#">
	AND
	targetbitrate = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.bitrate#">
	AND
	operation = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.operation#">
;
</cfquery>