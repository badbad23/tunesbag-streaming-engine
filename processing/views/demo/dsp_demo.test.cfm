<h1>demo / testing page</h1>

<!---
	create an upload key etc for this demo run
--->

<cfinclude template="/inc/scripts.cfm">

<cfdump var="master server: #GetMasterServer()#">

<cfset sAuthkey = CreateUUID() />
<!--- TODO: Edit userkey --->
<cfset sUserkey = 'A5C18C15-D3AE-407E-839AC844DEE183D8' />
<cfset sUserkey = '2406ECA1-F205-9A74-1C41F00931943663' />
<cfset sRunkey = CreateUUID() />

<cfquery name="qInsert" datasource="mytunesbutlerlogging">
INSERT INTO
	uploadauthkeys
	(
	dt_created,
	userkey,
	runkey,
	authkey,
	ip
	)
VALUES
	(
	<cfqueryparam cfsqltype="cf_sql_timestamp" value="#Now()#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#sUserkey#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#sRunkey#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#sAuthkey#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.REMOTE_ADDR#">
	)
;
</cfquery>

<form action="?event=upload" method="post" enctype="multipart/form-data">
	
<cfoutput>
<input type="hidden" name="debug" value="true" />
<input type="hidden" name="runkey" value="#sRunkey#" />
<input type="hidden" name="userkey" value="#sUserkey#" />
<input type="hidden" name="librarykey" value="" />
<input type="hidden" name="authkey" value="#sAuthkey#" />
</cfoutput>
	
	<table cellpadding="8">
	<tr>
		<td>
			Plistname
		</td>
		<td>
			<input type="text" name="playlistname" />
		</td>
	</tr>
	<tr>
		<td>File</td>
		<td>
			<input type="file" name="filedata" />	
		</td>
	</tr>
	<tr>
		<td></td>
		<td>
			<input type="submit" value="Upload" />		
		</td>
	</tr>
	</table>
</form>