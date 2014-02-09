<!--- 

	upload response text

 --->

<cfinclude template="/inc/scripts.cfm">

<cfset stReturn = event.getArg( 'stReturn', SetReturnStructErrorCode(GenerateReturnStruct(), 989 ) ) />

<!--- debug mode? --->
<cfset bDebug = event.getArg( 'debug', false ) />

<!--- in debug mode? --->
<cfif bDebug>
	
	<h1>debug mode</h1>

	<cfdump var="#stReturn#" label="Result of this call">

	<cfdump var="#event.getargs()#" label="Provided arguments">

<cfelse>

	<cfcontent type="text/json; charset=UTF-8" />
	
	<cfoutput>#SerializeJSON( stReturn )#</cfoutput>

</cfif>
