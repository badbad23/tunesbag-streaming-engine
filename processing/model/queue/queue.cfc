<!--- 

	queue management

 --->

<cfcomponent output="false" hint="queue management" extends="MachII.framework.Listener">
	
	<cffunction name="configure" access="public" output="false" returntype="void" hint="Configures this listener as part of the Mach-II  framework"> 
	</cffunction>

	<cffunction access="public" name="CleanupAndModifyQueuePriorities" output="false" returntype="void"
			hint="attemp to modify queue priorities to make smaller amount of tracks appear faster in the library">
		<cfargument name="event" type="MachII.framework.Event" required="true" />
		
		<cfset var qDeleteInvalidItems = 0 />
		
		<cfquery name="qDeleteInvalidItems" datasource="tb_incoming">
		DELETE FROM
			uploaded_items
		WHERE
			entrykey = ''
		;
		</cfquery>
		
		<!--- update priorities --->
		<cfinclude template="utils/inc_modify_queue_properties.cfm">

	</cffunction>
	
	<cffunction access="public" name="GetNextWaitingQueueItems" output="false" returntype="void"
			hint="return the next waiting items">
		<cfargument name="event" type="MachII.framework.Event" required="true" />
		
		<cfset event.setArg( 'qUnhandledIncoming', getProperty( 'beanFactory' ).getBean( 'QueueComponent' ).GetNextWaitingUnhandledItems() ) />

	</cffunction>
	
	<cffunction access="public" name="transmitQueueStatus" output="false" returntype="void">
		<cfset getProperty( 'beanFactory' ).getBean( 'Tools' ).transmitQueueStatus() />
	</cffunction>

</cfcomponent>