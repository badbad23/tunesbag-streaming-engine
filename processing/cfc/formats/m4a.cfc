<!--- //

	Module:		Parse out m4a tags
	Action:		
	Description:	
	
// --->

<cfcomponent displayName="MP4 Parser" hint="Reads ID3 information from an M4A" output="false">
	
	<cfinclude template="/inc/scripts.cfm">
	
	<cffunction access="public" name="init" returntype="any" output="false">
		<cfreturn this />
	</cffunction>
	
	
	<cffunction access="public" name="ParseM4AFile" output="false" returntype="struct"
			hint="return basic information about mp3">
		<cfargument name="filename" type="string" required="true"
			hint="filename">
		
		<cfset var stReturn = GenerateReturnStruct() />	
		<cfset var a_parser = CreateObject('java', 'org.jaudiotagger.audio.mp4.Mp4FileReader').init() />
		<cfset var a_str_file_java = 0 />
		<cfset var a_read_file = 0 />
		<cfset var a_tag = 0 />
		<cfset var a_str_key = '' />
		<cfset var a_header = 0 />
		<cfset var local = {} />
		<cfset var a_bin_artwork = 0 />
		<cfset var a_str_artwork_filename = GetTBTempDirectory() & 'artwork_' & createUUID() & '.jpg' />
		
		<!--- create the very basic structure ... --->
		<cfset var a_struct_meta = ReturnBasicMediaMetaInformationStructure() />
		
		<cfif NOT DirectoryExists( GetDirectoryFromPath( a_str_artwork_filename ))>
			<cfdirectory action="create" directory="#GetDirectoryFromPath( a_str_artwork_filename )#">
		</cfif>		
		
		<!--- file not found? --->
		<cfif NOT FileExists(arguments.filename)>
			<cfreturn SetReturnStructErrorCode(stReturn, 4000) />
		</cfif>
		
		<cfset a_str_file_java = CreateObject("java","java.io.File").Init( arguments.filename ) />	

		<cftry>
		<cfset a_read_file = a_parser.read( a_str_file_java ) />
		<cfcatch type="any">
			<cfreturn SetReturnStructErrorCode(stReturn, 4101) />
		</cfcatch>
		</cftry>
	
		<!--- set data --->
		<cftry>
		<cfset a_tag = a_read_file.getTag() />
		<cfset a_struct_meta.artist = a_Tag.getFirstArtist() /> 
		<cfset a_struct_meta.album = a_Tag.getFirstAlbum() /> 
		<cfset a_struct_meta.comment = a_Tag.getFirstComment() /> 		
		<cfset a_struct_meta.genre = a_Tag.getFirstGenre() /> 		
		<cfset a_struct_meta.name = a_Tag.getFirstTitle() /> 		
		<cfset a_struct_meta.trackno = a_Tag.getFirstTrack() />
		<cfset a_struct_meta.year = Left( a_Tag.getFirstYear(), 4) />
		<cfcatch>
			<!--- do nothing here --->
		</cfcatch>
		</cftry>
		
		<!--- audio info --->		
		<cfset a_struct_meta.size = a_str_file_java.length() />
		
		<cfset a_header = a_read_file.getAudioHeader() />
		<cfset a_struct_meta.bitrate = a_header.getBitRateAsNumber() />
		<cfset a_struct_meta.format = a_header.getFormat() />
		<cfset a_struct_meta.tracklength = a_header.getTrackLength() />
		<cfset a_struct_meta.samplerate = a_header.getSampleRateAsNumber() />
		
		<cftry>
			<cfset a_bin_artwork = a_tag.getFirstArtwork().getBinaryData() />

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
			
			
			
			
			<!--- return saved temp file --->
			<cfset a_struct_meta.artworkFilename = a_str_artwork_filename />
			
			<!--- save as string --->
			<cfset a_struct_meta.artworkfilecontent = ToBase64( a_bin_artwork ) />
		<cfcatch type="any">
			
		</cfcatch>
		</cftry>
		
		<cfset a_str_file_java = 0 />
		
		<cfset stReturn.metainformation = a_struct_meta />
		<cfreturn SetReturnStructSuccessCode(stReturn) />
		
		</cffunction>
	
</cfcomponent>