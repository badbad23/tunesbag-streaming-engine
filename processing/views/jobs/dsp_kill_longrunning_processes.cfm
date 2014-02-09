<!--- 

	kill long running processes

 --->
<cftry>
<cfsavecontent variable="sScript">ps -lfe > /tmp/processes.txt
</cfsavecontent>

<cffile action="write" file="#GetTempDirectory()#/kill_long_running_processes.sh" output="#sScript#">

<cfexecute name="sh" arguments="#GetTempDirectory()#/kill_long_running_processes.sh" />

<cffile action="read" file="/tmp/processes.txt" variable="sProcesses">

<cfloop list="#sProcesses#" delimiters="#Chr(10)#" index="sLine">
	
<cfset sLine = Trim( sLine ) />


	
<!--- a line: 

	0 R www-data 27993 27990 95 85 0 - 1000 - 12:06 ? 01:13:09 sox -t wav - -t wav - fade t 3 20 3
	 --->

<cfif FindNoCase( 'sox', sLine ) GT 0>
	<cfset aProps = ListToArray( sLine, ' ' ) />
	
	<cfoutput>#sLine#</cfoutput><br />
	<!--- 14 is the time --->
	
	<cfset iID = aProps[ 4 ] />
	<cfset sTime = aProps[ 14 ] />
	
	<cfset aTime = ListToArray( sTime, ':' ) />
	
	<cfset iTimeRunnigSecods = aTime[ 3 ] + aTime[ 2 ] * 60 + aTime[ 1 ] * 60 * 60 />
	
	<cfdump var="#iTimeRunnigSecods#">
	
	<!--- 2 mins max --->
	<cfif iTimeRunnigSecods GT 120>
		<h4>kill <cfoutput>#iID#</cfoutput>!</h4>
		
		<cfexecute name="kill" arguments="-9 #iId#" timeout="0" />
		
	</cfif>
	
</cfif>
	
</cfloop>


<cfcatch type="any">
	<cfdump var="#cfcatch#">
</cfcatch>
</cftry>

done.