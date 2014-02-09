<!--- 

	helper scripts library

 --->

<cfscript>
// function for creating the default return structure
function GenerateReturnStruct() {
	var s = StructNew();
	
	s.result = false;
	s.error = 0;
	s.errormessage = '';
	
	return s;
	}
	
// this directory is used for uploads and so on
function GetTBTempDirectory() {
	return GetSettingsProperty( 'TempDirectory' , '/var/tb_temp/' );
	}
	
// return the master server for the communication of this remote server
function GetMasterServer() {
	return GetSettingsProperty( 'RemoteMasterServer', 'http://tunesBag.com/' );
	}
	
// return the used temp directory
// this directory is used for uploads and so on
function GetIncomingDirectory() {
	return GetSettingsProperty( 'IncomingDirectory' , '/var/tb_temp/incoming/' );
	}
	
// get the path to the java binary
function GetJavaPath() {
	return GetSettingsProperty( 'java' , 'java' );
	}
	
	
// set the error code ...
function SetReturnStructErrorCode(struct, code) {
	var a_struct_return = struct;
	
	if (ArrayLen(arguments) GT 2) {
		a_struct_return.errormessage = arguments[3];
		}
	a_struct_return.error = code;
	a_struct_return.result = false;
	return a_struct_return;
	}
	
// set OK answer
function SetReturnStructSuccessCode(struct) {
	var a_struct_return = struct;
	a_struct_return.error = 0;
	a_struct_return.result = true;
	a_struct_return.errormessage = '';
	return a_struct_return;
	}
	
// @@ read a certain general setting
function GetSettingsProperty(name, defaultvalue) {
	var a_str_filename = '/etc/tunesbag/site.properties';
	var a_str_returnvalue = defaultvalue;
	var a_str_read_ini = '';
	var a_bol_custom_properties_file_exists = (Len( cgi.custom_tunesbag_properties ) GT 0) AND (FileExists( cgi.custom_tunesbag_properties ));

	// default filename = /etc/tunesbag/site.properties
	// if cgi.custom_tunesbag_properties exist, use this file
	
	if (a_bol_custom_properties_file_exists) {a_str_filename = cgi.custom_tunesbag_properties;}
	
	a_str_returnvalue = GetProfileString(a_str_filename, 'main', name);
	
	if (Len( a_str_returnvalue ) IS 0) {
		return defaultvalue;
		} else return a_str_returnvalue;
	}
	
/**
 * This function will return the length of a file or a directory.
 * Version 2 by Nathan Dintenfass
 * Version 3 by Nat Papovich
 * 
 * @param filename 	 The filename or directory path. (Required)
 * @return Returns a number. 
 * @author Jesse Houwing (j.houwing@student.utwente.nl) 
 * @version 3, July 11, 2006 
 */
function fileSize(pathToFile) {
	var fileInstance = createObject("java","java.io.File").init(toString(arguments.pathToFile));
	var fileList = "";
	var ii = 0;
	var totalSize = 0;

	//if this is a simple file, just return it's length
	if(fileInstance.isFile()){
	    return fileInstance.length();
	}
	else if(fileInstance.isDirectory()) {
		fileList = fileInstance.listFiles();
		for(ii = 1; ii LTE arrayLen(fileList); ii = ii + 1){
		    totalSize = totalSize + fileSize(fileList[ii]);
		}
		return totalSize; 
	}
	else
		return 0;
}

// return the basic structure holding all meta properties of a media file
function ReturnBasicMediaMetaInformationStructure() {
	var a_struct_return = StructNew();
	a_struct_return.artist = '';
	a_struct_return.name = '';
	a_struct_return.genre = '';
	a_struct_return.album = '';
	a_struct_return.year = '';
	a_struct_return.comment = '';
	a_struct_return.track = '';
	a_struct_return.size = 0;
	a_struct_return.lyrics = '';
	a_struct_return.bitrate = 0;
	a_struct_return.samplerate = 0;
	a_struct_return.tracklength = 0;
	a_struct_return.format = '';
	a_struct_return.rating = '';
	return a_struct_return;
	}
	
// get the full URI to the current server
function getCurrentServerURI() {
	return 'http://' & cgi.server_name & ':' & cgi.server_port & '/';
	}
	
</cfscript>