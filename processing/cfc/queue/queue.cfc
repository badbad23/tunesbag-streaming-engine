<!--- 

	handle various formats

 --->

<cfcomponent output="false" hint="general incoming routines">
	
	<cfinclude template="/inc/scripts.cfm">

	<cffunction access="public" name="init" returntype="processing.cfc.queue.queue" output="false">
		<cfreturn this />
	</cffunction>
	
	<cffunction access="public" name="GetNextWaitingUnhandledItems" output="false" returntype="query">
		<cfset var qUnhandledIncoming = 0 />
		
		<cfquery name="qUnhandledIncoming" datasource="tb_incoming">
		SELECT
			*
		FROM
			uploaded_items
		WHERE
			handled = 0
		ORDER BY
			priority DESC,
			dt_created
		LIMIT
			10
		;
		</cfquery>
		
		<cfreturn qUnhandledIncoming />
		
	</cffunction>
	
	<cffunction access="public" name="DeleteQueueItems" output="false" returntype="void"
			hint="delete the items by it's entrykeys">
		<cfargument name="sEntrykeys" type="string" required="true" />
		
		<cfset var qDelete = 0 />
		
		<cfquery name="qDelete" datasource="tb_incoming">
		DELETE FROM
			uploaded_items
		WHERE
			entrykey IN (<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.sEntrykeys#" list="true">)
		;
		</cfquery>

	</cffunction>
	
	<cffunction access="public" name="SetHandledStatus" output="false" returntype="struct">
		<cfargument name="sEntrykey" type="string" required="true" />
		<cfargument name="iHandled" type="numeric" required="true"
			hint="0/1" />
			
		<cfset var qUpdate = 0 />
		<cfset var stUpdate = 0 />
		
		<cfquery name="qUpdate" datasource="tb_incoming" result="stUpdate">
		UPDATE
			uploaded_items
		SET
			handled = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.iHandled#">
		WHERE
			entrykey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.sEntrykey#">
			AND NOT
			handled = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.iHandled#">
		;
		</cfquery>
		
		<cfreturn stUpdate />
	
	</cffunction>
		
	
</cfcomponent>