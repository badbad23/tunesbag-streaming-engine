<!--- 

	setup database etc

 --->

<cfinclude template="/inc/scripts.cfm">

<!--- driver: org.gjt.mm.mysql.Driver --->

<!--- create jobs --->

<cfschedule urL="http://localhost/processing/?event=checkincoming"
		action="update"
		enddate=""
		endtime="23:59"
		interval="15"
		operation="HTTPRequest"
		resolveurl="false"
		startdate="01/01/1970"
		starttime="00:00"
		task="checkincoming" />

<cfschedule urL="http://localhost/processing/?event=upload2s3"
		action="update"
		enddate=""
		endtime="23:59"
		interval="17"
		operation="HTTPRequest"
		resolveurl="false"
		startdate="01/01/1970"
		starttime="00:00"
		task="upload2s3" />
		
<cfschedule urL="http://localhost/processing/?event=convertfiles"
		action="update"
		enddate=""
		endtime="23:59"
		interval="20"
		operation="HTTPRequest"
		resolveurl="false"
		startdate="01/01/1970"
		starttime="00:00"
		task="convertfiles" />
		
<cfschedule urL="http://localhost/processing/?event=resubmitmetainfo"
		action="update"
		enddate=""
		endtime="23:59"
		interval="15"
		operation="HTTPRequest"
		resolveurl="false"
		startdate="01/01/1970"
		starttime="00:00"
		task="resubmitmetainfo" />
		
<cfschedule urL="http://localhost/maintain/status.cfm"
		action="update"
		enddate=""
		endtime="23:59"
		interval="30"
		operation="HTTPRequest"
		resolveurl="false"
		startdate="01/01/1970"
		starttime="00:00"
		task="submitStatusInformation" />

<cfschedule urL="http://localhost/processing/?event=requestpuidjob"
		action="update"
		enddate=""
		endtime="23:59"
		interval="15"
		operation="HTTPRequest"
		resolveurl="false"
		startdate="01/01/1970"
		starttime="00:00"
		task="requestpuidjob" />
		
<!--- cleanup --->
<cfschedule urL="http://localhost/processing/?event=cleanup"
		action="update"
		enddate=""
		endtime="23:59"
		interval="3600"
		operation="HTTPRequest"
		resolveurl="false"
		startdate="01/01/1970"
		starttime="00:00"
		task="cleanup" />
		
<!--- killlongrunningprocesses --->
<cfschedule urL="http://localhost/processing/?event=killlongrunningprocesses"
		action="update"
		enddate=""
		endtime="23:59"
		interval="90"
		operation="HTTPRequest"
		resolveurl="false"
		startdate="01/01/1970"
		starttime="00:00"
		task="killlongrunningprocesses" />
<h4>SET chmod a+x for bin/</h4>

<!--- <cfadmin action="getMappings"
type="web"
returnVariable="mappings">

<cfdump var="#mappings#">  --->


<!--- // create datasource // --->



<!--- <cfadmin action="updateMapping"
type="web"
password="yourRailoWebAdminPassword"
virtual="/myApplication"
physical="c:\inetpub\wwwroot\myApplication"
archive="{railo-web}/archives/myApplication.ras"
primary="archive"
trusted="yes"> --->