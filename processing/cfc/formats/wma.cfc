<!--- //

	Module:		Parse out mp3 tags
	Action:		
	Description:	
	
// --->

<cfcomponent displayName="wma" hint="Reads ID3 information from an WMA file" output="false">
	
	<cfinclude template="/inc/scripts.cfm">
	
	<cffunction access="public" name="init" returntype="any" output="false">
		<cfreturn this />
	</cffunction>

	<cffunction access="public" name="ParseWMAFile" output="false" returntype="struct"
			hint="return basic information about mp3">
		<cfargument name="filename" type="string" required="true"
			hint="filename">
			
		<cfset var stReturn = GenerateReturnStruct() />	
		<cfset var a_str_file_java = 0 />
		<cfset var a_read_file = 0 />
		<cfset var a = 0 />
		<cfset var a_str_key = '' />
		<!--- data --->
		<cfset var a_str_name = '' />
		<cfset var a_str_artist = '' />
		<cfset var a_str_album = '' />
		<cfset var a_str_genre = '' />
		<cfset var a_str_year = '' />
		<cfset var a_str_track = '' />
		<cfset var a_wma_info = '' />
		<cfset var a_parser = 0 />
		<cfset var a_tags = 0 />
		
		<!--- audio info --->
		<cfset var a_struct_file_info = 0 />
		
		<!--- create the very basic structure ... --->
		<cfset var a_struct_meta = ReturnBasicMediaMetaInformationStructure() />
		
		<!--- file not found? --->
		<cfif NOT FileExists( arguments.filename )>
			<cfreturn SetReturnStructErrorCode(stReturn, 4000) />
		</cfif>
		
		<cfset a_str_file_java = CreateObject("java","java.io.File").Init( arguments.filename ) />	
		<cfset a_parser = CreateObject('java', 'entagged.audioformats.AudioFileIO').init() />
		
		<!--- try to read the file --->
		<cftry>
			<cfset a_wma_info = a_parser.readFile( a_str_file_java ) />
			<cfset a_tags = a_wma_info.getTag() />
		<cfcatch type="any">
			
			<cfmail from="hansjoerg@tunesbag.com" to="hansjoerg@tunesbag.com" subject="exception" type="html">
			<cfdump var="#cfcatch#">
			</cfmail>
			
			<cfreturn SetReturnStructErrorCode(stReturn, 4101) />
		</cfcatch>
		</cftry>
		
		<!--- the bitrate --->
		<!--- <cfset a_struct_meta.bitrate = a_parser.getBitrate() /> --->
		<cfset a_struct_meta.bitrate = a_wma_info.getBitrate() />
		<cfset a_struct_meta.tracklength = a_wma_info.getLength() />
			
		<!--- only set the fixed string values, bitrate etc are calculated later on when
			we have a real MP3 --->
		<cfset a_struct_meta.album = a_tags.getFirstAlbum() />
		<cfset a_struct_meta.trackno = a_tags.getFirstTrack() />
		<cfset a_struct_meta.artist = a_tags.getFirstArtist() />
		<cfset a_struct_meta.name = a_tags.getFirstTitle() />
		<cfset a_struct_meta.year = a_tags.getFirstYear() />
		<cfset a_struct_meta.genre = a_tags.getFirstGenre() />
		<cfset a_struct_meta.comment = a_tags.getFirstComment() />
		
		<!--- return data --->
		<cfset stReturn.metainformation = a_struct_meta />
		
		<cfset a_str_file_java = 0 />
		
		<cfreturn SetReturnStructSuccessCode(stReturn) />
			
	</cffunction>

</cfcomponent>