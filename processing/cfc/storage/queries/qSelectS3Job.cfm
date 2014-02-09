<cfquery name="qSelectJob" datasource="tb_incoming" maxrows="1">
SELECT
	s3uploadqueue.id,
	s3uploadqueue.filelocation,
	s3uploadqueue.uploadkey,
	s3uploadqueue.dt_created,
	s3uploadqueue.handled,
	s3uploadqueue.done,
	uploaded_items.userkey
FROM
	s3uploadqueue
LEFT JOIN
	uploaded_items ON (uploaded_items.entrykey = s3uploadqueue.uploadkey)
WHERE
	uploadkey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.sUploadkey#">
	AND
	s3uploadqueue.done = 0
;
</cfquery>