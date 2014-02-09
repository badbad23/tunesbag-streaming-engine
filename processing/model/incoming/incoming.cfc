<!--- 

	incoming component
	
	an uploaded file can have three states:
	
	- WAITING = 0 ... has just been uploaded
	- ACTIVE  = 1 ... is handled by a job
	- CLEANUP = 2 ... handled, waiting for cleanup

 --->

<cfcomponent name="incoming" displayname="incoming"output="false" extends="MachII.framework.Listener" hint="Handle incoming requests (upload)">

	<cfinclude template="/inc/scripts.cfm">

	<cffunction name="configure" access="public" output="false" returntype="void" hint="Configures this listener as part of the Mach-II  framework"> 
		<!--- do nothing --->
		
		<cfset var sBaseUploadDirectory = GetIncomingDirectory() />
				
		<cfif NOT DirectoryExists( sBaseUploadDirectory )>
			<cfdirectory action="create" directory="#sBaseUploadDirectory#" />
		</cfif>
		
	</cffunction> 
	
	<cffunction name="CheckIncomingRequest" access="public" output="false" returntype="void"
			hint="check the basics of the incoming request">
		<cfargument name="event" type="MachII.framework.Event" required="true" />

		<cfset var sUserkey = event.getArg( 'userkey' ) />
		<cfset var sPlaylistname = event.getArg( 'playlistname' ) />
		<cfset var sRunkey = event.getArg( 'runkey' ) />
		<cfset var sAuthKey = event.getArg( 'authkey' ) />
		<cfset var sLibrarykey = event.getArg( 'librarykey' ) />
		<cfset var oIncoming = getProperty( 'beanFactory' ).getBean( 'IncomingComponent' ) />
		<cfset var stCheckResult = 0 />
		<cfset var stFiledata = event.getArg( 'filedata' ) />
		<cfset var cffile = 0 />
		<cfset var cffilemeta = 0 />
		<cfset var stData = {} />
		<cfset var iMaxFileSize = 20 />
		<!--- the jobkey --->
		<cfset var stReturn = GenerateReturnStruct() />
		<cfset var sFileNameMetaInformation = '' />
		
		<!--- perform some basic checks --->
		<cfif (Len( sUserkey ) IS 0) OR (Len( sRunkey ) IS 0) OR (Len( sAuthKey ) IS 0) OR (Len( stFiledata ) IS 0)>
			
			<cfmail from="support@tunesBag.com" to="support@tunesBag.com" subject="Upload failed (browser-based)" type="html">
			<cfdump var="#event.getargs()#" label="args">
			<cfdump var="#form#" label="form">
			<cfdump var="#cgi#" label="cgi">
			
			<cfdump var="#url#" label="url">
			</cfmail>
			
			<cflog application="false" file="tb_upload" log="Application" type="information" text="invalid request from #cgi.REMOTE_ADDR# ... userkey: #sUserkey# runkey: #sRunkey# authkey: #sAuthKey# Len(stFiledata): #Len( stFiledata )#" />
			<cfreturn />
		</cfif>
		
		<!---  --->
				
		<!--- handle upload ... move file to /mnt/tunesbag/incoming/temp/ --->
		<cffile action="upload" filefield="filedata" nameconflict="makeunique" result="cffile" destination="#GetTBTempDirectory()#">
		
		<!--- meta information provided? --->
		<cfif Len( event.getArg( 'metainfo' ) ) GT 0>
			<cffile action="upload" filefield="metainfo" nameconflict="makeunique" result="cffilemeta" destination="#GetTBTempDirectory()#" />
			
			<cfset sFileNameMetaInformation = cffilemeta.ServerDirectory & '/' & cffilemeta.ServerFile />
		</cfif>
		
		<!--- insert notification about this new item and perform some checks (quota etc) --->
		<cfset stReturn = oIncoming.InsertNewUploadItemNotification( userkey = sUserkey,
												authkey = sAuthKey,
												ip = cgi.REMOTE_ADDR,
												autoadd2plist = sPlaylistname,
												librarykey = sLibrarykey,
												runkey = sRunkey,
												location = cffile.ServerDirectory & '/' & cffile.ServerFile,
												location_metainfo = sFileNameMetaInformation,
												filesize = cffile.FileSize ) />
												
		<!--- prepare for output --->
		<cfset event.setArg( 'stReturn', stReturn ) />
		
	</cffunction>
	
	<cffunction access="public" name="CheckWaitingJobs" output="false" returntype="void"
			hint="check the new waiting jobs">
		<cfargument name="event" type="MachII.framework.Event" required="true" />
		
		<cfset var qJobs = getProperty( 'beanFactory' ).getBean( 'IncomingComponent' ).GetWaitingJobs() />
		
		<cfset event.setArg( 'qJobs', qJobs ) />

	</cffunction>
	
	<cffunction access="public" name="checkSuccessfullyUploadedFiles" output="false" returntype="void"
			hint="return the list of successfully uploaded items">
		<cfargument name="event" type="MachII.framework.Event" required="true" />
		
		<cfset qSelect = 0 />
		
		<cfquery name="qSelect" datasource="tb_incoming">
		SELECT
			s3uploadqueue.uploadkey,
			uploaded_items.userkey,
			uploaded_items.location,
			uploaded_items.dt_created,
			uploaded_items.priority,
			uploaded_items.originalhashvalue,
			uploaded_items.status,
			uploaded_items.ORIGINALID3TAGS
		FROM
			s3uploadqueue
		LEFT JOIN
			uploaded_items ON (uploaded_items.entrykey = s3uploadqueue.uploadkey)
		WHERE
			s3uploadqueue.done = 1
			AND
			s3uploadqueue.handled = 1
			AND
			s3uploadqueue.success = 1
			AND
			/* status = 2, 2 means storage in progress */
			uploaded_items.status = 2
		;
		</cfquery>
		
		<cfset event.setArg( 'qSelect', qSelect ) />
		
	</cffunction>

</cfcomponent>