<!--- 

	get various metric data and post them back to the main server
	
	a) system load
	b) coldfusion process


 --->

<cfinclude template="/inc/scripts.cfm">

<cfexecute name="w" timeout="15" variable="a_str_w" />

<!--- unify format (Mac / Linux) --->
<cfset a_str_w = ReplaceNocase( a_str_w, 'load averages:', 'load average:' ) />

<!--- get first line --->
<cfset a_str_w = ListGetAt( a_str_w, 1, Chr(10) ) />

<cfset a_str_w = ListLast( a_str_w, ':' ) />

<cfset a_str_w = ListGetAt( a_str_w, 2, ' ' ) />

<!--- handle linux way ... --->
<cfif Right( a_str_w, 1 ) IS ','>
	<cfset a_str_w = ListFirst( a_str_w, ',' ) />
</cfif>

<!--- unify value --->
<cfset a_str_w = ReplaceNoCase( a_str_w, ',', '.', 'ALL' ) />

<!--- <cfexecute name="ps" arguments=" -A" outputfile="/tmp/ps.txt"></cfexecute>

<cffile action="read" charset="utf-8" file="/tmp/ps.txt" variable="a_str_ps" />

<cfset a_int_ffmpeg = WordInstance( a_str_ps, 'ffmpeg' ) /> --->
<cfset a_int_ffmpeg = 0 />


<cfquery name="qSelectUnhandledItems" datasource="tb_incoming">
SELECT
	COUNT( id ) AS count_items
FROM
	uploaded_items
WHERE
	handled = 0
;
</cfquery>

<cfquery name="qSelectWaitingS3Upload" datasource="tb_incoming">
SELECT
	COUNT( id ) AS count_items
FROM
	s3uploadqueue
WHERE
	handled = 0
;
</cfquery>

<cfquery name="qSelectWaitingConverting" datasource="tb_incoming">
SELECT
	COUNT( id ) AS count_items
FROM
	convertjobs
WHERE
	handled = 0
;
</cfquery>


<cfset inet = CreateObject("java", "java.net.InetAddress")>
<cfset inet = inet.getLocalHost()>

<!--- get the host name --->
<cfif Len( cgi.PublicName ) GT 0>
	<!--- public name set? --->
	<cfset sHostname = cgi.PublicName />
<cfelseif Len( cgi.Server_Name ) GT 0>
	<!--- CGI server name --->
	<cfset sHostname = cgi.Server_Name />
<cfelse>
	<!--- java based hostname lookup --->
	<cfset sHostname = inet.getHostName() />
</cfif>

<p>Hostname: <cfoutput>#sHostname#</cfoutput></p>

<cfhttp charset="utf-8" url="#GetMasterServer()#/james/?event=server.ping" method="post">
	<!--- we're a streaming engine AND a INCOMING engine ( 2 + 3 )--->
	<cfhttpparam type="formfield" name="hosttype" value="#GetSettingsProperty( 'HostTypes', '2,3')#">
	<cfhttpparam type="formfield" name="hostname" value="#sHostname#">
	<cfhttpparam type="formfield" name="hostip" value="#inet.getHostAddress()#">
	<cfhttpparam type="formfield" name="ffmpeg_processes" value="#a_int_ffmpeg#">
	<cfhttpparam type="formfield" name="serverload" value="#a_str_w#">
	<cfhttpparam type="formfield" name="waiting_incoming" value="#qSelectUnhandledItems.count_items#">
	<cfhttpparam type="formfield" name="waiting_s3upload" value="#qSelectWaitingS3Upload.count_items#">
	<cfhttpparam type="formfield" name="waiting_converting" value="#qSelectWaitingConverting.count_items#">
</cfhttp>

<!---  -A | grep 'ffmpeg' --->

<cfscript>
/**
* Returns the number of occurances of a word in a string.
* Minor edit by Raymond Camden
*
* @param word      The word to count. (Required)
* @param string      The string to check. (Required)
* @return Returns the number of times the word appears.
* @author Joshua Miller (josh@joshuasmiller.com)
* @version 2, September 20, 2004
*/
function WordInstance(word,string){
    var i=0;
    var start=1;
    var j = 1;
    var tmp = "";
    
    string = " " & string & " ";
    for(j=1;j lte Len(string);j=j+1){
        tmp=REFindNoCase("[^a-zA-Z]+#word#[^a-zA-Z]+",string,start);
        if(tmp gt 0){
            i=i+1;
            start=tmp+Len(word);
        }else{
            start=start+1;
        }
    }
    return i;
}
</cfscript>


status done