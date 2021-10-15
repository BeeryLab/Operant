# Operant
Scripts for scoring operant social behavior

Instructions for running these files: see the more extensive readme for BeeryLab/IntervoleTimer which has step by step instructions for running these scripts.
Quick version:
From the command line (e.g. Terminal on a mac), navigate to the directory with the script and launch with "perl OperantSocialTimerRightTetheree1.2a.pl" 
Fill out the test information in response to prompts, then hit spacebar to begin scoring.  Use < and > (over , and .) to move the icon of the rodent. 

Operant Social Timer:
These scripts allow the user to quantify social behavior in an operant apparatus by moving a rodent icon to mimic behavior witnessed in any-speed playback video. 
Variables in the script allow the user to set the test duration (30 minutes is the session default) and results are scaled.

There are two versions of this file depending on whether the social chamber is arranged on the right or the left side of the apparatus relative to the video position.


A view of the version with the stimulus animal on the right, and the free vole depicted beneath the tube.

               Left (start)          Tube           Right           Right
               Operant box       (1/2 or more)      not huddling    huddling
          ________________________           ________________________________ 
         |                        |         |                                |
         |                        |_________|                                |
         |                        |_________|                        <: )--  |
         |________________________|         |________________________________|

                                    --( :>                                 



Operant Choice Timer:
This script is similar to the operant social timer except that it is set up for two levers that provide access to animals are on both sides of the main chamber
