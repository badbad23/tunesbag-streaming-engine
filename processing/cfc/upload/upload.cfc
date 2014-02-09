<!--- 

	tunesBag Upload handling component

	handle various formats, organize the converting of files etc

 --->

<cfcomponent output="false" hint="general incoming routines">
	
	<cfinclude template="/inc/scripts.cfm">

	<cffunction access="public" name="init" returntype="processing.cfc.upload.upload" output="false">
		<cfreturn this />
	</cffunction>
	
	<cffunction access="public" name="GetItemByEntrykey" output="false" returntype="query">
		<cfargument name="sEntrykey" type="string" required="true" />
		
		<cfset var qSelect = 0 />
		
		<cfquery name="qSelect" datasource="tb_incoming">
		SELECT
			*
		FROM
			uploaded_items
		WHERE
			uploaded_items.entrykey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.sEntrykey#">
		;
		</cfquery>
		
		<cfreturn qSelect />
		
	</cffunction>
	
	<cffunction access="public" name="UpdateItemProperties" output="false" returntype="void">
		<cfargument name="sEntrykey" type="string" required="true" />
		<cfargument name="stUpdate" type="struct" default="#StructNew()#" />
		
		<cfset var qUpdate = 0 />
		<cfset var local = {} />
		
		<cfquery name="qUpdate" datasource="tb_incoming">
		UPDATE
			uploaded_items
		SET
		
			<cfif StructKeyExists( arguments.stUpdate, 'handleerrorcode' )>
				handleerrorcode = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.stUpdate.handleerrorcode#">,
			</cfif>
			<cfif StructKeyExists( arguments.stUpdate, 'status' )>
				status = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.stUpdate.status#">,
			</cfif>
			<cfif StructKeyExists( arguments.stUpdate, 'done' )>
				done = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.stUpdate.done#">,
			</cfif>
			<cfif StructKeyExists( arguments.stUpdate, 'convertjobkey' )>
				convertjobkey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.stUpdate.convertjobkey#">,
			</cfif>
			<cfif StructKeyExists( arguments.stUpdate, 'originalid3tags' )>
				originalid3tags = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#arguments.stUpdate.originalid3tags#">,
			</cfif>
			
			entrykey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.sEntrykey#">
			
		WHERE
			entrykey = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.sEntrykey#">
		;
		</cfquery>
	
	</cffunction>
	
	<cffunction access="public" name="HandleUploadedFile" output="false" returntype="struct"
			hint="check the uploaded file">
		<cfargument name="entrykey" type="string" required="true"
			hint="entrykey of item in the upload queue" />
		
		<cfset var stReturn = GenerateReturnStruct() />
		<cfset var sFilename_only = '' />
		<cfset var qItem = GetItemByEntrykey( arguments.entrykey ) />
		<cfset var sLibrary = qItem.librarykey />
		<cfset var sUserkey = qItem.userkey />
		<cfset var sFilenameMeta = qItem.location_metainfo />
		<cfset var bMetaInfoExists = FileExists( qItem.location_metainfo ) />
		<cfset var stMetaInfo = {} />
		<cfset var sMetaInfoContent = '' />
		<cfset var stResultAdd = {} />
		<cfset var sFormat = lCase( ListLast( qItem.location, '.' )) />
		<cfset var stParseMP3 = 0 />
		<cfset var stParseWMA = 0 />
		<cfset var stParseOGG = 0 />
		<cfset var stParseM4A = 0 />
		<cfset var sWDDXID3 = '' />
		<cfset var stCreateConvertJob = 0 />
		<cfset var bFileAlreadyExists = false />
		<cfset var stUpdateItem = {} />
		<cfset var stSubmitMetaDataToMaster = {} />
		<cfset var stStorageInfo = {} />
		<cfset var sArtworkfileContent = ''/>
		<cfset var stUploadStorageRequest = {} />
		<cfset var local = {} />
		
		<!--- run the PUID check ... it's a MP3 and we're OK! --->
		<cfset var oTools = application.beanFactory.getBean( 'Tools' ) />
		
		<!--- check the format --->
		<cfswitch expression="#sFormat#">
			<cfcase value="mp3">
				
				<!--- a MP3 file ... get bitrate ... too high, so is there a need to convert? --->
				<cfset stParseMP3 = application.beanFactory.getBean( 'MP3Reader' ).ParseMP3File( filename = qItem.location ) />
				
				<cfset stReturn.stParseMP3 = stParseMP3 />
				
				<cfif NOT stParseMP3.result>
					
					<!--- seems to be an invalid file --->					
					<cfset stUpdateItem = { handleerrorcode = 4101 } />
					
					<cfset UpdateItemProperties( sEntrykey = qItem.entrykey, stUpdate = stUpdateItem ) />
					<cfreturn SetReturnStructErrorCode( stReturn, 4101 ) />
					
				</cfif>
				
				<!--- in case bitrate is too high, reduce, otherwise apply MP3 gain on the file --->
				<cfif stParseMP3.metainformation.bitrate GT 320>
				
					<!--- we need to convert this one! --->
					<cfset stCreateConvertJob = application.beanFactory.getBean( 'AudioConverter' ).CreateConvertFileJob( 
										uploadkey = arguments.entrykey,
										operation = 1,
										userkey = qItem.userkey,
										source = qItem.location,
										id3tags = stParseMP3.metainformation ) />
										
					<!--- job creation failed --->
					<cfif NOT stCreateConvertJob.result>
						
						<cfset stUpdateItem = { handleerrorcode = 4101 } />
						<cfset UpdateItemProperties( sEntrykey = qItem.entrykey, stUpdate = stUpdateItem ) />
						
						<!--- invalid? --->
						<cfreturn stCreateConvertJob />
					</cfif>
					
					<!--- save the convert job ... store original ID3 tags for later use (we will apply them to the new file again) --->
					<cfwddx input="#stParseMP3.metainformation#" output="sWDDXID3" action="cfml2wddx">
			
					<cfset stUpdateItem = { originalid3tags = sWDDXID3, convertjobkey = stCreateConvertJob.jobkey, status = 1 } />
					<cfset UpdateItemProperties( sEntrykey = qItem.entrykey, stUpdate = stUpdateItem ) />
					
					<!--- return that we are preparing the file ... --->
					<cfreturn SetReturnStructErrorCode( stReturn, 4200 ) />
				
				<cfelseif qItem.audionormalizedone IS 0>
				
					<!--- apply mp3gain to file? ... TODO: lookup user preference on this one --->
					<cfset stCreateConvertJob = application.beanFactory.getBean( 'MP3Reader' ).ApplyMP3GainOnFile( source = qItem.location ) />
				
				</cfif>
				
				<!--- Perform PUID lookup using musicDNS --->
				<!--- <cftry>
					
					<!--- 
						try to lookup the PUID
						and set the result for our insert process
					 --->
					<cfset local.stPUID = oTools.calculatePUID( qItem.location ) />
					
					<cfif local.stPUID.result>
						
						<!--- yes, we've generated the PUID! --->
						<cfset stParseMP3.metainformation.puid_generated = 1 />
						
						<!--- set the PUID --->
						<cfset stParseMP3.metainformation.PUID = local.stPUID.sPUID />
					</cfif>
	
					<cfcatch type="any">
						<cfmail from="support@tunesBag.com" to="support@tunesBag.com" subject="error on executing GENPUID" type="html"><cfdump var="#arguments#"><cfdump var="#cfcatch#"><cfdump var="#local#"></cfmail>
					</cfcatch>
				</cftry> --->
				
				<cfset stMetaInfo = stParseMP3.metainformation />
			
			</cfcase>
			<cfcase value="m4a">
				
				<!--- a M4A file ... get bitrate ... too high, so is there a need to convert? --->
				<cfset a_struct_parse_m4a = application.beanFactory.getBean( 'M4AReader' ).ParseM4aFile( filename = qItem.location ) />
				
				<!--- invalid file ... --->
				<cfif NOT a_struct_parse_m4a.result>
					<cflog application="false" file="tb_m4a" text="could not parse file: #qItem.location#" log="Application" type="information">
					<cfreturn a_struct_parse_m4a />
				</cfif>
				
				<cfset stCreateConvertJob = application.beanFactory.getBean( 'AudioConverter' ).CreateConvertFileJob( operation = 2,
									uploadkey = arguments.entrykey,
									userkey = qItem.userkey,
									source = qItem.location,
									id3tags = a_struct_parse_m4a.metainformation ) />
				
				<!--- job creation failed --->
				<cfif NOT stCreateConvertJob.result>
					
					<cfset stUpdateItem = { handleerrorcode = 4101 } />
					<cfset UpdateItemProperties( sEntrykey = qItem.entrykey, stUpdate = stUpdateItem ) />
					
					<!--- invalid? --->
					<cfreturn stCreateConvertJob />
				</cfif>
				
				<!--- save the convert job ... store original ID3 tags for later use (we will apply them to the new file again) --->
				<cfwddx input="#a_struct_parse_m4a.metainformation#" output="sWDDXID3" action="cfml2wddx">
				
				<cfset stUpdateItem = { originalid3tags = sWDDXID3, convertjobkey = stCreateConvertJob.jobkey, status = 1 } />
				<cfset UpdateItemProperties( sEntrykey = qItem.entrykey, stUpdate = stUpdateItem ) />
				
				<!--- return that we are preparing the file ... --->
				<cfreturn SetReturnStructErrorCode( stReturn, 4200 ) />
				
			</cfcase>
			<cfcase value="wma">
			
				<!--- file need to be converted --->
				<!--- a WMA file ... get bitrate ... too high, so is there a need to convert? --->
				<cfset a_struct_parse_wma = application.beanFactory.getBean( 'WMAReader' ).ParseWMAFile( filename = qItem.location ) />
			
				<!--- invalid file ... --->
				<cfif NOT a_struct_parse_wma.result>
					<cfreturn a_struct_parse_wma />
				</cfif>
				
				<!--- 3 = wma2mp3 --->
				<cfset stCreateConvertJob = application.beanFactory.getBean( 'AudioConverter' ).CreateConvertFileJob( operation = 3,
											uploadkey = arguments.entrykey,
											userkey = qItem.userkey,
											source = qItem.location,
											id3tags = a_struct_parse_wma.metainformation ) />		
				<!--- job creation failed --->
				<cfif NOT stCreateConvertJob.result>
					
					<cfset stUpdateItem = { handleerrorcode = 4101 } />
					<cfset UpdateItemProperties( sEntrykey = qItem.entrykey, stUpdate = stUpdateItem ) />
					
					<!--- invalid? --->
					<cfreturn stCreateConvertJob />
				</cfif>
				
				<!--- save the convert job ... store original ID3 tags for later use (we will apply them to the new file again) --->
				<cfwddx input="#a_struct_parse_wma.metainformation#" output="sWDDXID3" action="cfml2wddx">
				
				<cfset stUpdateItem = { originalid3tags = sWDDXID3, convertjobkey = stCreateConvertJob.jobkey, status = 1 } />
				<cfset UpdateItemProperties( sEntrykey = qItem.entrykey, stUpdate = stUpdateItem ) />
				
				<!--- return that we are preparing the file ... --->
				<cfreturn SetReturnStructErrorCode( stReturn, 4200 ) />
				
			</cfcase>
			<cfcase value="ogg">
				
				<!--- ogg vorbis --->
				<!--- a WMA file ... get bitrate ... too high, so is there a need to convert? --->
				<cfset a_struct_parse_ogg = application.beanFactory.getBean( 'OGGReader' ).ParseOGGFile( filename = qItem.location ) />
				
				<!--- invalid file ... --->
				<cfif NOT a_struct_parse_ogg.result>
					<cfreturn a_struct_parse_ogg />
				</cfif>
				
				<!--- 4 = OGG2MP3 --->
				<cfset stCreateConvertJob = application.beanFactory.getBean( 'AudioConverter' ).CreateConvertFileJob( operation = 4,
											uploadkey = arguments.entrykey,
											userkey = qItem.userkey,
											source = qItem.location,
											id3tags = a_struct_parse_ogg.metainformation ) />	
													
				<!--- job creation failed --->
				<cfif NOT stCreateConvertJob.result>
					
					<cfset stUpdateItem = { handleerrorcode = 4101 } />
					<cfset UpdateItemProperties( sEntrykey = qItem.entrykey, stUpdate = stUpdateItem ) />
					
					<!--- invalid? --->
					<cfreturn stCreateConvertJob />
				</cfif>
				
				<!--- save the convert job ... store original ID3 tags for later use (we will apply them to the new file again) --->
				<cfwddx input="#a_struct_parse_ogg.metainformation#" output="sWDDXID3" action="cfml2wddx">
				
				<cfset stUpdateItem = { originalid3tags = sWDDXID3, convertjobkey = stCreateConvertJob.jobkey, status = 1 } />
				<cfset UpdateItemProperties( sEntrykey = qItem.entrykey, stUpdate = stUpdateItem ) />
				
				<!--- return that we are preparing the file ... --->
				<cfreturn SetReturnStructErrorCode( stReturn, 4200 ) />
			
			</cfcase>
		</cfswitch>

		<!--- meta information provided .. get serveral additional iTunes properties --->
		<cfif bMetaInfoExists>
		
			<cffile action="read" charset="utf-8" file="#qItem.location_metainfo#" variable="sMetaInfoContent" />
			
			<!--- parse the additional meta data --->
			<cfif IsXML( sMetaInfoContent )>
			
				<cfset local.stAdditionalMetaData = GenericMetaInfoXMLToStruct( sMetaInfoContent ) />
				
				<!--- check for certain fields to add to our main structure --->
				
				<!--- // rating // --->
				<cfif StructKeyExists( local.stAdditionalMetaData, 'rating' ) >
					<cfset stMetaInfo.rating = local.stAdditionalMetaData.rating />
				</cfif>
				
				<!--- // iTunesPersistentID // --->
				<cfif StructKeyExists( local.stAdditionalMetaData, 'iTunesPersistentID' ) >
					<cfset stMetaInfo.iTunesPersistentID = local.stAdditionalMetaData.iTunesPersistentID />
				</cfif>
				
				<!--- // iTunesTrackID // --->
				<cfif StructKeyExists( local.stAdditionalMetaData, 'iTunesTrackID' ) >
					<cfset stMetaInfo.iTunesTrackID = local.stAdditionalMetaData.iTunesTrackID />
				</cfif>
				
				<!--- // LastPlayed // --->
				<cfif StructKeyExists( local.stAdditionalMetaData, 'LastPlayed' ) >
					<cfset stMetaInfo.LastPlayed = local.stAdditionalMetaData.LastPlayed />
				</cfif>
				
				<!--- // PlayedTimes // --->
				<cfif StructKeyExists( local.stAdditionalMetaData, 'PlayedTimes' ) >
					<cfset stMetaInfo.PlayedTimes = local.stAdditionalMetaData.PlayedTimes />
				</cfif>
			
			</cfif>
			
		</cfif>
		
		<!--- store tag information as well ... --->
		<cfwddx input="#stMetaInfo#" output="sWDDXID3" action="cfml2wddx">
		
		<!--- finalizing this item now (storing ...) --->
		<cfset stUpdateItem = { status = 2, originalid3tags = sWDDXID3 } />
		<cfset UpdateItemProperties( sEntrykey = qItem.entrykey, stUpdate = stUpdateItem ) />
		
		<!--- check for artwork ... submit base64 version --->
				
		<!--- insert into S3 upload queue --->		
		<cfset InsertIntoS3UploadQueue( uploadkey = qItem.entrykey,
							filelocation = qItem.location ) />
			
		<!--- success --->
		<cfreturn SetReturnStructSuccessCode( stReturn ) />
	
	</cffunction>
	
	<cffunction access="public" name="InsertIntoS3UploadQueue" returntype="void" output="false"
			hint="Insert into upload queue">
		<cfargument name="uploadkey" type="string" required="true"
			hint="entrykey of upload job" />
		<cfargument name="filelocation" type="string" required="true" />
		
		<cfquery name="qInsertUploadQueue" datasource="tb_incoming">
		INSERT INTO
			s3uploadqueue
			(
			uploadkey,
			filelocation,
			dt_created,
			s3uploadinfo
			)
		VALUES
			(
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.uploadkey#">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.filelocation#">,
			<cfqueryparam cfsqltype="cf_sql_timestamp" value="#Now()#">,
			''
			)
		;
		</cfquery>
	
	</cffunction>
	
	<cffunction access="private" name="GenericMetaInfoXMLToStruct" returntype="struct" output="false"
			hint="convert the generic XML to struct ... this generic XML is uploaded by the tunesBag uploading application">
		<cfargument name="content" type="string" required="true"
			hint="raw xml content (string)">
			
		<cfset var stReturn = StructNew() />
		<cfset var a_xml_obj = XmlParse(arguments.content) />
		<cfset var a_xml_data = XMLSearch(a_xml_obj, '//data/') />
		<cfset var ii = 0 />
		
		<cfset a_xml_data = a_xml_data[1].xmlchildren />
				
		<cfloop from="1" to="#ArrayLen(a_xml_data)#" index="ii">
			<cfset stReturn[a_xml_data[ii].xmlname]  = a_xml_data[ii].xmltext />
		</cfloop>
		
		<cfreturn stReturn />
	</cffunction>
	
</cfcomponent>