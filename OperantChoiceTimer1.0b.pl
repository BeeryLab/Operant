#!/usr/bin/env perl
#This program times the interval between key presses

use strict; 	 # be fussy about variables
use Fcntl; 		 # for sysopen
use Time::HiRes; # for sub-second time resolution

## Todo: multiplier to get scale right, pass file handle instead of leaving name global


my $BSD_STYLE;
my $file_name;  #not really used, since file handle is Global, OMG ponies!!!
my $key='z';	#key pressed by scorer
my $sec; my $min; my $hour;
my $state = '2';
my $start_time;	
my $started = 0;	
my $firstframe;
my $time_on;
my $time_off;		
my $time_paused;	
my $durations = [0,0,0,0,0];
my $iterations = [0,0,0,0,0];
my $left = '';
my $right = '';




drawTitle();				# Intro screen

($firstframe, $left, $right) = createFile();	# Creates file, gets test info, and returns first scored frame (user entered)

drawInstructions ($firstframe,$started);		# how to score -- 0 means not started yet.


# This somehow allows the getc function to not wait for the return (ever)
if ($BSD_STYLE) {
	system "stty cbreak </dev/tty >/dev/tty 2>&1";
   }
   else {
	system "stty", '-icanon', 'eol', "\001";
   }


$key = getc(STDIN);								# Listen for a key press, and begin timing once it is a 'space'
until ($key =~ ' ') {
	print "Press <SPACEBAR> to begin recording \n";
	$key = getc(STDIN);	
	}
$time_on = [Time::HiRes::gettimeofday( )];		#Official start time at high resolution
$started = 1;

drawInstructions ($firstframe,$started);		# reprint how to score -- 1 means started, so display start time.

$key = 'z'; 									# just setting to something other than space, which it was

until ($key =~ ' ') {
	print drawState($state),"\r";
	$key = getc(STDIN);
	if ($key =~ ',') {				# move one state left unless already at 0
		unless ($state == 0) {
			$time_on = recordState($state, $time_on, $durations, $iterations);  # records duration in $state before it is changed
			$state = $state - 1;
		}
	}
	if ($key =~ 'p') {
		$time_paused = recordState($state, $time_on, $durations, $iterations);
		#don't change state, since will resume in same position.  Can tell paused because of "p" typed on screen
		#time_paused isn't used for anything, it's just named a different thing because it's not the time_on of any state.
		
		#wait until unpaused
		until ($key = getc(STDIN) =~ 'p') {
			#do nothing -- just waiting to be unpaused
		};
		
		#Unpaused now, so record new timestamp as $time_on.  This will start the timing running again until the next state change.
		$time_on = [Time::HiRes::gettimeofday( )];
		
	}
	elsif ($key =~ '\.') {			# move one state right unless already at 4
		unless ($state == 4) {
			$time_on = recordState($state, $time_on, $durations, $iterations);
			$state = $state + 1;
		}
	}
#	else {							# Do nothing for other key presses
#		#print "Invalid key -- use \',\' and \'.\' to move between states\n";  
#	}
}

# space has been pressed.  Record final state, summarize results, then exit.	
$time_on = recordState($state, $time_on, $durations, $iterations);
summarizeData($durations, $iterations, $left, $right);

close (OUTPUT);    #google perl input echo to turn off when using arrow keys



######################### Subroutines #############################################:

#----------------------------------------------------------------------------------
# string createFile()
#   Gets test info and creates data file.  Returns name of created file.
#----------------------------------------------------------------------------------

sub createFile()
{
	my $test_id = 'unknown';
	my $test_date = 'unspecified';
	my $left = 0;
	my $right = 0;
	my $playspeed = 1;
	my $firstframe = '';
	my $filetype = '';
	
	print "Please enter the following information for this behavioral test\n";
	print "Test ID: ";
	chomp($test_id = <STDIN>);
	
	sysopen (OUTPUT, "TID$test_id.txt", O_WRONLY|O_EXCL|O_CREAT) || die ('Cannot write file : ' . $!); 
	
	print "\nTest date (MM/DD/YY): ";
	chomp($test_date = <STDIN>);
	print "\nNumber of left vole (tethered): ";
	chomp($left = <STDIN>);
	print "\nNumber of right vole (tethered): ";
	chomp($right = <STDIN>);
	print "\nPlayback speed (suggest 4x-8x): ";
	chomp($playspeed = <STDIN>);
	print "\nVideo file type (eg: dvd (video), .mov, .mpeg, .mp3): ";
	chomp($filetype = <STDIN>);
#	print "\nFirst frame you are scoring (timestamp on video) if available: ";
#	chomp($firstframe = <STDIN>);
	
	printf OUTPUT "Test ID: $test_id   Test Date: $test_date   Left vole: $left   Right vole: $right\n";
	printf OUTPUT "Video source: $filetype, playback speed: $playspeed\n\n";
	printf OUTPUT "RAW DATA:\n";
	printf OUTPUT "State, Localtime, Full Timestamp of start (sec since epoch), Sec in state, Cum. sec in state\n";
	printf OUTPUT "----------------------------------------------------------------------\n";
	#close (OUTPUT);
	
	return ($firstframe,$left,$right);
}


#----------------------------------------------------------------------------------
# void drawTitle ()
#   Draws the intro material
#----------------------------------------------------------------------------------

sub drawTitle()
{
	system("clear");
	print "\n\n\n******************************************************************\n";
	print "\n";
	print "        ()-().----.      .       \n";
	print "         \\\"/` ___  ;____.'       Intervole Timer\n";
	print "          ` ^^   ^^              2006-2012 Behavioral Scoring Program\n";
	print "\n";
	print "*******************************************************************\n\n";
}

#----------------------------------------------------------------------------------
# void drawInstructions (string firstframe, int started)
#   Behavioral scoring instructions (round 2)
#----------------------------------------------------------------------------------

sub drawInstructions()
{
	system("clear");
	print"Behavioral Scoring Instructions\n\n";
	print"\n* Press Space to begin timing (as soon as video begins).  \n* Press Space to end scoring session (when video ends).\n* Use \',\' and \'.\' to move between states\n\n";
	print"If you must pause, type <p> and note frame on video.  \nRestart video at or before that frame and type <p> to unpause.\n";
	
	if ($started ==1)
		{
			($sec, $min, $hour) = ( localtime ) [ 0, 1, 2];		#Time scoring is begun (good enough for screen display only)
			print"Recording begun at $hour:$min:$sec \n";			
		}
	else 
		{
			print "\n\n";
		}
	
	print"    <-------------------------------START--------------------------------->\n";
	print"   Left        Left chamber      Center chamber      Right chamber      Right\n";
	print"   huddling    not huddling        (& tube)          not huddling    huddling\n\n";
}



#----------------------------------------------------------------------------------
# string drawState (int $state)
#   takes a state from 0 to 4 and returns a graphical version of the vole position
#----------------------------------------------------------------------------------

sub drawState()
{
	if ($state == 0) {
		return '   <: )--                                                                 ';
	}
	if ($state == 1) {
		return '                 <: )--                                                   ';
	}
	if ($state == 2) {
		return '                                   <: )--                                 ';
	}
	if ($state == 3) {
		return '                                                     <: )--               ';
	}
	if ($state == 4) {
		return '                                                                    <: )--';
	}
 	die ('invalid state');
}  

#----------------------------------------------------------------------------------
# arrayref recordState (int $state, $time_on, $durations, $iterations)
#   takes a state from 0 to 4 and the time that state started, and records elapsed seconds
#   returns $time_off, essentially the time of the most recent key press
#----------------------------------------------------------------------------------

sub recordState()
{
	my $time_off = [Time::HiRes::gettimeofday( )];
	my $elapsed = Time::HiRes::tv_interval($time_on,$time_off);
	my ($startsec, $startusec) = @$time_on;
	my ($s, $m, $h) = localtime($startsec);	#localtime for printing in output file

	$durations->[$state] += $elapsed;  # add elapsed time to cumulative tally
	
	if ($elapsed > 3) {
		$iterations->[$state] ++;          # When detecting huddling bouts, must be in state for >3 sec to count.
	}
	elsif ($state ==2) {				   # but center entries count as iterations no matter what
		$iterations->[$state] ++;
	}
	
	printf OUTPUT ("$state, %d:%d:%d, %d\.%d, %f, Cumulative duration: %f\n", $h, $m, $s, $startsec, $startusec, $elapsed, $durations->[$state]); # put timestamp in file as backup data source
	return $time_off
}

#----------------------------------------------------------------------------------
# void summarizeData (arrayref $durations, arrayref $iterations)
#   takes a state from 0 to 4 and the time that state started, and records elapsed seconds
#   returns $time_off, essentially the time of the most recent key press
#----------------------------------------------------------------------------------

sub summarizeData()
{
	my($total_min)=0;
	my($multiplier)=1;
	my $left_hud; my $right_hud; my $left_not_hud; my $right_not_hud; my $solo; 
	my $notes;
	my $scorer;
	my $testduration = 30;
	my $yesno;
	my $pause;
	
	system ("clear");
	printf OUTPUT "---------------NOTES----------------------------------------------------\n$notes";
	
	$left_hud = $durations->[0]/60;
	$left_not_hud = $durations->[1]/60;
	$solo = $durations->[2]/60;
	$right_not_hud = $durations->[3]/60;
	$right_hud = $durations->[4]/60;
	
	$total_min = (($durations->[0]+$durations->[1]+$durations->[2]+$durations->[3]+$durations->[4])/60);
	$multiplier = $testduration/$total_min;
	
	printf OUTPUT "----------------------------------------------------------------------\n";	
	printf OUTPUT ("\n\nSUMMARY DATA:\n");
#print raw time values	
	printf OUTPUT ("--------------ACTUAL SCORED TOTALS (at scoring speed)------------------\n");
	printf OUTPUT ("Total time left:  %.2f min\n", $left_hud + $left_not_hud);
	printf OUTPUT ("Total time right: %.2f min\n", ($right_hud + $right_not_hud));
	printf OUTPUT ("Time solo:        %.2f min\n", $solo);
	printf OUTPUT ("Huddling left:    %.2f min, %d bout(s)        ", $left_hud, $iterations->[0]); 
	printf OUTPUT ("Huddling right:   %.2f min, %d bout(s)        \n", $right_hud, $iterations->[4]); 
	printf OUTPUT ("Not hudd left:    %.2f min\n", $left_not_hud); 
	printf OUTPUT ("Not hudd right:   %.2f min\n", $right_not_hud); 
	printf OUTPUT ("Total min scored: %.2f min\n", $total_min);
	printf OUTPUT "Activity (corrected center entries): " . (($iterations->[2])-1)  . "\n";

#print times scaled to a 30 min total
	printf OUTPUT ("--------------SCALED SCORED TOTALS (%.0f min test)--------------------------\n", $multiplier*$total_min);
	printf OUTPUT ("Left vole: $left, Right vole: $right\n");	 #finish
	printf OUTPUT ("Total min (scaled): %.2f min\n\n", $multiplier*$total_min);
	printf OUTPUT ("Total time left:  %.2f min\n", $multiplier*($left_hud + $left_not_hud));
	printf OUTPUT ("Total time right: %.2f min\n", $multiplier*($right_hud + $right_not_hud));
	printf OUTPUT ("Time solo:        %.2f min\n", $multiplier*$solo);
	printf OUTPUT "Activity (corrected enter entries): " . (($iterations->[2])-1)  . "\n";
	printf OUTPUT ("Huddling left:    %.2f min, %d bout(s)\n", $multiplier*$left_hud, $iterations->[0]); 
	printf OUTPUT ("Huddling right:   %.2f min, %d bout(s)\n", $multiplier*($right_hud), $iterations->[4]); 
	
	system ("clear");
	print "Please enter the name of the scorer:";
	$scorer = <STDIN>;
	printf OUTPUT "\nScored by: $scorer\n";
	print "Please enter any notes or observations to add to this scoring file.  \nSpecifically mention whether free vole interacted at all with each vole. \n(Press enter when done):\n";
	$notes = <STDIN>;
	printf OUTPUT "---------------NOTES----------------------------------------------------\n$notes";

}