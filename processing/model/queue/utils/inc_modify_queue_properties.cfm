<!--- 

	modify priorities a little bit so that users with just a few tracks are preferred

	select distinct userkeys, then update the priority of the first 5 items of the user

 --->


<cflock name="lck_handle_update_queue" timeout="30" type="exclusive" throwontimeout="true">

<cftransaction>

<!--- reset to default priority... --->
<cfquery name="q_update_old_priority" datasource="tb_incoming">
UPDATE
	uploaded_items
SET
	priority = 0
WHERE
	priority = -1
	AND
	done = 0
	AND
	handled = 0
;
</cfquery>

<cfquery name="q_select_upload_items" datasource="tb_incoming">
SELECT
	COUNT( uploaded_items.id ) AS itemscount,
	uploaded_items.userkey
FROM
	uploaded_items
WHERE
	done = 0
	AND
	handled = 0
GROUP BY
	uploaded_items.userkey
ORDER BY
	itemscount DESC
;
</cfquery>

<cfoutput query="q_select_upload_items">

	<cfquery name="q_select_user_entrykeys" datasource="tb_incoming">
	SELECT
		uploaded_items.entrykey
	FROM
		uploaded_items
	WHERE
		uploaded_items.userkey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#q_select_upload_items.userkey#">
		AND
		done = 0
		AND
		handled = 0
	ORDER BY
		uploaded_items.dt_created
	/* the five oldest items */
	LIMIT
		5
	;
	</cfquery>
	
	<!--- lower priority of all upload items of user except the oldest five --->
	<cfquery name="q_update_set_priority_lower" datasource="tb_incoming">
	UPDATE
		uploaded_items
	SET
		priority = -1
	WHERE
		uploaded_items.userkey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#q_select_upload_items.userkey#">
		AND NOT
		uploaded_items.entrykey IN (<cfqueryparam cfsqltype="cf_sql_varchar" value="#ValueList( q_select_user_entrykeys.entrykey )#">)
	;
	</cfquery>
	
	<!--- fewer then three items ... handle immediately --->
	<cfif q_select_upload_items.itemscount LT 3>
		
		<cfquery name="q_upload_few_items_handle_now" datasource="tb_incoming">
		UPDATE
			uploaded_items
		SET
			priority = 5
		WHERE
			uploaded_items.userkey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#q_select_upload_items.userkey#">
		;
		</cfquery>
		
	</cfif>
	

</cfoutput>

</cftransaction>

</cflock>