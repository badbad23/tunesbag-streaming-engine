<!---

	tools / helper component

--->

<cfcomponent output="false">
	
	<cfinclude template="/inc/scripts.cfm">
	
	<cfset variables.sPUIDLockFilename = '/tmp/puid.gen.job.running.lock' />
	
	<cffunction access="public" name="init" output="false" hint="constructor">
		<cfreturn this />
	</cffunction>
	
	<cffunction access="private" name="getPUIDLockFileName" output="false" returntype="string"
			hint="return the name of the lock file">
		<cfreturn variables.sPUIDLockFilename />
	</cffunction>
	
	<cffunction access="public" name="transmitQueueStatus" output="false" returntype="void"
			hint="post status about database back to master">
		
		<cfset var qSelectQueue = 0 />
		<cfset var stData = {} />
		<cfset var stTransmitData = {} />
		<cfset var sCol = '' />
		
		<cfquery name="qSelectQueue" datasource="tb_incoming">
		SELECT
			dt_created,
			entrykey,
			userkey,
			location,
			librarykey,
			handled,
			uploadrunkey,
			status
		FROM
			uploaded_items
		WHERE
			/* not finished */
			NOT (done = 1)
		;
		</cfquery>
		
		<cfloop query="qSelectQueue">
			<cfset stData[ qSelectQueue.currentrow ] = {} />
			
			<cfloop list="#qSelectQueue.columnlist#" index="sCol">
				<cfset stData[ qSelectQueue.currentrow ][ sCol ] = qSelectQueue[ sCol ][ qSelectQueue.currentrow ] />
			</cfloop>
			
		</cfloop>
		
		<cfset stTransmitData.sQueue = SerializeJSON( stData ) />
		
		<cfset application.beanFactory.getBean( 'Communication' ).TalkToMasterServer( type = 'slave.queuestatus', data = stTransmitData ) />
		
	</cffunction>
	
	<cffunction name="getFileHash" returntype="string" output="false" hint="Function to create an MD5 checksum of a binary Byte array similar to md5sum command on linux.  This is useful for creating md5 sums of jpg/png images for integrity verification" >
		<cfargument name="filename" type="string" required="true">
		<cfargument name="algorithm" type="string" required="false" default="SHA-1" hint="Any algorithm supported by java MessageDigest - eg: MD5, SHA-1,SHA-256, SHA-384, and SHA-512.  Reference: http://java.sun.com/javase/6/docs/technotes/guides/security/StandardNames.html##MessageDigest">
		<!--- <cfset var i = "">
		<cfset var checksumByteArray = "">
		<cfset var checksumHex = "">
		<cfset var hexCouplet = "">
		<cfset var myBinaryFile = 0 />
		<cfset var digester = createObject("java","java.security.MessageDigest").getInstance(arguments.algorithm) />
		<cfset var cffile = 0 />
		
		<cfif NOT FileExists( arguments.filename )>
			<cfreturn '' />
		</cfif>	
		
		<cffile result="cffile" action="readbinary" file="#arguments.filename#" variable="myBinaryFile">
		
		<cfset digester.update(myBinaryFile,0,len( myBinaryFile ))>
		<cfset checksumByteArray = digester.digest()>
		
		<!--- Convert byte array to hex values --->
		<cfloop from="1" to="#len(checksumByteArray)#" index="i">
			<cfset hexCouplet = formatBaseN(bitAND(checksumByteArray[i],255),16)>
			<!--- Pad with 0's --->
			<cfif len(hexCouplet) EQ 1>
				<cfset hexCouplet = "0#hexCouplet#">
			</cfif>
			<cfset checkSumHex = "#checkSumHex##hexCouplet#">
		</cfloop>
		<cfreturn lCase( checkSumHex ) /> --->
		
		<cfset var local = {} />
		<cfset var local.sCMD = 'openssl' />
		<cfset var local.sParams = 'dgst -sha1 "' & arguments.filename & '"' />
		
		<cfexecute name="openssl" arguments="#local.sParams#" variable="local.sOutput" timeout="30" />
		
		<!--- output: SHA1(/tmp/madonna.mp3)= 60a6487b96bd6598fdc0cb72c10ddbfd545e8516 --->
		<cfreturn Trim(ListLast( local.sOutput, '=' )) />
		
	</cffunction>

	<cffunction access="public" name="isPUIDJobRunning" output="false" returntype="boolean">
		
		<cfreturn FileExists( getPUIDLockFileName() ) />
	
	</cffunction>

	<cffunction access="public" name="calculatePUID" output="false" returntype="struct"
			hint="calculate the PUID for this MP3">
		<cfargument name="sMediaitemkey" type="string" required="true" />
		<cfargument name="sMP3Location" type="string" required="true"
			hint="full http location to MP3 (S3)" />
		
		<cfset var stReturn = GenerateReturnStruct() />
		<cfset var stLocal = {} />
		<cfset var stLocal.sMusicDNSKey = GetSettingsProperty( 'MusicDNSKey', '19d7d000d9798bc7d266f1a373a9617f' ) />
		
		<cfset stReturn.sGenPUIDPath = ExpandPath( '../bin/musicip/' ) />
		
		<cfif FindNoCase( 'Mac', server.OS.Name)>
			<cfset stReturn.sGenPUIDPath = stReturn.sGenPUIDPath & 'mac/genpuid' />
		<cfelse>
			<cfset stReturn.sGenPUIDPath = stReturn.sGenPUIDPath & 'linux/genpuid' />
		</cfif>
		

		<!--- use nice to reduce the CPU load --->
		<cfset stLocal.sLocalTempDirectory = GetTBTempDirectory() & 'puid-analyze/' />
		
		<cfif NOT DirectoryExists( stLocal.sLocalTempDirectory )>
			<cfdirectory action="create" directory="#stLocal.sLocalTempDirectory#" />
		</cfif>
		
		<cfset stLocal.sLocalMP3TempFile = stLocal.sLocalTempDirectory & arguments.sMediaitemkey & '-' & CreateUUID() & '.mp3' />
		
		<cfset stLocal.sXMLFile = stLocal.sLocalTempDirectory & 'musicip_analyze' & arguments.sMediaitemkey & '-' & createUUID() & '.xml' />
		
		<!--- <cfset stLocal.sExecute = stReturn.sGenPUIDPath & ' ' & stLocal.sMusicDNSKey & ' "' & arguments.sMP3File & '" -xml=' & stLocal.sXMLFile /> --->

<cfsavecontent variable="stLocal.sExecute">
<cfoutput>
##!/usr/bin/sh
touch #getPUIDLockFileName()#
wget --output-document=#stLocal.sLocalMP3TempFile# "#arguments.sMP3Location#" > /dev/null
nice -10 #stReturn.sGenPUIDPath# #stLocal.sMusicDNSKey# "#stLocal.sLocalMP3TempFile#" -xml=#stLocal.sXMLFile#
rm #stLocal.sLocalMP3TempFile#
rm #getPUIDLockFileName()#
</cfoutput>
</cfsavecontent>	

		<cfset stLocal.sExecuteFile = stLocal.sLocalTempDirectory & 'puid_execute_' & arguments.sMediaitemkey & '-' & createUUID() & '.sh' />
				
		<cffile action="write" file="#stLocal.sExecuteFile#" output="#Trim( stLocal.sExecute )#">

		<cfset stReturn.sExecuteFile = stLocal.sExecuteFile />
		

		<!--- call it now --->
		<cftry>
		<cfexecute name="sh" arguments=" #stLocal.sExecuteFile#" timeout="120" outputfile="/dev/null" />
			<cfcatch type="any">
				<cfreturn SetReturnStructErrorCode( stReturn, 500, 'Analyze problem with execute ' & stLocal.sExecuteFile & ' ' & cfcatch.Message ) />
			</cfcatch>
		</cftry>
		
		<!--- try to read XML file --->
		<cfif NOT FileExists( stLocal.sXMLFile )>
			<cfreturn SetReturnStructErrorCode( stReturn, 404, 'XML Result File not found: ' & stLocal.sXMLFile ) />
		</cfif>
		
		<cffile action="read" charset="utf-8" file="#stLocal.sXMLFile#" variable="stLocal.sXMLReport" />
		
		<cfif NOT IsXML( stLocal.sXMLReport )>
			<cfreturn SetReturnStructErrorCode( stReturn, 500, 'Invalid XML File: ' & stLocal.sXMLReport ) />
		</cfif>
		
		<cfset oXML = XMLParse( stLocal.sXMLReport ) />
		
		<cftry>
			<!--- <cfset stLocal.sStatus = oXML.genpuid.track.XMLAttributes.status /> --->
			<cfset stLocal.sPUID = oXML.genpuid.track.XMLAttributes.puid />
			<cfcatch type="any">
				<cfreturn SetReturnStructErrorCode( stReturn, 505, 'Invalid XML File: ' & stLocal.sXMLReport ) />
			</cfcatch>
		</cftry>
		
		<cfset stReturn.sPUID = stLocal.sPUID />
		
		<!--- clean up --->
		<cftry>
		<cffile action="delete" file="#stLocal.sExecuteFile#" />
		<cffile action="delete" file="#stLocal.sXMLFile#" />		
		<cfcatch type="any"></cfcatch>
		</cftry>
		
		<cfreturn SetReturnStructSuccessCode( stReturn ) />
	</cffunction>
	
</cfcomponent>