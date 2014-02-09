<!---

	OGG Parser
	
	Parse ogg file

--->


<cfcomponent displayName="ogg parser" hint="Reads ID3 information from an OGG file" output="false">
	
	<cfinclude template="/inc/scripts.cfm">
	
	<cffunction access="public" name="init" returntype="any" output="false">
		<cfreturn this />
	</cffunction>

	<cffunction access="public" name="ParseOGGFile" output="false" returntype="struct"
			hint="return basic information about mp3">
		<cfargument name="filename" type="string" required="true"
			hint="filename">
		
		<cfset var stReturn = GenerateReturnStruct() />	
		<cfset var a_parser = CreateObject('java', 'org.jaudiotagger.audio.ogg.OggFileReader').init() />
		<cfset var a_str_file_java = 0 />
		<cfset var a_read_file = 0 />
		<cfset var a_tag = 0 />
		<cfset var a_str_key = '' />
		<cfset var a_header = 0 />
		
		<!--- create the very basic structure ... --->
		<cfset var a_struct_meta = ReturnBasicMediaMetaInformationStructure() />
		
		<!--- file not found? --->
		<cfif NOT FileExists(arguments.filename)>
			<cfreturn SetReturnStructErrorCode(stReturn, 4000) />
		</cfif>
		
		<cfset a_str_file_java = CreateObject("java","java.io.File").Init( arguments.filename ) />	

		<cftry>
		<cfset a_read_file = a_parser.read( a_str_file_java ) />
		<cfcatch type="any">
			<cfreturn SetReturnStructErrorCode(stReturn, 4101, SerializeJSON( cfcatch )) />
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
		
		<cfset a_str_file_java = 0 />
		
		<cfset stReturn.metainformation = a_struct_meta />
		<cfreturn SetReturnStructSuccessCode(stReturn) />
		
		</cffunction>
		
</cfcomponent>