<!---

	layoutManager.cfc plugin for the Mach-II framework

	Author: Martin Laine

	Version: 2.1

	For usage instructions: http://www.1pixelout.net/code/

--->

<cfcomponent extends="MachII.framework.Plugin">

	<cffunction name="configure" access="public" output="false" returntype="void">
		
		<!--- Write parameters to plugin's persistent scope --->
		<cfset variables.argumentPrefix = getParameter( "argumentPrefix", "" ) />
		<cfset variables.defaultLayoutEvent = getParameter( "defaultLayoutEvent" ) />
		<cfset variables.defaultContentType = getParameter( "defaultContentType", "text/html;charset=utf-8" ) />
		<cfset variables.finalOutputKey = getParameter( "finalOutputKey", "" ) />
		<cfset variables.optimizeWhiteSpace = getParameter( "optimizeWhitespace", false ) />
		<cfset variables.preserveWhitespaceTagList = getParameter( "preserveWhitespaceTagList", "textarea,pre" ) />
		<cfset variables.defaultDispositionMethod = getParameter( "defaultDispositionMethod", "attachment" ) />

	</cffunction>

	<cffunction name="preProcess" access="public" output="false" returntype="void">
		<cfargument name="eventContext" type="MachII.framework.eventContext" required="true" />
		<!--- Set flag to false --->
		<cfset request.layoutManagerFlags.layoutDone = false />
	</cffunction>
	
	<cffunction access="private" name="LogEx" returntype="void">
		<cfargument name="s" type="string" required="true">
		<!--- <cflog application="false" file="ib_machii_layout" log="Application" text="#arguments.s#" type="information"> --->
	</cffunction>

	<cffunction name="postEvent" access="public" output="false" returntype="void">
		<cfargument name="eventContext" type="MachII.framework.eventContext" required="true" />

		<cfscript>
		var currentEvent = arguments.eventContext.getCurrentEvent();

		// Look for a specific layoutEvent in the event argument collection, otherwise use the default event set in the parameters
		var layoutEvent = currentEvent.getArg( "#variables.argumentPrefix#layoutEvent", variables.defaultLayoutEvent );
		
		
		if( currentEvent.getArg( "#variables.argumentPrefix#disableLayoutManager", false ) ) return;


		// Ignore if there are events left in the queue or if the event has been announced by this plugin

		if( not arguments.eventContext.hasMoreEvents() and not request.layoutManagerFlags.layoutDone ) {

			// Exit if the event argument skipLayoutEvent has been set to true or if we are in the layout event itself

			if( currentEvent.getArg( "#variables.argumentPrefix#skipLayoutEvent", false ) or currentEvent.getName() IS layoutEvent ) return;

			// Call the layout event
			arguments.eventContext.announceEvent( layoutEvent, currentEvent.getArgs() );

			// Flag this plugin's work as done
			request.layoutManagerFlags.layoutDone = true;

		}

		</cfscript>

	</cffunction>

	<cffunction name="postProcess" access="public" output="true" returntype="void">
		<cfargument name="eventContext" type="MachII.framework.eventContext" required="true" />


		<cfscript>

		var content = "";

		var contentType = "";

		var preservedContent = structNew();

		var tagPosition = 0;

		var tagName = "";

		var i = 0;

		var j = 0;

		var dispositionMethod = "";

		var currentEvent = arguments.eventContext.getCurrentEvent();

		var optimizeWhiteSpace = currentEvent.getArg( "#variables.argumentPrefix#optimizeWhiteSpace", variables.optimizeWhiteSpace );

		LogEx('--- postprocess ---');

		if( currentEvent.getArg( "#variables.argumentPrefix#disableLayoutManager", false ) ) return;

		LogEx('still in the game');

		// If no finalOutputKey is set then exit the plugin, its work is done
		
		if( len( variables.finalOutputKey ) eq 0 ) return;

		LogEx('output key: ' & variables.finalOutputKey);

		// Get content type (can be set as an event argument)

		contentType = currentEvent.getArg( "#variables.argumentPrefix#contentType", variables.defaultContentType );


		LogEx('contentType: ' & contentType);
		// Get final output

		content = trim( evaluate( variables.finalOutputKey ) );

		if( optimizeWhiteSpace ) {

			// Extract content of tags for which to preserve whitespace

			for(i=1;i lte listLen(variables.preserveWhitespaceTagList);i=i+1) {

				tagName = listGetAt( variables.preserveWhitespaceTagList, i );

				preservedContent[tagName] = arrayNew(1);

				tagPosition = REFind( "<#tagName#[^>]*>[^<]+</#tagName#>", content, 1, true );

				while( tagPosition.pos[1] gt 0 ) {

					arrayAppend( preservedContent[tagName], mid( content, tagPosition.pos[1], tagPosition.len[1] ) );

					content = REReplaceNoCase( content, "<#tagName#[^>]*>[^<]+</#tagName#>", "====:LAYOUTMANAGER_#tagName#:====", "ONE" );

					tagPosition = REFindNoCase( "<#tagName#[^>]*>[^<]+</#tagName#>", content, 1, true );

				}

			}

			

			// Optimise whitespace output

			content = REReplace( trim( content ), "[[:space:]]*[#chr(13)##chr(10)#]+[[:space:]]*", "#chr(13)##chr(10)#", "ALL" );

			

			// Replace preserved tag content

			for(i=1;i lte listLen(variables.preserveWhitespaceTagList);i=i+1) {

				tagName = listGetAt( variables.preserveWhitespaceTagList, i );

				for( j=1;j lte arrayLen(preservedContent[tagName]);j=j+1 ) {

					content = REReplaceNoCase( content, "====:LAYOUTMANAGER_#tagName#:====", preservedContent[tagName][j], "ONE" );

				}

			}

		}

		</cfscript>



		<!--- If forcedFileName argument is in event, set HTTP headers for setting the file's name and disposition method --->

		<cfif currentEvent.isArgDefined( "#variables.argumentPrefix#forcedFileName" )>

			<cfset dispositionMethod = currentEvent.getArg( "#variables.argumentPrefix#dispositionMethod", variables.defaultDispositionMethod ) />

			<cfheader name="Content-Disposition" value="#dispositionMethod#;filename=#currentEvent.getArg( "#variables.argumentPrefix#forcedFileName" )#" />

		</cfif>



		<!--- Reset output, set content type and output optimised content --->

		<cfcontent type="#contentType#" reset="true" /><cfoutput>#content#</cfoutput>

	</cffunction>



</cfcomponent>