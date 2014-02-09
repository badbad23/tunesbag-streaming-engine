<!--- 
	
	insert a convert job
	
 --->

<cfquery  name="qInsertConvertJob" datasource="tb_incoming">
INSERT INTO
	convertjobs
	(
	userkey,
	entrykey,
	uploadkey,
	dt_created,
	operation,
	sourcefile,
	destfile,
	targetformat,
	targetbitrate	
	)
VALUES
	(
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userkey#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#sJobkey#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.uploadkey#">,
	<cfqueryparam cfsqltype="cf_sql_timestamp" value="#Now()#">,
	<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.operation#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.source#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#sDestfile#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.format#">,
	<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.bitrate#">
	)
;
</cfquery>