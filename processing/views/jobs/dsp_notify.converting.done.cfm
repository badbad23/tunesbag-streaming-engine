<!--- 

	a file has been converted / bitrate reduced etc

 --->


<!--- format has been converted successfully --->

<cfset a_Str_jobkey = event.getArg( 'jobkey' ) />
<cfset a_int_ffmpeg_result = Val( event.getArg( 'FFMPEGRESULT' )) />

<!--- send notification --->
<cfset getProperty( 'beanFactory' ).getBean( 'AudioConverter' ).NotifyConvertJobDone( jobkey = a_str_jobkey,
																	ffmpegresult = a_int_ffmpeg_result ) />
										
<!--- run this task ... maybe the next item is already waiting in the queue --->							
<!--- <cfschedule task="checkConvertFileData" action="run"> --->

done.