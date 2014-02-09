<!--- 
	LoginPlugin.cfc (12/15/2003)
	by Rob Schimp (rtschimp@gmail.com)
	
	Description:
		This plugin checks to see if a user is correctly logged in or not.

	Parameters (All Required):
		LoginFormEvent: The event to call in case the user isn't logged in.
		NonLoginEvents: A list of events that shouldn't check to see if the user is logged in.
		LoginVariable: Variable to check to see if the user is logged in.
		
	Example:
		<plugin name="LoginPlugin" type="plugins.LoginPlugin">
			<parameters>
				<parameter name="LoginFormEvent" value="loginMain" />
				<parameter name="NonLoginEvents" value="loginProcess,remote*" />
				<parameter name="LoginVariable" value="session.loggedIn" />
			</parameters>
		</plugin>
	
	NOTE:
		All parameters are required.
		Asterisks (*) can be used on the list of non-login events. However, they can only be used at the end of a string. 
		For example, "remote*" would be a valid non-login event, but "remote*Event*" would not.
		Also note that getPageContext is used to redirect the user if needed.
--->

<cfcomponent displayname="LoginPlugin" extends="MachII.framework.Plugin" hint="This event will redirect the user to a different event if they aren't logged in.">
	<!--- PROPERTIES --->
	<cfscript>
		variables.loginFormEvent = "";
		variables.nonLoginEvents = "";
		variables.loginVariable = "";
	</cfscript>
	
	<!--- CONSTRUCTOR --->
	<cffunction name="configure" access="public" output="true">
		<cfscript>
			variables.loginFormEvent = getParameter('LoginFormEvent');
			variables.nonLoginEvents = getParameter('NonLoginEvents');
			variables.loginVariable = getParameter('LoginVariable');
		</cfscript>
	</cffunction>
	
	<!--- PUBLIC FUNCTIONS --->
	<cffunction name="preProcess" access="public" output="true">
		<cfargument name="eventContext" type="MachII.framework.EventContext" required="true" />
		
		<cfscript>
			//Say that this is the first event (even though at this point we don't have an event)
			//create a new struct just to work with this plugin for request scope.
			request.LoginPluginScope = StructNew();
			request.LoginPluginScope.isFirstEvent = TRUE;
			
			//we'll use this later for our dynamic navigation.
			request.LoginPluginScope.firstEventName = "";
		</cfscript>
		
	</cffunction>
	
	<cffunction name="preEvent" access="public" output="true">
		<cfargument name="eventContext" type="MachII.framework.EventContext" required="true" />
		
		<cfscript>
			var currentEvent = arguments.eventContext.getCurrentEvent();
			var isCurrentEventLoginEvent = FALSE;
			var eventParam = getAppManager().getPropertyManager().getProperty('eventParameter');
			var i = 1;
			var tempNonLoginEvent = "";
			var a_bol_redirect_to_login_form = false;

			//If we are in the first event, check to see if we should go to the login screen.
			//otherwise, check to see if we should be logging in. 
			if (request.LoginPluginScope.isFirstEvent) {
				request.LoginPluginScope.firstEventName = currentEvent.getName();
				request.LoginPluginScope.isFirstEvent = FALSE;

				//check to see if this is a login event or not. (or an event that shouldn't force login)
				if (currentEvent.getName() EQ variables.loginFormEvent OR ListFind(variables.nonLoginEvents, currentEvent.getName())) {
					isCurrentEventLoginEvent = TRUE;
				} else if (Find("*", variables.nonLoginEvents)) {
					for (; i LTE ListLen(variables.nonLoginEvents); i = i + 1) {
						tempNonLoginEvent = ListGetAt(variables.nonLoginEvents, i);
						if (Find("*", tempNonLoginEvent)) {
							tempNonLoginEvent = Left(tempNonLoginEvent, Len(tempNonLoginEvent) - 1);
							//if the event name begins with the same beginning as a starred guy, it is a non-login event
							if (NOT CompareNoCase(Left(currentEvent.getName(), Len(tempNonLoginEvent)), tempNonLoginEvent)) {
								isCurrentEventLoginEvent = TRUE;
								break;
							}
						}
					}
				}
				
				//if we're not in the process of logging in, and don't have a login variable, 
				//redirect to the login screen. Did this since I couldn't figure out how to stop processing
				//this event and future events.
				if (NOT isCurrentEventLoginEvent AND 
					(NOT IsDefined("#variables.loginVariable#") 
					 OR (IsBoolean(Evaluate("#variables.loginVariable#")) AND NOT Evaluate("#variables.loginVariable#")))) {
					arguments.eventContext.clearEventQueue(); //I'm not really sure that this line is needed (since we're redirecting anyway)
					a_bol_redirect_to_login_form = true;
					//getPageContext().forward('index.cfm?#eventParam#=#variables.loginFormEvent#');
				}
			}
		</cfscript>
		
		<!--- redirect to login --->
		<cfif a_bol_redirect_to_login_form>
			<!--- forward to /james/ ... --->
			<cflocation addtoken="false" url="/james/index.cfm?#eventParam#=#variables.loginFormEvent#&returnurl=#UrlEncodedFormat( '?' & cgi.query_string )#">
		<cfelse>
		

		</cfif>

	</cffunction>
	
	<!--- <cffunction name="postEvent" access="public" output="true">
		<cfargument name="eventContext" type="MachII.framework.EventContext" required="true" />
		
	</cffunction>
	
	<cffunction name="preView" access="public" output="true">
		<cfargument name="eventContext" type="MachII.framework.EventContext" required="true" />
		
	</cffunction>
	
	<cffunction name="postView" access="public" output="true">
		<cfargument name="eventContext" type="MachII.framework.EventContext" required="true" />
		
	</cffunction>
	
	<cffunction name="postProcess" access="public" output="true">
		<cfargument name="eventContext" type="MachII.framework.EventContext" required="true" />

	</cffunction> --->

</cfcomponent>