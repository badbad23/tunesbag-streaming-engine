<cfcomponent
	displayname="Application"
	extends="MachII.mach-ii"
	output="false">

	<!---
	PROPERTIES - APPLICATION SPECIFIC
	--->
	<cfset this.name = "tunesBagProcessingEngine" />
	<cfset this.loginStorage = "session" />
	<cfset this.sessionManagement = false />
	<cfset this.setClientCookies = false />
	<cfset this.setDomainCookies = false />
	<!--- <cfset this.sessionTimeOut = CreateTimeSpan(0,1,0,0) /> --->
	<cfset this.applicationTimeOut = CreateTimeSpan(1,0,0,0) />
	
	<!---
	PROPERTIES - MACH-II SPECIFIC
	--->
	<!---Set the path to the application's mach-ii.xml file --->
	<cfset MACHII_CONFIG_PATH = ExpandPath("./config/mach-ii.xml") />
	<!--- Set the app key for sub-applications within a single cf-application. --->
	<cfset MACHII_APP_KEY =  this.name />
	<!--- Set the configuration mode (when to reinit): -1=never, 0=dynamic, 1=always --->
	<cfset MACHII_CONFIG_MODE = 0 />
	<!--- Whether or not to validate the configuration XML before parsing. Default to false. --->
	<cfset MACHII_VALIDATE_XML = FALSE />
	<!--- Set the path to the Mach-II's DTD file. --->
	<cfset MACHII_DTD_PATH = ExpandPath("../MachII/mach-ii_1_5_0.dtd") />
	
	<!---
	PROPERTIES - APPLICATION SPECIFIC
	--->
	<!--- Increases the request timeout when the framework (re)loads --->
	<cfset REQUEST_TIMEOUT = 2000 />
	
	<cfsetting requesttimeout="2000" />

	<!---
	PUBLIC FUNCTIONS
	--->
	<cffunction name="onApplicationStart" returnType="void" output="false"
		hint="Only runs when the App is started.">
		<cfsetting requesttimeout="#REQUEST_TIMEOUT#" />
		<cfset LoadFramework() />
	</cffunction>

	<cffunction name="onApplicationEnd" returntype="void" output="false"
		hint="Only runs when the App is shut down.">
		<cfargument name="applicationScope" type="struct" required="true" />
	</cffunction>

	<cffunction name="onSessionStart" returntype="void" output="false"
		hint="Only runs when a session is created.">
		<!---
		Example onSessionStart in a Session Facade
		<cfset getProperty("sessionFacade").onSessionStart() />
		--->
	</cffunction>

	<cffunction name="onSessionEnd" returntype="void" output="false"
		hint="Only run when a session ends.">
		<cfargument name="sessionScope" type="struct" required="true" />
		<!---
		Example onSessionEnd
		<cfset getProperty("sessionFacade").onSessionEnd(arguments.sessionScope) />
		--->
	</cffunction>

	<cffunction name="onRequestStart" returnType="void" output="true"
		hint="Run at the start of a page request.">
		<cfargument name="targetPage" type="string" required="true" />
		
		<cfinclude template="inc_consts.cfm" />

		<!--- Set per session cookies if not using J2EE session management --->
		<!--- <cfif StructKeyExists(session, "cfid") 
			AND (NOT StructKeyExists(cookie, "cfid") OR NOT StructKeyExists(cookie, "cftoken"))>
			<cfcookie name="cfid" value="#session.cfid#" />
			<cfcookie name="cftoken" value="#session.cftoken#" />
		</cfif> --->

		<!--- Temporarily override the default config mode
			Set the configuration mode (when to reinit): -1=never, 0=dynamic, 1=always --->
		<cfif StructKeyExists(url, "reinit")>
			<cfsetting requesttimeout="#REQUEST_TIMEOUT#" />
			<cfset MACHII_CONFIG_MODE = 1 />
		</cfif>

		<!--- Handle the Mach-II requests only --->
		<cfif FindNoCase("index.cfm", ListLast(arguments.targetPage, "/"))>
			<cfset handleRequest() />
		</cfif>
	</cffunction>

	<cffunction name="onError" returnType="void">
	   <cfargument name="Exception" required=true/>
	   <cfargument name="EventName" type="String" required=true/>
	  
	 <!---  <cfdump var="#Exception#"> --->
	  
	   <cftry>
	   <cfmail from="support@tunesBag.com" to="support@tunesBag.com" subject="tunesBag Satellite unhandled exception" type="html">
			<cfdump var="#arguments#">
		</cfmail>
		<cfcatch type="any">
			<!--- no mail server defined --->
		</cfcatch>
		</cftry>
	   
	  <!---  <cfdump var="#arguments#"> --->
	</cffunction>

</cfcomponent>