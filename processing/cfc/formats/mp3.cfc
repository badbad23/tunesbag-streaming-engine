<!--- //

	Module:		Parse out mp3 tags
	Action:		
	Description:	
	
// --->

<cfcomponent displayName="MP3" hint="Reads ID3 information from an MP3" output="false">
	
	<cfinclude template="/inc/scripts.cfm">
	
	<cffunction access="public" name="init" returntype="processing.cfc.formats.mp3" output="false">
		<cfreturn this />
	</cffunction>
	
	<cffunction access="public" name="ParseMP3File" output="false" returntype="struct"
			hint="return basic information about mp3">
		<cfargument name="filename" type="string" required="true"
			hint="filename">
		
		<cfset var a_struct_return = GenerateReturnStruct() />	
		<cfset var a_parser = CreateObject('java', 'org.jaudiotagger.audio.AudioFileIO').init() />
		<cfset var a_str_file_java = 0 />
		<cfset var a_read_file = 0 />
		<cfset var a_v1_info = 0 />
		<cfset var a_v2_info = 0 />
		<cfset var a = 0 />
		<cfset var a_str_key = '' />
		<!--- data --->
		<cfset var a_str_name = '' />
		<cfset var a_str_artist = '' />
		<cfset var a_str_album = '' />
		<cfset var a_str_genre = '' />
		<cfset var a_str_year = '' />
		<cfset var a_str_track = '' />
		<cfset var a_str_lyrics = '' />
		
		<!--- audio info --->
		<cfset var a_struct_file_info = 0 />
		<cfset var a_2nd_opinion = 0 />
		
		<!--- create the very basic structure ... --->
		<cfset var a_struct_meta = ReturnBasicMediaMetaInformationStructure() />
		
		<!--- file not found? --->
		<cfif NOT FileExists(arguments.filename)>
			<cfreturn SetReturnStructErrorCode(a_struct_return, 4000) />
		</cfif>
		
		<cfset a_str_file_java = CreateObject("java","java.io.File").Init(arguments.filename) />
		
		<cfset a_struct_meta.size = a_str_file_java.length() />
		
		<!--- read the file ... --->
		<cftry>
		<cfset a_read_file = a_parser.readFile(a_str_file_java) />
		<cfcatch>
			<!--- <cfmail from="support@tunesBag.com" to="support@tunesBag.com" subject="error on mp3 reading" type="html"><cfdump var="#arguments#"><cfdump var="#cfcatch#"></cfmail> --->
			<cfreturn SetReturnStructErrorCode(a_struct_return, 4101) />
		</cfcatch>
		</cftry>
		
		<!--- reading is possible? --->
		<cftry>
		<cfset a = a_read_file.hasID3v1Tag() />
		<cfcatch type="any">
			<cfmail from="hansjoerg@tunesBag.com" to="hansjoerg@tunesBag.com" subject="error on mp3 reading - no hasID3v1Tag" type="html">
				<cfdump var="#arguments#"><cfdump var="#cfcatch#">
				<h2>what about v2?</h2>
				<cftry>
					<cfdump var="#a_read_file.hasID3v2Tag()#">
					<cfcatch type="any">
						<cfdump var="#cfcatch#">
					</cfcatch>
				</cftry>
			</cfmail>
			<cfreturn SetReturnStructErrorCode(a_struct_return, 4101) />
		</cfcatch>
		</cftry>
		
		<!--- try v1 --->
		<cfif a_read_file.hasID3v1Tag()>
			
			<cfset a_struct_meta = TryReadV1Tag(datastruct = a_struct_meta, infotag = a_read_file.getID3v1Tag()) />

		</cfif>
		
		<!--- next: check v2 --->
		<cfif a_read_file.hasID3v2Tag()>
			
			<cfset a_struct_meta = TryReadV2Tag(datastruct = a_struct_meta, infotag = a_read_file.getID3v2Tag()) />
		</cfif>
				
		<!--- find some further informations --->
		<cftry>
			<cfset a_struct_file_info = a_read_file.getMP3AudioHeader() />
			
			<!---  bitrate --->
			<cfset a_struct_meta.bitrate = ReplaceNoCase( a_struct_file_info.getBitRate(), '~', '' ) />
			<cfset a_struct_meta.samplerate = a_struct_file_info.getSampleRate() />
			<cfset a_struct_meta.tracklength = Val( a_struct_file_info.getTrackLength() ) />
			<cfset a_struct_meta.format = a_struct_file_info.getFormat() />
			
			<cfcatch type="any"></cfcatch>
		</cftry>
		
		<cfset a_struct_file_info = 0 />
		
		<!--- track len is 0 ... get a second opinion ... --->
		<cfif Val( a_struct_meta.tracklength ) IS 0>
		
			<cfset a_2nd_opinion = CreateObject('java', 'entagged.audioformats.AudioFileIO').init() />
			
			<cftry>
				
				<cfset a_2nd_opinion = a_parser.readFile( a_str_file_java ) />
				<cfset a_struct_meta.tracklength = Val( a_2nd_opinion.getPreciseLength() ) />
			
			<cfcatch type="any"></cfcatch>
			</cftry>
			
			<cfset a_2nd_opinion = 0 />
		
		</cfif>
		
		<!--- return data --->
		<cfset a_struct_return.metainformation = a_struct_meta />
		
		<cfset a_str_file_java = 0 />
		
		<cfreturn SetReturnStructSuccessCode(a_struct_return) />
	
	</cffunction>
	
	<cffunction access="public" name="TagMP3FileWithGivenData" output="false" returntype="struct"
			hint="tag the given MP3 file with the information given in the structure">
		<cfargument name="filename" type="string" required="true"
			hint="path to MP3">
		<cfargument name="metainfo" type="struct" required="true"
			hint="structure holding the MP3 ID3 tags to write to the file">
			
		<cfset var a_struct_return = GenerateReturnStruct() />
		<cfset var a_str_file_java = CreateObject("java","java.io.File").Init( arguments.filename ) />	
		<cfset var a_id3_info = 0 />
		<cfset var a_parser = CreateObject('java', 'org.jaudiotagger.audio.AudioFileIO').init() />
		<cfset var a_new_tag = CreateObject( 'java', 'org.jaudiotagger.tag.id3.ID3v11Tag' ) />
		<cfset var a_v22 = 0 />
		<cfset var a_read_file = 0 />
		
		<cftry>
		<cfset a_read_file = a_parser.readFile(a_str_file_java) />
		<cfcatch>
			<cfreturn SetReturnStructErrorCode(a_struct_return, 999, 'Could not read the file') />
		</cfcatch>
		</cftry>
		
		<!--- set data --->
		<cfif StructKeyExists( arguments.metainfo, 'album' )>
			<cfset a_new_Tag.setalbum( arguments.metainfo.album ) />
		</cfif>
		<cfif StructKeyExists( arguments.metainfo, 'artist' )>
			<cfset a_new_Tag.setartist( arguments.metainfo.artist ) />
		</cfif>
		<cfif StructKeyExists( arguments.metainfo, 'comment' )>
			<cfset a_new_Tag.setComment( trim( Left( arguments.metainfo.comment, 50 )) ) />
		</cfif>
		<cfif StructKeyExists( arguments.metainfo, 'genre' )>
			<cfset a_new_Tag.setgenre( arguments.metainfo.genre ) />
		</cfif>
		<cfif StructKeyExists( arguments.metainfo, 'name' )>
			<cfset a_new_Tag.settitle( arguments.metainfo.name ) />
		</cfif>
		<cfif StructKeyExists( arguments.metainfo, 'trackno' )>
			<cfset a_new_Tag.setTrack( JavaCast( "string", Val( arguments.metainfo.trackno )) ) />
		</cfif>		
		<cfif StructKeyExists( arguments.metainfo, 'year' )>
			<cfset a_new_Tag.setyear( trim( Left( arguments.metainfo.year, 4) )) />
		</cfif>
		
		<cfset a_v22 = createObject( 'java', 'org.jaudiotagger.tag.id3.ID3v22Tag' ).init( a_new_tag) />

		<cfset a_read_file.setID3v2Tag( a_v22 ) />

		<cfset a_read_file.commit() />
		<cfset a_read_file.save() />

		<cfreturn SetReturnStructSuccessCode(a_struct_return) />
		
	</cffunction>
	
	<cffunction access="public" name="ApplyMP3GainOnFile" output="false" returntype="struct"
			hint="apply mp3gain to a file">
		<cfargument name="source" type="string" required="true">
		
		<cfset var a_struct_return = GenerateReturnStruct() />
		
		<!--- execute mp3gain --->
		<cftry>
		<cfexecute name="mp3gain" arguments="#arguments.source#" timeout="45"></cfexecute>
		<cfcatch type="any">
			<!--- ignore timeouts --->
		</cfcatch>
		</cftry>

		<cfreturn SetReturnStructSuccessCode(a_struct_return) />
		
	</cffunction>
	
	<cffunction access="public" name="CreateReduceBitrateJob" output="false" returntype="struct"
			hint="create the bitrate reduction job">
		<cfargument name="jobkey" type="string" required="true"
			hint="entrykey for this job">
		<cfargument name="source" type="string" required="true"
			hint="source file">
		<cfargument name="destination" type="string" required="true"
			hint="destination file">
		<cfargument name="bitrate" type="numeric" required="true"
			hint="target bitrate">
			
		<cfset var a_struct_return = GenerateReturnStruct() />
		<cfset var a_str_sh_file = GetTBTempDirectory() & 'converts/reduce_mp3_bitrate_' & arguments.jobkey & '.sh' />
		<cfset var a_str_sh_content = '' />
		<cfset var a_str_host_info = getCurrentServerURI() />
		<cfset var a_str_ffmpeg_log_file = GetTBTempDirectory() & 'converts/ffmpeg_log_' & arguments.jobkey & '.txt' />
		

		<!--- write sh script:
		
		- convert
		- notify engine that job is done
		- exit
		
		 --->
<cfsavecontent variable="a_str_sh_content"><cfoutput>##!/bin/bash
ffmpeg -y -i "#arguments.source#" -ab #arguments.bitrate#k #arguments.destination# 2> #a_str_ffmpeg_log_file#
FFMPEGRESULT=$?
mp3gain #arguments.destination#
wget "#a_str_host_info#/james/?event=jobs.exec&type=notify.reducebitrate&jobkey=#UrlEncodedFormat( arguments.jobkey )#&ffmpegresult=$FFMPEGRESULT" > /dev/null
echo "Done"
</cfoutput></cfsavecontent>	

		<cfif FileExists( a_str_sh_file )>
			<cffile action="delete" file="#a_str_sh_file#">
		</cfif>

		<cffile action="write" output="#a_str_sh_content#" file="#a_str_sh_file#" addnewline="false" charset="utf-8">
		
		<cfexecute name="sh" arguments="#a_str_sh_file#" timeout="0"></cfexecute>		
	
		<cfreturn SetReturnStructSuccessCode(a_struct_return) />

	</cffunction>
	
	<cffunction access="public" name="NotifyBitrateReductionJobDone" output="false" returntype="void"
			hint="set a job done">
		<cfargument name="jobkey" type="string" required="true">
		<cfargument name="ffmpegresult" type="numeric" required="true"
			hint="return code of ffmpeg">
		
		<cfset var a_transfer = application.beanFactory.getbean( 'ContentTransfer' ).getTransfer() />
		<cfset var a_item = a_transfer.get( 'converter.convertjobs', arguments.jobkey ) />
		<!--- set job done in the main table of incoming items --->
		<cfset var a_item_queue = a_transfer.readByProperty( 'storage.uploaded_items', 'convertjobkey', arguments.jobkey ) />
		<!--- the location of the ffmpeg logfile --->
		<cfset var a_str_ffmpeg_log_file = GetTBTempDirectory() & 'converts/ffmpeg_log_' & arguments.jobkey & '.txt' />
		<cfset var a_str_ffmpeg_log = '' />
		<cfset var a_struct_id3 = 0 />
		
		<cfif NOT a_item.getIsPersisted()>
			<cfreturn />
		</cfif>
		
		<cfif FileExists( a_str_ffmpeg_log_file )>
			<cffile action="read" file="#a_str_ffmpeg_log_file#" variable="a_str_ffmpeg_log">
		</cfif>
		
		<!---  set done and store --->
		
		<!--- everything OK? --->
		<cfif arguments.ffmpegresult IS 0>
			<cfset a_item.setdone( 1 ) />
		</cfif>

		<!--- store output --->
		<cfset a_item.setffmpeglog( a_str_ffmpeg_log ) />
		<cfset a_item.seterrorno( arguments.ffmpegresult ) />
		<cfset a_transfer.update( a_item ) />
		
		<!--- job failed; exit --->
		<cfif NOT arguments.ffmpegresult IS 0>
			<cfreturn />
		</cfif>
		
		<cfif NOT a_item_queue.getisPersisted()>
			<cfreturn />
		</cfif>
		
		<!--- tag new converted file with original informations --->
		<cfwddx input="#a_item_queue.getoriginalid3tags()#" output="a_struct_id3" action="wddx2cfml">
		<cfset TagMP3FileWithGivenData( filename = a_item.getdestfile(), metainfo = a_struct_id3 ) />
		
		<!--- replace original incoming file with new, converted one and proceed; mark file already as processed --->
		<!--- re-throw in the queue with a higher priority! --->
		<cfset a_item_queue.setlocation( a_item.getdestfile() ) />
		<cfset a_item_queue.setpriority( 5 ) />
		<cfset a_item_queue.sethandled( 0 ) />
		
		<!--- already normalized, save status --->
		<cfset a_item_queue.setaudionormalizedone( 1 ) />
		
		<cfset a_transfer.save( a_item_queue ) />

	</cffunction>
	
	<cffunction access="private" name="TryReadV2Tag" output="false" returntype="struct"
			hint="read much more complex v2 structure and try even to read and save the artwork">
		<cfargument name="datastruct" type="struct" required="true"
			hint="the struct to return">
		<cfargument name="infotag" type="any" required="true"
			hint="the info tag">
			
		<cfset var a_struct_return = arguments.datastruct />
		<cfset var a_v1_tag = arguments.infotag />
		<cfset var a_struct_frames = arguments.infotag.frameMap />
		<cfset var a_str_item = '' />
		<cfset var a_str_identifier = '' />
		<cfset var a_str_value = '' />
		<cfset var a_struct_item = 0 />
		<cfset var a_struct_v2_data = StructNew() />
		<cfset var a_int_ii = 0 />
		<cfset var a_bin_artwork = 0 />
		<cfset var a_str_artwork_filename = GetTBTempDirectory() & 'artwork/artwork_' & createUUID() & '.jpg' />
		<cfset var local = {} />
		
		<cfif NOT DirectoryExists( GetDirectoryFromPath( a_str_artwork_filename ))>
			<cfdirectory action="create" directory="#GetDirectoryFromPath( a_str_artwork_filename )#">
		</cfif>
			
		<!--- loop through the keys of the structure --->
		<cfloop collection="#a_struct_frames#" item="a_str_item">
			
			<cfset a_struct_item = a_struct_frames[a_str_item] />
			<cfset a_str_identifier = '' />
			
			<cfif IsArray(a_struct_item)>
				
				<cfloop from="1" to="#arrayLen(a_struct_item)#" index="a_int_ii">
					<cfset a_struct_v2_data = CheckV2FrameItem( v2struct = a_struct_v2_data, item = a_struct_item[a_int_ii] ) />
				</cfloop>
				
			<cfelse>
			
				<cfset a_struct_v2_data = CheckV2FrameItem( v2struct = a_struct_v2_data, item = a_struct_item ) />
				
			</cfif>
			
		</cfloop>
		
		<cfloop collection="#a_struct_v2_data#" item="a_str_item">
			
			<!--- get the item --->
			<cfset a_str_value = Trim(a_struct_v2_data[a_str_item]) />
			
			<!--- check what to use --->
			<cfswitch expression="#a_str_item#">
				<cfcase value="TAL,TALB">
					<cfset a_struct_return.album = a_str_value />
				</cfcase>
				<cfcase value="TRCK,TRK">
					<cfset a_struct_return.trackno = a_str_value />
				</cfcase>
				<cfcase value="TPE1,TP1">
					<cfset a_struct_return.artist = a_str_value />
				</cfcase>
				<cfcase value="TCON,TCO">
					<cfset a_struct_return.genre = a_str_value />
				</cfcase>
				<cfcase value="TIT2,TIT1,TT2">
					<cfset a_struct_return.name = a_str_value />		
				</cfcase>
				<cfcase value="TYER,TYE">
					<cfset a_struct_return.year = a_str_value />		
				</cfcase>
				<cfcase value="ULT">
					<cfset a_struct_return.lyrics = a_str_value />
				</cfcase>
			</cfswitch>
			
		</cfloop>
		
		<!--- try to read the artwork ... --->
		<cftry>		
			<cfset a_bin_artwork = arguments.infotag.getFirstArtwork().getBinaryData() />
			
			<cffile action="write" file="#a_str_artwork_filename#" output="#a_bin_artwork#">
			
			<!--- try to read artwork --->
			
			<cfimage action="info" source="#a_str_artwork_filename#" structName="local.stInfo" />
			
			<!--- resize --->
			<cfif local.stInfo.height GT 300 OR local.stInfo.width GT 300>
				<cfimage action="resize" source="#a_str_artwork_filename#" destination="#a_str_artwork_filename#" overwrite="true" width="300" />
				
				<!--- re-read --->
				<cffile action="readbinary" file="#a_str_artwork_filename#" variable="a_bin_artwork" />
			</cfif>
			
			<!--- return saved temp file --->
			<cfset a_struct_return.artworkFilename = a_str_artwork_filename />
			
			<!--- save as string --->
			<cfset a_struct_return.artworkfilecontent = ToBase64( a_bin_artwork ) />
			
		<cfcatch type="any">
			<!--- no hit --->
			<!--- <cfmail from="support@tunesBag.com" to="support@tunesBag.com" subject="catch MP3 reading cover art" type="html">
			<cfdump var="#cfcatch#">
			<cfdump var="#arguments#">
			</cfmail> --->
		</cfcatch>
		</cftry>
			
		<cfreturn a_struct_return />
	</cffunction>
	
	<cffunction access="private" name="CheckV2FrameItem" output="false" returntype="struct">
		<cfargument name="v2struct" type="struct" required="true">
		<cfargument name="item" type="any" required="true">
		
		<cfset var a_struct_return = arguments.v2struct />
		<cfset var a_str_identifier = '' />
		
		<cftry>
			<cfset a_str_identifier = arguments.item.getIdentifier() />
		<cfcatch type="any">
			<cfset a_str_identifier = '' />
		</cfcatch>
		</cftry>
		
		<cfif NOT IsDefined('a_str_identifier')>
			<cfreturn a_struct_return />
		</cfif>
	
		<cfswitch expression="#a_str_identifier#">
			<cfcase value="ULT">
				<cfset a_struct_return[ a_str_identifier ] = Trim(arguments.item.getBody()) />

			</cfcase>
			<cfdefaultcase>
				<cftry>
					<cfset a_struct_return[ a_str_identifier ] = Trim( arguments.item.getBody().getText() ) />
				<cfcatch type="any">
				</cfcatch>
				</cftry>
				
			</cfdefaultcase>
		</cfswitch>
		
		<cfreturn a_struct_return />
	</cffunction>
	
	<cffunction access="private" name="TryReadV1Tag" output="false" returntype="struct">
		<cfargument name="datastruct" type="struct" required="true"
			hint="the struct to return">
		<cfargument name="infotag" type="any" required="true"
			hint="the info tag">
			
		<cfset var a_struct_return = arguments.datastruct />
		<cfset var a_v1_tag = arguments.infotag />
		<cfset var a_arr_tmp = 0 />
		
		<cftry>
			
			<cfif IsArray( a_v1_tag.getArtist() )>
				<cfset a_arr_tmp = a_v1_tag.getArtist() />
				<cfset a_struct_return.artist = a_arr_tmp[ 1 ].toString() />
						
			<cfelse>
				<cfset a_struct_return.artist = a_v1_tag.getArtist().toString() />			
			</cfif>

		<cfcatch type="any">
			<cfset a_struct_return.artist = '' />
		</cfcatch></cftry>
		
		<cfif NOT StructKeyExists(a_struct_return, 'artist')>
			<cfset a_struct_return.artist = '' />
		</cfif>
	
		<cftry>
			
			<cfif IsArray( a_v1_tag.getAlbum() )>
				<cfset a_arr_tmp = a_v1_tag.getAlbum() />
				<cfset a_struct_return.album = a_arr_tmp[ 1 ].toString() />
						
			<cfelse>
				<cfset a_struct_return.album = a_v1_tag.getAlbum().toString() />	
			</cfif>
		
		<cfcatch type="any">
			<cfset a_struct_return.album = '' />
		</cfcatch></cftry>
		
		<cfif NOT StructKeyExists(a_struct_return, 'album')>
			<cfset a_struct_return.album = '' />
		</cfif>
			
		<cftry>
			
			<cfif IsArray( a_v1_tag.getGenre() )>
				<cfset a_arr_tmp = a_v1_tag.getGenre() />
				<cfset a_struct_return.genre = a_arr_tmp[ 1 ].toString() />
						
			<cfelse>
				<cfset a_struct_return.genre = a_v1_tag.getGenre().toString() />
			</cfif>
			
		<cfcatch type="any">
			<cfset a_struct_return.genre = '' />
		</cfcatch></cftry>
		
		<cfif NOT StructKeyExists(a_struct_return, 'genre')>
			<cfset a_struct_return.genre = '' />
		</cfif>
	
		<cftry>
		
			<cfif IsArray( a_v1_tag.getTitle() )>
				<cfset a_arr_tmp = a_v1_tag.getTitle() />
				<cfset a_struct_return.name = a_arr_tmp[ 1 ].toString() />
						
			<cfelse>
				<cfset a_struct_return.name = a_v1_tag.getTitle().toString() />
			</cfif>
			
		<cfcatch type="any">
			<cfset a_struct_return.name = '' />
		</cfcatch></cftry>
		
		<cfif NOT StructKeyExists(a_struct_return, 'name')>
			<cfset a_struct_return.name = '' />
		</cfif>
	
		<cftry>
			<cfif IsArray( a_v1_tag.getYear() )>
				<cfset a_arr_tmp = a_v1_tag.getYear() />
				<cfset a_struct_return.year = a_arr_tmp[ 1 ].toString() />
						
			<cfelse>
				<cfset a_struct_return.year = a_v1_tag.getYear().toString() />
			</cfif>
		
		<cfcatch type="any">
			<cfset a_struct_return.year = '' />
		</cfcatch></cftry>
		
		<cfif NOT StructKeyExists(a_struct_return, 'year')>
			<cfset a_struct_return.year = '' />
		</cfif>
	
		<cftry>
			<cfif IsArray( a_v1_tag.getTrack() )>
				<cfset a_arr_tmp = a_v1_tag.getTrack() />
				<cfset a_struct_return.trackno = a_arr_tmp[ 1 ].toString() />
						
			<cfelse>
				<cfset a_struct_return.trackno = a_v1_tag.getTrack().toString() />
			</cfif>
		
		<cfcatch type="any">
			<cfset a_struct_return.trackno = '' />
		</cfcatch></cftry>
		
		<cfif NOT StructKeyExists(a_struct_return, 'trackno')>
			<cfset a_struct_return.trackno = '' />
		</cfif>
		
		<cftry>
			
			<cfif IsArray( a_v1_tag.getComment() )>
				<cfset a_arr_tmp = a_v1_tag.getComment() />
				<cfset a_struct_return.comment = a_arr_tmp[ 1 ].toString() />
						
			<cfelse>
				<cfset a_struct_return.comment = JavaCast( "string", a_v1_tag.getComment()).toString() />
			</cfif>
		
		<cfcatch type="any">
			<cfset a_struct_return.comment = '' />
		</cfcatch></cftry>
		
		<cfif NOT StructKeyExists(a_struct_return, 'comment')>
			<cfset a_struct_return.comment = '' />
		</cfif>
			
		<cfreturn a_struct_return />
			
	</cffunction>
   
</cfcomponent>