# Motus Kiosk Windows Final Deployment


### Motus Kiosk web app - Final Deployment ###
This document is a guide on how to get the 'Motus Kiosk' Shiny web app deployed into OpenKiosk on Microsoft Windows 10.

 It is the third of the three documents that I use to describe the full setup of the kiosk. 

The first is WINDOWS_FIRSTRUN_README.md that describes all the tweaks and setting to MS Windows10

The second is BUILDING_THE_APP_README.md that describes installation of the build tools and constructing the Shiny web app.

*All of the work described in the first two documents should be completed before attempting what is in this document.*

If you are wanting to modify or further develop the application there is a fouth document named DEVELOPERS_README.md that may be helpful.


### Who do I talk to? ###

* Owner/Originator:  Richard Schramm - schramm.r@gmail.com

### Preliminaries ###

##### The OpenKiosk
The OpenKiosk is a basically a specialized web browser with configurable restrictions that will connect to our Shiny web application (via an http connect to a port on a web server).

See: https://openkiosk.mozdevgroup.com

##### The Web Application
 The application is built in R-Studio using the R package "Shiny" (see: https://shiny.rstudio.com/)
 Shiny is an R package that makes it easy to build interactive web apps straight from R.

When run on the local machine from a command line it will start a 'shiny server' on a local machine URL that we will point OpenKiosk to. We are etting up a MS Windows task to start our shiny server on boot up. 

We are setting  OpenKiosk to start at every login of user MOTUS_KIOSK to connect to our shiny server via http. OpenKiosk will be run within a full-screen window that is configured to prevent the user from doing anything except use our intended application. 

### How do I get started? ###

##### Complete all steps of WINDOWS_FIRSTRUN_README.md

This and all other accompanying documentation assumes a particular Windows10 user account username=MOTUS_KIOSK and project directory structure: C:\Users\MOTUS_KIOSK\Projects\MOTUS_KIOSK

##### Complete all steps of BUILDING_THE_APP_README.md

It is assumed here that you are now able to run the MOTUS_KIOSK project in R-Studio running on your target machine and the project has been downloaded from github resides in the above directory belonging to the MOTUS_KIOSK user.

#### 1.0 - Install OpenKiosk on your platform.

* *Read this warning this before proceeding:*

```
When open kiosk runs it may appear to lock you out of viewing other windows (including possibly this document! Have you got a pencil handy? The secret to unlock:
- Shift F1 puts an administrator login banner up in the upper-left. Enter ‘admin’ as the password
- Shift F9 puts quit banner up - look over at the Upper-right – there is a “quit” button

(Note )on my macOSX keyboard its fn+Shift+F1 and fn+Shift+F9)
```

Download and install OpenKiosk from https://openkiosk.mozdevgroup.com/

*It’s a long download* that ends up in your downloads folder – something like OpenKiosk91.7.0-2022-02-22-x86_64.exe
**28March2023 - now downloads a .msi installer file to your Downloads folder (not a .exe)** 

Double-click the installer. Windows may show “Windows protected your PC”,  just click “More info” and select “Run anyway”

Accept the license, and click through all the standard default installation wizards.

Go to C:\Program Files and run OpenKiosk by double-clicking it – It will run in its own browser an it will likely look like your locked onto that screen… (that’s a good thing!)

Shift F1 puts administrator login banner up in the upper-left. Enter ‘admin’ as the password (this is the default password for OpenKiosk.

While on the admin page:

Select "Home" selector on the sidebar panel.

* Set "Homepage and new windows" to "localhost:8081" 

Select "OpenKiosk" selector on the sidebar panel.

Verifiy Settings are:

- "Enable Attract Screen" False (unchecked box)
- "Enable Full Screen" True (checked box) http://
- "Enable Redirect Screen" True (checked box)
- "Enable URL Filters" False (unchecked box)
- Set homepage to : localhost:8081  << this port must agree with the shiny app startup task we will create in next section!
- "Enable Javascript" True (checked box)
- "Enable Network Protocol Filters". Both blob and data should be checked
- Section "Reset Session" check the box for "Set Inactive terminal" and reset after 5 minutes
- Section "Reset Session" check the box for "Enable Countdown" and show for 10 seconds
- Section "Reset Session" check the box for "Enable Countdown on Manual Reset" (True)
- "Enable Tabbed Browsing" False (box unchecked)
- "Enable URL Toolbar" False (box unchecked)
- In the "Quit" section, "Enable Quit Button Password" True (checked box)
- "Allow Multiple Displays" False
- In the "Password" section - you may wish to change the OpenKiosk admin password - but r*emember it - there is no password recovery mechanism!!*

"Quit" the OpenKiosk (button on upper right of the main panel)



#### 2.0 - Set the shiny kiosk application local web server to run at at boot

Shiny kiosk  is a background server application needed by the kiosk web pages. We want it to start at boot so it’s running and ready whenever the kiosk gui is displayed by OpenKiosk (eg.when ever the motus_kiosk user logs in)

There are two files in the project directory.

File 1 - MOTUS_MSWINDOWS_STARTSERVER.bat is the command file that starts the kiosk server

File 2 - MOTUS_MSWINDOWS_STARTSERVER_TASK.xml is used to create the task scheduler job that runs the above .bat file at system boot

**2.1** - Login as administrator Admin

**2.2** - Check the path to the installed version of R.
 2.2.1 -  Using the File Explorer, navigate to  C:\Program Files\R and make a note of the path where R is installed (eg. R-4.2.2)

**2.3** - Edit the startup command .bat file to set the path to the installed version of R

 2.3.1 - Using the File Explorer, find the file: MOTUS_MSWINDOWS_STARTSERVER.bat in the main project folder.

 2.3.2 - right-click to edit (in notepad) , set the path in the cmd shown to the version discovered above and "Save" it.

**2.4** - Create the task scheduler run-at-boot job.

 2.4.1 - Right-click the TaskScheduler icon and choose "Run as administrator"

 2.4.2 - In TaskScheduler window - Click to highlight "Task Scheduler Library" on the right side panel

 2.4.3 - In TaskScheduler Main Menubar:  Action > Import Task

 2.4.4 - in the "open file" pop-up, navigate to the file  MOTUS_MSWINDOWS_STARTSERVER_TASK.xml in the project folder and "Open" it.

  **Note** Windows may ask you for the Admin account password, before it will create the task.) 

**2.5**  - Test that the job starts manually

 2.5.1 - From within the taskManager , highlight the MOTUS_MSWINDOWS_STARTSERVER_TASK task you just created, right-click on it and select 'Run'.

 2.5.2 - Open Chrome or Firefox and browse to:  http:://localhost:8081 - the kiosk app should be displayed in the browser.

**2.6** - Test that the job starts on boot

 2.6.1 - shutdown and reboot the PC.
 2.6.2 - retest by pointing your web browser again to localhost:8081

**Warning** On a slow PC, sometimes it takes a few momentd for the server to fully start.  Your browser may say it failed to connect, wait perhaps 5-10 seconds and retry.)

**2.7** - At this point you should have a kiosk server )that auto-starts whenever the PC is booted (but not the dashboard window yet...that comes next)wmic

**TROUBLE SHOOTING:** If the browser doesnt display the dashboard.

First look in the main project's Logs directory for any messages in the most recent log.

Else try opening a Cmd.exe window and R-Studio side-by-side. In the command window type the full command below all as a single line:

**WARNING**: sometimes a cut&paste from below will replace the single quotes that wrap the directory path  with a reversed quote (’). Its really hard to spot so make sure after the paste they both are true single quotes!  Same for the double-quotes.

```
“C:\Program Files\R\R-4.2.2\bin\R.exe” -e “shiny::runApp('C:/Users/MOTUS_KIOSK/Projects/MOTUS_KIOSK',port=8081)"
```

View the command output for hints to the error - sometimes it has been a failed package load and there will be a message like "No package xxxx not found".  This can usually be cleared by typing install.package("xxxx") in the RStudio console.  (See also the BUILDING_THE_APP_README.md Section 3.0)

Once you are able to get the Kiosk dashboard to display in a Web browser,  shutdown and reboot the PC. Then point your web browser again to localhost:8081

(Note that on a slow PC, sometimes it takes a few moment for the server to fully start.  Your browser may say it failed to connect, wait perhaps 5-10 seconds and retry.)

At this point you hopefully have a kiosk server that auto-starts whenever the PC is booted.

 

### 3.0 - Make user MOTUS_KIOSK auto start kiosk gui on login

The kiosk gui that the user sees is displayed by OpenKiosk which is a completely locked down display so the public can not access anything on the computer except the gui we show them.  We want the kiosk to start up automatically when the MOTUS_KIOSK user logs in.

It must open in its "own shell" - not the normal explorer.exe shell to prevent the user from being able to access the windows desktop or other applications such as cmd.exe

**3.1** Log in as MOTUS_KIOSK

3.2 First we need to find the MOTUS_KIOSK ‘security identifier’ or SID.

·   	- you must be logged in as user=MOTUS_KIOSK 

·   	- Open a CMD.exe window

·		- Type the command :  wmic useraccount get name,sid

· 		- Look at results to locate the Sid for MOTUS_KIOSK

.			Example:  S-1-5-21-195043977-3097296022-4082461035-1012

**3.2 **Next we prepare a comand string using a temporary text file.

. 		- Right-click anywhere on the Desktop and select 'New' > 'Text file' and open it for editing

.		- Cut and paste this line into the file exactly as shown into the file (as a single line).

```code
reg add "HKEY_USERS\####\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d """"c:\Program Files\OpenKiosk\OpenKiosk.exe""" http://localhost:8081"
```

.		- cut the MOTUS_KIOSK Sid SID from the command window

.		- paste the into the "reg add cmd" in the text file - replacing only the four #### characters

**3.3** Now copy (control-c) and paste (control-v)  the fully assembled command string into the Cmd.exe window and press 'Enter'

It should say all is good

**3.4** Log out, then log back in as MOTUS_KIOSK You should see the auto-started kiosk app

**3.5** Click in kiosk window and type: Shift + F9  (to quit) and type the kiosk admin password.

**3.6** You can now delete the temporary text file from the Desktop

**Troubleshooting:**  WARNING: Sometimes on system reboot, the kiosk will come up blank with "Unable To Connect"

That typically means the MOTUS_KIOSK_SERVER was either slow to start or failed to start at boot.  Wait a 10 seconds and "Try Again" If success -  If no luck... then in the Kiosk window type Shift-F9 and enter the pasword to quit

Go to Section 2 try to troubleshoot the auto-start at boot of the shiny server.



#### Appendix 2 - OBSOLETE App.R Start on Boot Directions OBSOLETE

 15-Nov-22 I changed the windows task startup proceedure (Section 2 above) to make it easier to debug startup issues. Below is the old proceedure which would still work but is less friendly and harder to troubleshoot. 

#### A-2.0 - Set the shiny App.R local web server to run at at boot

Shiny kiosk App.R is the background server application needed by the kiosk web pages. So we want it to start at boot so it’s running and ready whenever the kiosk gui is displayed by OpenKiosk (eg.when ever the motus_kiosk user logs in)

**A-2.1** - Login as administrator Admin

**A-2.2** - Right-click the TaskScheduler icon and choose "Run as administrator"

**A-2.3** - In TaskScheduler - Highlight "Task Scheduler Library" on the right side panel

**A-2.4** - In TaskScheduler Main Menubar:  Action > Create Task 

**A_2.5** - On the "General" tab

.			-  The task will be named MOTUS_KIOSK_SERVER

.			-  Location field is just a default backslash character

·   		-	Check the option  ‘Run whether user is logged on or not”

·   		-	Check that it is set to run under the Admin account.

**A-2.6** - On the "Triggers" tab

·   		- Click "New" button and then set "Begin the task" to run at “Startup”

·   		- Make sure the checkbox near the bottom of the panel here is “Enabled” (checked)

·   		- Press "OK" button for the trigger.

**A-2.7** - On the "Actions" tab

·   		- Click "New" button and then set  it’s Action to be “Start a  Program”

·  		 - In the "Program/script" use the browse button and navigate to:

​			 “C:\Program Files\R\R-4.2.1\bin\R.exe”    (or which ever installed  version of R is) and select it

.			- Verify that the 'Browse' function filled in the Program/script field with the surrounding double-quotes as shown *above*

.			- Now fill the the Action "Add arguments" field as written below (with quotes as shown):  Note the port number selected must match the OpenKiosk default homepage set in previous section.

WARNING: sometimes a cut&paste from below will replace the single quotes that wrap the directory path  with a reversed quote (’). Its really hard to spot so make sure after the paste they both are true single quotes!

```code
-e “shiny::runApp('C:/Users/MOTUS_KIOSK/Projects/MOTUS_KIOSK',)
```

.			- Press "OK"  for the action button.

**A-2.8** - On the "Settings" tab

·   		- Uncheck the box "Stop the task if it runs longer than x days"

**A-2.9** - Click the final "OK" and Windows will ask you for the Admin account password, then create the task. 

**A-2.10** - From within the taskManager , highlight the MOTUS_KIOSK_SERVER task, right-click and select run. Then open Crome or Firefox and browse to:  http:://localhost:8081 - the kiosk app should be displayed in the browser.

**A-2.11** - If you are able to get the Kiosk dashboard to display in a Web browser,  shutdown and reboot the PC. Then retest by pointing your web browser again to localhost:8081

Note that on a slow PC, sometimes it takes a few moment for the server to fully start.  Your browser may say it failed to connect, wait perhaps 5-10 seconds and retry.)

**A-2.12** - At this point you hopefully have a kiosk server that auto-starts whenever the PC is booted. 
