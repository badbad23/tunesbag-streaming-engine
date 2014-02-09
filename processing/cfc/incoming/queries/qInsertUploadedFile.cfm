<!--- 

	insert information about upload into database

 --->

<cfquery name="qInsertUploadedFile" datasource="tb_incoming">
INSERT INTO
	uploaded_items
	(
	entrykey,
	dt_created,
	userkey,
	location,
	location_metainfo,
	librarykey,
	source,
	uploadrunkey,
	priority,
	autoaddtoplaylist,
	OriginalHashValue,
	done
	)
VALUES
	(
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#sjobkey#">,
	<cfqueryparam cfsqltype="cf_sql_timestamp" value="#Now()#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userkey#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.location#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.location_metainfo#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.librarykey#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.source#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.runkey#">,
	<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.priority#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.autoadd2plist#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#sOriginalHashValue#">,
	0
	)
;
</cfquery>