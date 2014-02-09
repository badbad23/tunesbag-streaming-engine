<!--- consts --->

<!--- 
	consts
 --->

<cfif StructKeyExists( application, 'const' ) AND NOT StructKeyExists( url, 'reinit')>
	<cfexit method="exittemplate" />
</cfif>

<cflock type="exclusive" name="lock_init_consts" timeout="30">

<cfset application.const = {} />

<!--- supported file formats --->
<cfset application.const.L_SUPPORTED_FILE_FORMATS = 'mp3,wma,m4a,ogg,flac' />

<!--- audio formats --->
<cfset application.const.I_AUDIO_FORMAT_UNKNOWN = 0 />
<cfset application.const.I_AUDIO_FORMAT_MP3 = 1 />
<cfset application.const.I_AUDIO_FORMAT_WMA = 5 />

<cfset application.const.I_AUDIO_FORMAT_M4A = 10 />
<cfset application.const.I_AUDIO_FORMAT_AAC = 15 />

<!--- special formats --->
<cfset application.const.I_AUDIO_FORMAT_OGG = 20 />
<cfset application.const.I_AUDIO_FORMAT_SWF = 50 />
<cfset application.const.I_AUDIO_FORMAT_FLAC = 60 />

<!--- dropbox --->
<cfset application.const.I_DROPBOX_ITEM_FILE = 1 />
<cfset application.const.I_DROPBOX_ITEM_DIRECTORY = 2 />

<!--- errors --->
<cfset application.err.AUDIO_UNABLE_TO_PARSE_FILE = 4101 />

</cflock>