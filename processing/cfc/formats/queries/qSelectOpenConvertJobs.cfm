<cfquery name="q_select_open_convert_jobs" datasource="tb_incoming">
SELECT
	*
FROM
	convertjobs
WHERE
	handled = 0
	AND
	done = 0
ORDER BY
	dt_created
LIMIT
/* just select ONE task */
	1
;
</cfquery>

<!--- select the number of active processes 

	started, but yet finished max 10 min ago

--->
<cfquery name="q_select_convert_active_processes" datasource="tb_incoming">
SELECT
	COUNT(id) AS count_open_jobs
FROM
	convertjobs
WHERE
	/* already handled */
	handled = 1
	AND
	/* not yet done */
	done = 0
	AND
	/* started not long time ago */
	dt_started > <cfqueryparam cfsqltype="cf_sql_timestamp" value="#DateAdd( 'n',-15, Now())#">
;
</cfquery>