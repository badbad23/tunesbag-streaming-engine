<!--- //

	Module:		Converter
	Action:		
	Description:	
	
// --->

<cfcomponent displayName="converter" hint="convert file formats" output="false">
	
	<cfinclude template="/inc/scripts.cfm">
	
	<cffunction access="public" name="init" returntype="processing.cfc.formats.converter" output="false">
		<cfreturn this />
	</cffunction>
	
	<!--- <cffunction access="public" name="NotifyAltVersionHasBeenConverted" output="false" returntype="void"
			hint="callback that an alternative version of a file has been created">
		<cfargument name="jobkey" type="string" required="true">
		
		<cfset var a_transfer = application.beanFactory.getBean( 'ContentTransfer' ).getTransfer() />
		<cfset var a_item = a_transfer.readByProperty( 'mediaitems.mediaitems_alt_versions', 'jobkey', arguments.jobkey ) />
		
		<cfif a_item.getIsPersisted()>
			<cfset a_item.setconvertdone( 1 ) />
			<cfset a_transfer.save( a_item ) />
		</cfif>
		
	</cffunction> --->
	
	<cffunction access="public" name="CreateConvertFileJob" output="false" returntype="struct"
			hint="reduce the bitrate of a MP3 file ... will work asynchronous">
		<cfargument name="userkey" type="string" required="true" />
		<cfargument name="uploadkey" type="string" required="true"
			hint="entrykey of the upload process" />
		<cfargument name="source" type="string" required="true">
		<cfargument name="operation" type="numeric" required="true"
			hint="the desired operation ... 1 = reduce bitrate; 2 = M4a2MP3, 3= WMA2MP3, 4 = OGG 2 MP3">
		<cfargument name="format" type="string" default="mp3" required="false"
			hint="the target format ... currently only mp3 is supported and implemented">
		<cfargument name="bitrate" type="numeric" default="192" required="false"
			hint="the target bitrate">
		<cfargument name="id3tags" type="struct" required="true"
			hint="the original data before the reduction of the bitrate (will save the file later with this data again)">
		
		<cfset var stReturn = GenerateReturnStruct() />
		<!---  jobkey --->
		<cfset var sJobkey = CreateUUID() />		
		<!--- destination file --->
		<cfset var sDestfile = GetTBTempDirectory() & 'converted_' & CreateUUID() & '.mp3' />
		<cfset var sJobDirectory = GetTBTempDirectory() & 'converts/' />
		<cfset var stReturn_converter = 0 />
		<cfset var qSelectJobAlreadyExists = 0 />
		
		<cfif NOT DirectoryExists( sJobDirectory )>
			<cfdirectory action="create" directory="#sJobDirectory#">
		</cfif>
		
		<!--- check if this job already exists ... --->
		<cfinclude template="queries/qSelectJobAlreadyExists.cfm">
		
		<cfif qSelectJobAlreadyExists.count_id GT 0>
			<cfreturn SetReturnStructErrorCode(stReturn, 999, 'This job already exists') />
		</cfif>
		
		<cfinclude template="queries/q_insert_convert_job.cfm">
		
		<cfset stReturn.jobkey = sJobkey />
		
		<cfswitch expression="#arguments.operation#">
			<cfcase value="1">
			
				<!--- reduce bitrate of a MP3 --->
				<cfset stReturn_converter = CreateConvertJob(jobkey = sJobkey,
							audiosourcetype = arguments.operation,
							source = arguments.source,
							destination = sDestfile,
							currentbitrate = arguments.id3tags.bitrate,
							targetbitrate = arguments.bitrate ) />
							
				<cfif NOT stReturn_converter.result>
					<cfreturn stReturn_converter />
				</cfif>
			
			</cfcase>
			<cfcase value="2,3,4">
			
				<!--- m4a / WMA / OGG to MP3 --->
				<cfset stReturn_converter = CreateConvertJob(jobkey = sJobkey,
							audiosourcetype = arguments.operation,
							source = arguments.source,
							destination = sDestfile,
							currentbitrate = arguments.id3tags.bitrate,
							targetbitrate = arguments.bitrate ) />
							
				<cfif NOT stReturn_converter.result>
					<cfreturn stReturn_converter />
				</cfif>			
				
			
			</cfcase>
		</cfswitch>
		
		<!--- save script to database --->
		<cfquery name="qUpdateShellScript" datasource="tb_incoming">
		UPDATE
			convertjobs
		SET
			shellscript = <cfqueryparam cfsqltype="cf_sql_varchar" value="#stReturn_converter.script#">
		WHERE
			entrykey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#sJobkey#">
		;
		</cfquery>
		
		<cfreturn SetReturnStructSuccessCode(stReturn) />		

	</cffunction>
	
	<cffunction access="public" name="getConvertingJobByEntrykey" output="false" returntype="query"
			hint="return all details by it's entrykey">
		<cfargument name="entrykey" type="string" required="true"
			hint="entrykey of this job" />
			
		<cfset var qSelectConvertJobByEntrykey = 0 />
		<cfinclude template="queries/qSelectConvertJobByEntrykey.cfm">
		
		<cfreturn qSelectConvertJobByEntrykey />
	</cffunction>
	
	<cffunction access="public" name="NotifyConvertJobDone" output="false" returntype="void"
			hint="A converting job has been executed successfully">
		<cfargument name="jobkey" type="string" required="true">
		<cfargument name="ffmpegresult" type="numeric" required="true"
			hint="return code of ffmpeg">
		
		<cfset var qConvertingJob = getConvertingJobByEntrykey( entrykey = arguments.jobkey ) />
		<!--- set job done in the main table of incoming items --->
		<cfset var qSelectOriginalID3Tags = 0 />
		<!--- the location of the ffmpeg logfile --->
		<cfset var a_str_ffmpeg_log_file = GetTBTempDirectory() & 'converts/ffmpeg_log_' & arguments.jobkey & '.txt' />
		<cfset var a_str_ffmpeg_log = '' />
		<cfset var a_struct_id3 = 0 />
		<cfset var qUpdate = 0 />
		<cfset var qUpdateUploadQueue = 0 />
		
		<cfif qConvertingJob.recordcount IS 0>
			<cfreturn />
		</cfif>
		
		<!--- try to read the logfile --->
		<cfif FileExists( a_str_ffmpeg_log_file )>
			<cffile action="read" file="#a_str_ffmpeg_log_file#" variable="a_str_ffmpeg_log">
		</cfif>
		
		<!---  set done and store --->
		<cfquery name="qUpdate" datasource="tb_incoming">
		UPDATE
			convertjobs
		SET
			<!--- everything OK? --->
			<cfif arguments.ffmpegresult IS 0>
				done = 1,
			</cfif>
				ffmpeglog = <cfqueryparam cfsqltype="cf_sql_varchar" value="#a_str_ffmpeg_log#" />,
				errorno = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.ffmpegresult#" />
		WHERE
			convertjobs.entrykey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.jobkey#">
		;
		</cfquery>
				
		<!--- job failed; exit --->
		<cfif NOT arguments.ffmpegresult IS 0>
			<cfreturn />
		</cfif>
		
		<cfquery name="qSelectOriginalID3Tags" datasource="tb_incoming">
		SELECT
			originalid3tags
		FROM
			uploaded_items
		WHERE
			convertjobkey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.jobkey#">
		;
		</cfquery>
		
		<!--- tag new converted file with original informations --->
		<cfwddx input="#qSelectOriginalID3Tags.originalid3tags#" output="a_struct_id3" action="wddx2cfml">
		
		<cfset application.beanFactory.getBean( 'MP3Reader' ).TagMP3FileWithGivenData( filename = qConvertingJob.destfile,
					metainfo = a_struct_id3 ) />
		
		<!--- replace original incoming file with new, converted one and proceed;
			mark file already as processed
			re-throw in the queue with a higher priority! --->		
			
		<cfquery name="qUpdateUploadQueue" datasource="tb_incoming">
		UPDATE
			uploaded_items
		SET
			location = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qConvertingJob.destfile#">,
			priority = 5,
			handled = 0,
			status = 2,
			audionormalizedone = 1
		WHERE
			entrykey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qConvertingJob.uploadkey#">
		;
		</cfquery>
		
		<!--- delete old original file if it still exists --->
		<cfif FileExists( qConvertingJob.sourcefile )>
			<cffile action="delete" file="#qConvertingJob.sourcefile#">
		</cfif>

	</cffunction>	
	
	<cffunction access="public" name="CreateConvertJob" output="false" returntype="struct"
			hint="create the bitrate reduction job">
		<cfargument name="audiosourcetype" type="numeric" required="true"
			hint="integer, type of source">
		<cfargument name="jobkey" type="string" required="true"
			hint="entrykey for this job">
		<cfargument name="source" type="string" required="true"
			hint="source file">
		<cfargument name="destination" type="string" required="true"
			hint="destination file">
		<cfargument name="currentbitrate" type="numeric" required="true"
			hint="the current bitrate">
		<cfargument name="targetbitrate" type="numeric" required="true"
			hint="target bitrate">
			
		<cfset var stReturn = GenerateReturnStruct() />
		<cfset var sSHFile = GetTBTempDirectory() & 'converts/convert_' & arguments.audiosourcetype & '_format_' & arguments.jobkey & '.sh' />
		<cfset var sSHContent = '' />
		<cfset var sHostInfo = getCurrentServerURI() />
		<cfset var sFFMpegLogFile = GetTBTempDirectory() & 'converts/ffmpeg_log_' & arguments.jobkey & '.txt' />
		<cfset var iTargetBitrate = arguments.targetbitrate />
		
		<!--- do not create a file with a HIGHER bitrate --->
		<cfif (arguments.currentbitrate GT 0) AND (arguments.currentbitrate LT arguments.targetbitrate)>
			<cfset iTargetBitrate = arguments.currentbitrate />
		</cfif>
		

		<!--- write sh script:
		
		- convert
		
		let ffmpeg convert the file to WAV and lame do the encoding with VBR quality 2 and max bitrate given as argument
		write ffmpeg log to given file
		
		http://forum.doom9.org/archive/index.php/t-130499.html
		- notify engine that job is done
		
		LAME quality
		http://www.mpex.net/info/lame.html
		
		LAME commands
		http://lame.cvs.sourceforge.net/*checkout*/lame/lame/USAGE
		- exit

		added nice to lame so that we take as few resources as possible
		 --->
<cfsavecontent variable="sSHContent"><cfoutput>
ffmpeg -i "#arguments.source#" -vn -f wav - 2> #sFFMpegLogFile# | nice -n 19 lame -V 2 --abr #iTargetBitrate# - #arguments.destination#
FFMPEGRESULT=$?
## mp3gain #arguments.destination#
wget "#sHostInfo#/processing/?event=notify.converting.done&jobkey=#UrlEncodedFormat( arguments.jobkey )#&ffmpegresult=$FFMPEGRESULT" > /dev/null
</cfoutput></cfsavecontent>	

		<cfif FileExists( sSHFile )>
			<cffile action="delete" file="#sSHFile#">
		</cfif>
		
		<cfset stReturn.script = Trim( sSHContent ) />
	
		<cfreturn SetReturnStructSuccessCode(stReturn) />

	</cffunction>
	
	<cffunction access="public" name="GetNextOpenConvertJobs" output="false" returntype="struct"
			hint="return the ONE next open convert jobs to execute">
				
		<cfset var q_select_open_convert_jobs = 0 />
		<cfset var stReturn = GenerateReturnStruct() />
		<cfset var a_item = 0 />
		<cfset var a_str_sh_script = '' />
		<cfset var qSelectOpenConvertJobs = 0 />
		<cfset var qUpdateHandled = 0 />
		
		<!--- just get the NEXT job (ONE item max) --->
		<cfinclude template="queries/qSelectOpenConvertJobs.cfm">
		
		<!--- no items --->
		<cfif q_select_open_convert_jobs.recordcount IS 0>
			<cfreturn SetReturnStructErrorCode(stReturn, 999, 'No items found') />
		</cfif>
		
		<!--- more than 3 jobs should not be running at the same time ... --->
		<cfif q_select_convert_active_processes.count_open_jobs GT 2>
			<cfreturn SetReturnStructErrorCode(stReturn, 999, 'Too many open requests') />
		</cfif>
		
		<cfquery name="qUpdateHandled" datasource="tb_incoming">
		UPDATE
			convertjobs
		SET
			/* handled, and now! */
			handled = 1,
			dt_started = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#Now()#">
		WHERE
			convertjobs.entrykey IN (<cfqueryparam cfsqltype="cf_sql_varchar" value="#ValueList( q_select_open_convert_jobs.entrykey )#" list="true">)
		;
		</cfquery>
				
		<cfset stReturn.q_select_open_convert_jobs = q_select_open_convert_jobs />
		
		<cfreturn SetReturnStructSuccessCode(stReturn) />
			
	</cffunction>
	
</cfcomponent>