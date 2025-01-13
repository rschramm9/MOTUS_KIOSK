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

  