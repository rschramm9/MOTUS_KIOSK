**6.2.2 (2025-08-10)**

global.R  bumped version 

configUtils.R
   - prior rework on keyValueToList() caused that function to return
      a zero length list instead of NULL.  Modified calls to check for both
      NULL and length(list)==0.
   - add new parameters ApiKey_1 and ApiKey_2
   - add new parameters RebuildCacheDelaySeconds and RebuildCacheDepth

kiosks/DEFAULT/kiosk.cfg
   - add new parameters ApiKey_1 and ApiKey_2 for future use.
   - add new parameters RebuildCacheDelaySeconds and RebuildCacheDepth

BuildCache.R
   - moved to code/modules
   - implement parameters RebuildCacheDelaySeconds and RebuildCacheDepth
   - comment out calls to motus .org that never take long.  Left only the
     call to get tagDeploymentDetections as it is the one that typically
     takes the longest to complete.
   - above all done to minimize the number of hits on the motus.org data
     servers from the kiosk app.

Add utility script checkGitPushPull.bat for windows machines

Add utility script checkGitPushPull.sh for linux/OSX machines



**6.2.1 (2025-05-26)**

  Motus.org dashboard updates changed the page title of the homepage on
a redirect.  Following modules needed to test for a different page
redirect 
  tagInfo.R
  tagDeploymentDetections.R
  tagDeploymentDetails.R
  teceiverDeploymentDetections.R
  receiverDeploymentDetails,.R
  pingMotus.R


utility_functions
   modify testPageTitlenodes,  was not detecting title nodes correctly


ReceiverDetections.R
  titlePanel background color is now set dynamically to
  match config.NavbarTextColor. (had been hard wired to
  AnkenyGreen)

Upgrade from R 4.3.3 to R 4.5.0 broke config file parsing.
Needed to modify getStartConfig() and getKioskConfig() in configUtils.R to
use readlines() and then call new function linesToList(). 
Also modify function keyValueToList() in configUtils.R. It no longer calls 
lv2list(), instead it handles the list conversions internally.
Delete function lv2list() from utility_functions.R

BuildCache.R
   modifed to use the config.AdminContact to build the UserAgent string.  


##### 6.2.0 (2025-05-24)

configUtils.R
   add new parameter AdminContact

kiosks/DEFAULT/kiosk.cfg
   add new parameter AdminContact

server.R
  calls new function pingMotus()instead of receiverDeploymentDetails() to get motus.org online status

tagTrack.R
  include a "UserAgent" in the get URL so folks at motus.org can see who is making the request to help with their web traffic monitoring

utility_functions.R  function readUrlWithTimeout()
  include a "UserAgent" in the get URL so folks at motus.org can see who is making the request to help with their web traffic monitoring

global.R
     source new module pingMotus.R
     build the global userAgent string 

pingMotus.R
    added new module to handle the ping function

documentation/2_CONFIGURATION_GUIDE.md
  revised how to find deployment ID
  added documentation for the new AdminContact parameter

##### 6.1.1 (2025-04-22)

Fixed tagDeploymentDetections.R due to changes in the new motus dashboard.  the URL like https://motus.org/data/tagDeploymentDetections?id=49315 now includes the REceiverDeploymentID as a data column. Prior versions I had to extract the ID from the anchor tag of the site name.
This new ID data column also caused the array indexes for lat/lon to shift to the right.

##### 6.1.0 (2025-02-20)

Fixed known Issues #3 and #4 having to do with broken 'ignore detection by' processing 
and whitespace appearing in the kiosk.cfg file key/value processing.

Remove startup.cfg from the repository management. Replaced it with startup.cfg.template.  The startup.cfg file is always modified by the end user which complicates pulling core kiosk code changes and bug fixes from the repo.  

All ignore tags files have been renamed and will need to be manually moved to the users kiosk/data/ignoredetections directory and hand edited by the user.

Summary of changes to files:

ReceiverDetections.R
- rename receiverDeploymentID to GblReceiverDeploymentID anywhere the global
 variable is needed.  ie. it is the curently selectedd areciever

- add the tagDeploymentID to the tagflight_df dataframe so that
 it can be used to filter the dataframe of wild points instead ofthe tagID

 - overhauled all of the tagflight_df ingnore filters, including changed the
 ignore dataframe names to be more obviously and consistently named

 - the modified several of the fields in the .csv ignore file to be consistent
 - the above all fix Reported Issue #4

 Global.R
 - bump the version number

 - modified the read of the ignore.csv file.  Filenames and the global dataframe names

 - rename receiverDeploymentID to GblReceiverDeploymentID so that anywhere the global
 variable is needed it is obvious it using a global not a local.  ie. it is
    supposed to represent the curently selected reciever

 BuildCache.R
 - modified the read of the ignore.csv file.  Filenames and the global dataframe names. (Same as in Global.R)

 configUtils.R

 - remove the  assign("configfrm" to global.  It was never used as a global
 - modified the configfrm <- read.table call to strip whitespace. Fixes Reported Issue #3
 - added param SelectedTabTextColor

 utility_functions.R
 - comment out the warnings trap in ReadCsvToDataframe().  We want to see warning if any
 are thrown.

 tagDeploymentDetections.R
 - remove whitespace around dates when building the summaryFlight_df, was causing
    problems when filtering dateframe by date.

 receiverDeploymentDetections.R
 -  modify the filters of the dataframe df to use the new names for the 'IgnoreBy'
 dataframe names. (see Global.R above)

 ignoredetections files
 - all of the ignore detections files have been renamed to be consisten and much
 clearer about what they do.  Internal, some fieldnames have been modified
   for consistent naming. i.e. TadDepID and TagID were renamed tagDeploymentID
   where necessary.  The files are now:
    ignore_by_tag.csv
    ignore_by_receiver.csv
    ignore_by_tag_receiver.csv
    ignore_by_tag_receiver_date.csv
 - ignore startup.cfg which is no longer managed in the repository ( repo file is now startup.cfg.template)


##### 6.0.0 (2025-01-17)

Major rework of the application layout and css.  Added numerous kiosk.cfg parameters to allow easy configuration of background colors and text colors of most of the main page elements.

Change the layout so now the language picker sticks to the upper right corner..

Added a jump to tag detection map button (completing the implemention begun in v5.2.1)

Implemented the configuration option to make the default opening page be the normal homepage or the tag filight map page per a users request.

New css layout eliminated the need for configuration item MainLogoOffsetPixels

For clarity configration item NavbarColor has been renamed to NavbarBackgroundColor

For clarity configration item TitlebarColor has been renamed to TitlebarTextColor

Added items such as NavbarTextColor , NavbarSelectedTabTextColor, NavbarSelectedTabBackgroundColor.  See the Configuration Guide for details.

Required extensive changes to ui.R ,  server.R, global.R as well as ReceiverDetections.R and of course configUtils.R

Completely replaced the massive uniteligable .css file with greatly simplified .css with lots of inline comments. 

Discovered some tagged birds with very large datasets. They were taking more than 30-40 seconds to just get the data from motus.org making the UI frustrating to use.  Added an optional script (BuildCache.R) and a .bat fille that can run it.  If run nightly it will generate a complete data cache so that the daytime user interfacve stays responsive.



##### 5.2.1 (2025-01-13)

Begin to implement a feature that will allow the config file to specify if the app should open ito the homepage or to the tag detection map tab.

- ReceiverDetections.R - Add id's to to navbar tab panels
- Ui.R fixed reported issue #2 available receivers picklist/dropdon too small.



##### 5.2.0 (2024-11-28)

Removed the test at startup that would block server from completing
initialization until motus.org was reachable. This would make the
kiosk show a blank screen on boot until motus.org and/or the network
was up. Instead, add a line above the kiosk main titlebar to display warning
message if motus.org appears to be offline/unreachable.  Also quite a bit
of code cleanup and comments in ui.R and server.R  (see ReleaseNotes)

global.R

- disable the while(DONE) loop used to test if the motus.org server was online
- when starting up. Just created an empty dataframe and go so the UI starts

ui.R

- add a fluidRow above the main titlebar to display status if motus.org offline
  (see ui_motus_statusbar() )
- move footer definition to ui_footer() 
- clean up reformat some code blocks for readability
- add comments

server.R

- implement fluidRow above the main titlebar to display status if motus.org offline
- added reactive value motusServerStatusReactive2 to handle the new ui_motus_statusbar
- add function manageTitlebarMotusStatusMessage() to handle setting the ui_motus_statusbar
  language translation
- renamed reactive value motusServer to motusServerStatusReactive1 
- clean up reformat a lot of code for readability
- add a lot more comments

##### 5.1.6 (2024-07-23)

Added new module tagInfo.R which provides access to tag information such as serial number, mfg, frequency, and burst interval. This information is now visible on the Tag Details panel. tagInfo.R is called from within ReceiverDetections.R which renders the result on the Tag Details panel of the UI.

##### 5.1.5 (2024-05-03)

- Motus_Kiosk is now tested to run under both Windows 10 Pro and Windows 11 Pro.

- The documentation file 3_SETUP_FOR_WINDOWS has been split into a Windows_10 and a Windows_11 versions.

- Minor edits to other documentation files where clarification was needed.

- Fixed issue in configUtils.R where receiverdeploymentID lists in kiosk config containing whitespace not parsing correctly.

- Greatly simplified getting OpenKiosk setup to autorun on login of MOTUS_USER - all of the nitty-gritty is now encapsulated in a new powershell script (see code/SetOpenKioskAutostart.ps1) and instructions added to FINAL_DEPLOYMENT_FOR_WINDOWS.md

  
