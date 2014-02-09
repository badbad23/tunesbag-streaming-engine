<cfset variables.exception = event.getArg("exception") />

<cfset stException = { msg = variables.exception.getMessage(), detail = variables.exception.getDetail(), extinfo = variables.exception.getExtendedInfo() } />

<cfset variables.tagCtxArr = variables.exception.getTagContext() />

<cfset stException.path = ArrayNew(1) />
<cfloop index="i" from="1" to="#ArrayLen(variables.tagCtxArr)#">
	<cfset variables.tagCtx = variables.tagCtxArr[i] />
	
	<cfset stException.path[ ArrayLen( stException.path ) +1 ] = variables.tagCtx['template'] & ' ' & variables.tagCtx['line'] />
</cfloop>

<cfquery name="qInsertExceptionLog" datasource="tb_incoming">
INSERT INTO
	logexceptions
	(
	dt_created,
	cfcatch,
	ip,
	href
	)
VALUES
	(
	<cfqueryparam cfsqltype="cf_sql_timestamp" value="#Now()#">,
	<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#SerializeJSON( stException )#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.REMOTE_HOST#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.SCRIPT_NAME#?#cgi.query_string#">
	)
;
</cfquery>

<cfmail from="hansjoerg@tunesbag.com" to="hansjoerg@tunesbag.com" subject="upload exception" type="html">
<p>#variables.exception.getMessage()#</p>
<p>#variables.exception.getDetail()#</p>
<p>#variables.exception.getExtendedInfo()#</p>
	<cfset variables.tagCtxArr = variables.exception.getTagContext() />
			<cfloop index="i" from="1" to="#ArrayLen(variables.tagCtxArr)#">
				<cfset variables.tagCtx = variables.tagCtxArr[i] />
				<p>#variables.tagCtx['template']# (#variables.tagCtx['line']#)</p>
			</cfloop>
			
	<cfdump var="#variables.exception.getCaughtException()#" />
	
	<cfdump var="#cgi#" label="cgi (hostname etc)">		
</cfmail>

<cfif ListFindNoCase( '127.0.0.1,::1', cgi.REMOTE_ADDR ) GT 0>
<h3>Mach-II Exception</h3>

<cfoutput>
<table>
	<tr>
		<td valign="top"><h4>Message</h4></td>
		<td valign="top"><p>#variables.exception.getMessage()#</p></td>
	</tr>
	<tr>
		<td valign="top"><h4>Detail</h4></td>
		<td valign="top"><p>#variables.exception.getDetail()#</p></td>
	</tr>
	<tr>
		<td valign="top"><h4>Extended Info</h4></td>
		<td valign="top"><p>#variables.exception.getExtendedInfo()#</p></td>
	</tr>
	<tr>
		<td valign="top"><h4>Tag Context</h4></td>
		<td valign="top">
			<cfset variables.tagCtxArr = variables.exception.getTagContext() />
			<cfloop index="i" from="1" to="#ArrayLen(variables.tagCtxArr)#">
				<cfset variables.tagCtx = variables.tagCtxArr[i] />
				<p>#variables.tagCtx['template']# (#variables.tagCtx['line']#)</p>
			</cfloop>
		</td>
	</tr>
	<tr>
		<td valign="top"><h4>Caught Exception</h4></td>
		<td valign="top"><cfdump var="#variables.exception.getCaughtException()#" expand="false" /></td>
	</tr>
</table>
</cfoutput> 
</cfif>
<h1>an exception happend, sorry</h1>