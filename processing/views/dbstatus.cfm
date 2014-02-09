<!--- show database status --->
<html>
	<head>
		<title>DB Status</title>
		<style type="text/css" media="all">
			body,p,a,td {
				font-family:"Lucida Grande",Arial;
				font-size: 11px;
				}
		</style>
	</head>
<body>
	
<cfset oTools = application.beanFactory.getBean( 'Tools' ) />

<!--- <cfdirectory action="list" directory="/Users/hansjorgposch/Music/" filter="*.mp3" name="qSelect" />

<cfoutput query="qSelect" maxrows="50">
<cfdump var="#oTools.calculatePUID( qSelect.directory & '/' & qSelect.name )#"/>
</cfoutput> --->

<!--- 
<cfquery name="qSelect" datasource="tb_incoming">
SELECT * FROM uploaded_items;
</cfquery>

<cfdump var="#qSelect#">

<h2>Uploaded items (<cfoutput>#qSelect.recordcount#</cfoutput>)</h2>

<table>
	<thead>
		<tr>
			<th>Created</th>
			<th>Handled</th>
			<th>Userkey</th>
			<th>Status</th>
			<th>Action</th>
		</tr>
	</thead>
	<cfoutput query="qSelect">
	<tr>
		<td>
			#qSelect.dt_created#
		</td>
		<td>
			#qSelect.handled#
		</td>
		<td>
			#qSelect.userkey#
		</td>
		<td>
			#qSelect.status#
		</td>
		<td>
			<a href="##">Delete</a>
		</td>
	</tr>
	</cfoutput>
</table>

<cfquery name="qSelect" datasource="tb_incoming">
SELECT * FROM convertjobs;
</cfquery>
<h2>Convert jobs (<cfoutput>#qSelect.recordcount#</cfoutput>)</h2>

<cfdump var="#qSelect#">

<cfquery name="qSelect" datasource="tb_incoming">
SELECT * FROM s3uploadqueue;
</cfquery>

<cfdump var="#qSelect#">
 --->

</body>
</html>