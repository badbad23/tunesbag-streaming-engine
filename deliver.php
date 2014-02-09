<?php
	
// media delivery process - including re-encoding with a lower bitrate etc
// 
// we have a request key from the tunesBag.com server
//
// - query the tunesBag.com server for details with this key
// - parse incoming JSON data
// - deliver cached file or generate new one on the fly
// - usually by using wget to get file from S3, ffmpeg to convert and re-encode
// - store file when converter has finished in cache
// - notify tunesBag.com server when operation has been finished (for stats) - include log output
	
// set some PHP internals
set_time_limit( 30 );
ignore_user_abort( TRUE ); 
	
// the application key of the streaming engine
$appkey = 'FF0D5A94-F8D9-60D4-4572A1A21EFEE8DD';
	
// the given request key
// used for the background check of this request
$jobkey = $_GET['jobkey'];
	
// mediaitem key
$mediaitemkey = $_GET['mediaitemkey'];
	
if (($jobkey == "") || ($mediaitemkey == "")) {
	die ("unknown request");
	exit;
	}
	
// item delivery script
// are we using the stage server?
$stage = $_GET['stage'] ;	
	
// stage server?
if ($stage == "1") {
	// local dev server
	$server = 'http://tunesbagdev/';
	$basepath = '/tmp/';
	} elseif ($stage == "2") {
	    // stage.tunesbag.com
		$server = 'http://stage.tunesBag.com/';
		$basepath = '/mnt/tunesbag/';
		}
		  else {
			// live server
			$server = 'http://www.tunesBag.com/';
			$basepath = '/mnt/tunesbag/';
			}
	
// create needed directories of they do not exist ...
makeDirectory( $basepath . 'logging' );
makeDirectory( $basepath . 'cache' );
makeDirectory( $basepath . 'temp' );
makeDirectory( $basepath . 'download' );

// ask server for further instructions for this request
$url = $server . "/api/rest/internal/streaming/getconvertdata/?format=json&appkey=" . $appkey . "&jobkey=" . urlencode( $jobkey ) . "&mediaitemkey=" . urlencode( $mediaitemkey ) . "&hostname=" . urlencode( $_SERVER[ 'server_name' ] ) . '&ip=' . $_SERVER[ 'REMOTE_ADDR' ] . '&rand=' . uuid();
	
// get meta information
$fp = fopen($url, "r") or die ("Error while receiving details.");
while ($line = fgets($fp, 1024))  { 
  $meta.=$line; 
 }
fclose($fp);
	
$obj = json_decode( $meta );
		
// the result
$meta_result = $obj->{ 'RESULT' };
$meta_error = $obj->{ 'ERROR' };
$meta_errormessage = $obj->{ 'ERRORMESSAGE' };	
	
if ($meta_result != 1) {
	die ("access forbidden, error #" . $meta_error . " (" . $meta_errormessage . ")" );
	exit;
	}

// where to get the data from?
$source = $obj->{ 'SOURCE' };

// what's the source format?
$source_format_id = $obj->{ 'SRCFORMAT_ID' };

// define the format used in ffmpeg
switch ($source_format_id) {
    case 10:
        $source_format = "m4a";
        break;
    case 1:
        $source_format = "mp3";
        break;
    case 4:
        $source_format = "wma";
        break;
    case 20:
        $source_format = "ogg";
        break;
    case 50:
        $source_format = "swf";
        break;
    case 60:
        $source_format = "flac";
        break;        
    case 2:
        $source_format = "mp3";
        break;
    default:
}

// desired bitrate
$bitrate = $obj->{ 'BITRATE' };

// desired format	
$format = $obj->{ 'FORMAT' };	
	
// seconds to convert
$seconds = $obj->{ 'SECONDS' };
	
if ($seconds == '') {
	$seconds = 0;
	}

// valid address
$address = $obj->{ 'ADDRESS' };
	
/*if ($_SERVER['REMOTE_ADDR'] != $address) {
	die ("access forbidden; please use the appropriate player");	
	exit;
	}*/
	
$descriptorspec = array(
   0 => array("pipe", "r"),  // stdin is a pipe that the child will read from
   1 => array("pipe", "w"),  // stdout is a pipe that the child will write to
   2 => array("file", "/tmp/error-output" . $jobkey . ".txt", "a") // stderr is a file to write to
);
	
// set the content type of the output file
if ($format == 'mp3') {
	$contenttype = 'audio/mpeg';
	}
	
// aac++ = using aacplusenc
if ($format == 'aac') {
	$contenttype = 'audio/aac';
	// $contenttype = 'text/plain';
	}

// does a cached version already exist? serve this one ...
$cached_version_filename = $basepath . 'cache/' . $mediaitemkey . '-' . $bitrate . '-' . $seconds . '.' .$format;
$temp_record_filename = $basepath . 'temp/' . $mediaitemkey . '-' . uuid() . '-' . $bitrate . '-' . $seconds . '.' . $format;
$download_filename = $basepath . 'download/' . $mediaitemkey . '-' . uuid() . '-' . $bitrate . '-' . $seconds . '.' . $source_format;
	
// file exists but has zero length
if (file_exists( $cached_version_filename ) == true) {
	if (filesize( $cached_version_filename ) == 0) {
		unlink( $cached_version_filename );
		}
	}

// deliver the cached version
if (file_exists( $cached_version_filename ) == true) {
	
	if ($cached_version_file = fopen($cached_version_filename, 'rb')) {
		// submit stat back to server
		submitStatBackToServer( $server, $appkey, $jobkey, 1 );
		
		// deliver file
		header("Delivered-from-cache: true");
		fpassthru($cached_version_file);
		fclose($cached_version_file);
		
		exit;
		}
	}
	
// continue with on the fly convert ...
$cwd = '/tmp';
$env = array('some_option' => 'aeiou');
	
// define the logfile
$logfile_ffmpeg = $basepath . 'logging/ffmpeg_' . $jobkey . '.log';
		
// cut certain seconds out?
if ($seconds > 0) {
	$cut_seconds = ' -ss 15 -t ' . $seconds;	
	} else {
		$cut_seconds = '';
		}
	
// destination format MP3: get file / convert
if ($format == 'mp3') {

	// what's the source format?
	// 
	
	switch ($source_format_id) {
    	case 10:
		
// TODO handle using FIFO and MPLAYER
// mkfifo p
// wget http://stage.tunesBag.com/tests/test.m4a --quiet -O - 2>/dev/null | mplayer -  -cache 8192 -vo null -vc dummy -ao pcm:nowaveheader -ao pcm:fast:file=p
// ffmpeg -acodec pcm_s16le -i p -f mp3 -ab 128k -y test.mp3

			// download m4a file
			$fp = fopen ( $download_filename, 'w+' );//This is the file where we save the information
			$ch = curl_init( $source );//Here is the file we are downloading
			curl_setopt($ch, CURLOPT_TIMEOUT, 50);
			curl_setopt($ch, CURLOPT_FILE, $fp);
			curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
			curl_exec($ch);
			curl_close($ch);
			fclose($fp);
			
			// read from the file just downloaded
			$ffmpeg_input = $download_filename;
			
			// no wget needed
			$readSrcWget = '';
			
			break;
		default:
			// mp3
			
			// read from STDIN
			$ffmpeg_input = "-";
			// wget source
			$readSrcWget = 'wget "' . $source . '" --quiet -O - 2>/dev/null | ';
		}
	
	
	if ($seconds > 0) {
		// add fading
		// read from source, convert to wav, add fading, output as desired
	
	    if ($stage == "1") {
	       $fadesox = '';
	       } else {
	          $fadesox = 'sox -t wav - -t wav - fade t 3 ' . $seconds . ' 3 | ';
	          }
	
		$command = $readSrcWget . 'ffmpeg -y -f ' . $source_format . ' -i ' . $ffmpeg_input . $cut_seconds . ' -f wav - | ' . $fadesox . ' ffmpeg -y -f wav -i - -ab ' . $bitrate . 'k -f ' . $format . ' -';
		} else
		{
			// default
			$command = $readSrcWget . 'ffmpeg -y -f ' . $source_format . ' -i ' . $ffmpeg_input . $cut_seconds . ' -ar 44100 -ab ' . $bitrate . 'k -f ' . $format . ' - 2>' . $logfile_ffmpeg;
		}
	}
	
	
// AAC: get file / convert to wav / encode as aac
if ($format == 'aac') {
	$command = 'wget "' . $source . '" --quiet -O - 2>/dev/null | ffmpeg -y -f mp3 -i - ' . $cut_seconds . ' -ar 44100 -f wav - | sox -t wav - -t wav - | aacplusenc - - '. $bitrate;

	// print( $command );
	// die();
	}
	


// disable caching, send out the headers
header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");
header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
header("Cache-Control: no-store, no-cache, must-revalidate");      // HTTP/1.1
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");                                      // HTTP/1.0
header("Server: Apache / tunesBag Streaming Engine 0.2");
header("Content-type: " . $contenttype );
	
// store command file
$fp = fopen("/tmp/exec-" . $jobkey . '.sh-cmd' ,"w");
fwrite($fp,$command);
fclose($fp);
		
// open temp file
$temp_recordcing_file = fopen($temp_record_filename, 'w') or die("can't open file");

// launch process
$process = proc_open( $command, $descriptorspec, $pipes, $cwd, $env);
	
$process_return = -1;
	
// check if the process has been launched successfully
if (is_resource($process)) {
    // $pipes now looks like this:
    // 0 => writeable handle connected to child stdin
    // 1 => readable handle connected to child stdout
    // Any error output will be appended to /tmp/error-output.txt

	// read return data
	while ($line = fgets($pipes[1], 1024))
		{
		print $line;

		// no flushing needed
		// ob_flush();
		// flush();
		if ($format == 'aac') {
			flush();
			}
		
		// write to recording file
		fwrite($temp_recordcing_file, $line);
		
		// are we still connected?
		if (connection_aborted()){
		
			// close temp recording file
			fclose($temp_recordcing_file);
			
			$process_return = proc_close($process);
			
			// delete temp file
			unlink( $temp_recordcing_file );
			
    		die;
    		}
		}

	// close temp recording file
	fclose($temp_recordcing_file);

	// move converted file to new location for caching
	rename( $temp_record_filename, $cached_version_filename );

    // It is important that you close any pipes before calling
    // proc_close in order to avoid a deadlock
    $process_return = proc_close($process);

	// TODO: notify tunesBag.com server about this process
	


} else {
	die ("an error occured. Please notify the webmaster");
	}


// helper function ... create a directory
function makeDirectory( $dirPath ){
        if( !is_dir( $dirPath ) ){
            if ( mkdir( $dirPath ) ){
                return true;
            }else{
               return false;
            }
        }
    }


/*$data = "pid=14&poll_vote_number=2";
$x = PostToHost(
              $server,
              $server ."/tests/post.cfm",
              $data);
exit;*/

// submit stat back to server
function submitStatBackToServer( $server, $appkey, $jobkey, $readfromcache ) {

	$url = $server . "/api/rest/internal/streaming/submitstat/?format=json&appkey=" . $appkey . "&jobkey=" . urlencode( $jobkey ) . "&readfromcache=" . $readfromcache;
	
	// get meta information
	$fp = fopen($url, "r") or die ("Error while receiving details.");
	fclose($fp);
	}

// post data
function PostToHost($host, $path, $data_to_send) {
  $fp = fsockopen($host, 80);
  printf("Open!\n");
  fputs($fp, "POST $path HTTP/1.1\r\n");
  fputs($fp, "Host: $host\r\n");
  fputs($fp, "Content-type: application/x-www-form-urlencoded\r\n");
  fputs($fp, "Content-length: ". strlen($data_to_send) ."\r\n");
  fputs($fp, "Connection: close\r\n\r\n");
  fputs($fp, $data_to_send);
  printf("Sent!\n");
  while(!feof($fp)) {
      $res .= fgets($fp, 128);
  }
  fclose($fp);
 
  return $res;
}


// generate an uuid
function uuid($length=32) {
	mt_srand((double)microtime()*1000000);
    $r = strtoupper(md5(time().$_SERVER["REMOTE_ADDR"].$_SERVER["UNIQUE_ID"].mt_rand(0,9999)));
    if ($length<32){ $r=substr($r,0,$length-1); }
    return $r;
    }

?>