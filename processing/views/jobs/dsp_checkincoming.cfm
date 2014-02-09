<!--- //

	Module:		Check the incoming data

	
// --->

<cfinclude template="/inc/scripts.cfm">

<cfsetting requesttimeout="2000">

<!--- waiting items --->
<cfset qWaitingItems = event.getArg( 'qUnhandledIncoming' ) />
<cfset oQueue = getProperty( 'beanFactory' ).getBean( 'QueueComponent' ) />
<cfset oUpload = getProperty( 'beanFactory' ).getBean( 'UploadComponent' ) />

<cfdump var="#qWaitingItems#">

<cfloop query="qWaitingItems">
	
	<!--- mark as handled --->
	<cfset stUpdate = oQueue.SetHandledStatus( sEntrykey = qWaitingItems.entrykey, iHandled = 1 ) />
	
	<!--- file or web page? --->
	<cfif FindNoCase( 'http://', qWaitingItems.location ) GT 0>
		
		<!--- start upload --->
		<!--- <cfset a_struct_http_load = a_upload.DoHttpUpload( url = q_select_incoming.location ) />
				
		<!--- set location --->
		<cfif a_struct_http_load.result>
			
			<!--- re-add to upload queue now with real filename --->
			<cfset a_struct_result_add = a_upload.InsertNewUploadItemNotification(userkey = q_select_incoming.userkey,
						librarykey = q_select_incoming.librarykey,
						location = a_struct_http_load.location,
						source = q_select_incoming.source ) />
			
			<!--- delete queue item with http:// location --->
			<cfset a_transfer.delete( a_item ) />
		</cfif> --->
		
		<cfthrow message="not supported location" />
		
	</cfif>
	
	<!--- file ... exists and size GT 0 --->
	<cfif FileExists( qWaitingItems.location ) AND (FileSize( qWaitingItems.location ) GT 0)>
			
		<!--- parse the file and upload it to S3 --->
		<cfset stAdd = oUpload.HandleUploadedFile( entrykey = qWaitingItems.entrykey ) />
		
		<cfdump var="#stAdd#">
		
		<cfif stAdd.result>
			<!--- lala --->
		</cfif>
		
	<cfelse>
	
		<!--- does not exist (any more) --->
		<cfset oQueue.DeleteQueueItems( sEntrykeys = qWaitingItems.entrykey ) />
		
	</cfif>


</cfloop>