# Final Deployment for Windows


### Motus Kiosk web app - Final Deployment on Windows OS ###
This document is a guide on how to get the 'Motus Kiosk' Shiny web app deployed into OpenKiosk on Microsoft Windows 10.

 It is the third of the three documents that I use to describe the full setup of the kiosk. 

The first is START_HERE.md that describes installation of the build tools and constructing the Shiny web app.

The second is the CONFIGURATION_GUIDE.md which describes how to configure a kiosk.

The third is SETUP_FOR_WINDOWS.md that describes all the tweaks and setting to MS Windows10

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

We are setting  OpenKiosk to start at every login of user MOTUS_USER to connect to our shiny server via http. OpenKiosk will be run within a full-screen window that is configured to prevent the user from doing anything except use our intended application. 

### How do I get started? ###

##### Complete all steps of START_HERE.md

It is assumed here that you are now able to run the MOTUS_KIOSK project in R-Studio running on your target machine and the project has been downloaded from github resides in the above directory belonging to the MOTUS_USER user (or whichever username you want to run the kiosk as).

##### Complete all steps of SETUP_FOR_WINDOWS.md

This and all other accompanying documentation assumes a particular Windows10 user account username=MOTUS_USER and project directory structure: C:\Users\MOTUS_USER\Projects\MOTUS_KIOSK

### 1.0 - Install OpenKiosk on your platform.

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

- Shift F1 puts administrator login banner up in the upper-left. Enter ‘admin’ as the password (this is the default password for OpenKiosk.


While on the admin page:

- Select "Home" selector on the sidebar panel.


* Set "Homepage and new windows" to "localhost:8081" << this port must agree with the shiny app startup task we will create in next section!

- Select "OpenKiosk" selector on the sidebar panel.


Verifiy Settings are:

- "Enable Attract Screen" FALSE (unchecked box)
- "Enable Full Screen" TRUE (checked box) 
- "Enable Redirect Screen" TRUE (checked box)
- "Enable URL Filters" FALSE (unchecked box)
- "Enable Javascript" TRUE (checked box)
- "Enable Network Protocol Filters". Both blob and data should be checked
- Section "Reset Session" check the box for "Set Inactive terminal" and reset after 5 minutes
- Section "Reset Session" check the box for "Enable Countdown" and show for 10 seconds
- Section "Reset Session" check the box for "Enable Countdown on Manual Reset" (True)
- "Enable Tabbed Browsing" FALSE (box unchecked)
- "Enable URL Toolbar" FALSE (box unchecked)
- In the "Quit" section, "Enable Quit Button Password" TRUE (checked box)
- "Allow Multiple Displays" FALSE
  
- In section "Keyboard Shortcuts"
- 	"Enable Back/Forward navigation keys" TRUE  <<<< CRITICALLY IMPORTANT!
- 	"Enable Settings keys" TRUE  <<<< CRITICALLY IMPORTANT!
  
- In the "Password" section - you may wish to change the OpenKiosk admin password - but r*emember it - there is no password recovery mechanism!!*

**CRITICALLY IMPORTANT **
Before you quit - double check that:
- Enable Back/Forward navigation keys is TRUE 
- Enable Settings keys TRUE
  
Otherwise you risk completely locking yourself out of your computer with absolutely no way to recover except by reinstalling the operating system.


"Quit" the OpenKiosk (button on upper right of the main panel)



### 2.0 - Set the shiny kiosk application local web server to run at at boot

Shiny kiosk App.R is the background server application needed by the kiosk web pages. So we want it to start at boot so it’s running and ready whenever the kiosk gui is displayed by OpenKiosk (eg.when ever the MOTUS_USER user logs in). This is accomplished by setting a job that starts in the background on boot using the **Windows Task Manager**. 

**2.1** - Login as administrator Admin

**2.2** - First we need to make a couple of edits a startup command .bat file to set the path to the installed version of the R language, the user account to run as, and a path to a directory for log files etc

​	**2.2.1**  Using the File Explorer, find the folder where you installed R.  If your followed recommendations then is should be in C:\R.  If its not there then most likely its in C:\Program Files\R  

​	**2.2.1** Open the folder and then make not of the version of R.  (e.g R-4..3.3)  folder C:\Program Files\R. 

Make a note of the **BOTH** the path and the version for use below.

​	**2.2.2** Using the File Explorer navigate to your 'extras' directory that contains the .bat file we need to edit.  Likely C:\MOTUS_USER\Documents\kiosks\yourkioskname\extras 

​	**2.2.3** Open this file for editing in notepad.  MOTUS_MSWINDOWS_STARTSERVER.bat  

** WARNING:** make sure your editing the .bat file in your own kiosk (not in the DEFAULT kiosk). 

** IMPORTANT Pay close attention to the user of forward-slash and back-slash characters in the paths in the .bat file.  DOS requires paths using forward-slash,  R likes to see 'linux' type paths using bask-slash. Notice where the DOS portion of the cmd line uses forward-slash and the parts that get passed to R use the back-slash form.

	 - Set the path to R in the cmd shown to the location discovered above.
	 - Set the R version field in the path to match your installed version discovered above.
  - Check the username. If you chose to run as a different user than MOTUS_USER
    then substitute that username below in two places.
  - check the path to the logs directory. You will want to have logs written
    in with your kiosk specific directory. If you have followed recommendations then that
    logs directory will be in the same place as your kiosk.cfg file - (likely in
    the C:/Users/MOTUS_USER/Documents/kiosks/yourkioskname path)

​	**2.2.4**   "Save" the file and exit.

**2.3** Edit the startup.cfg to eliminate any relative paths (expand ~/ path into absolute path)

NOTE: R likes to see 'linux' type paths here - notice the slash in "C:/Users" 

```
# KiosksPath="~/Documents/kiosks" expands to become
KiosksPath="C:/Users/MOTUS_USER/Documents/kiosks"
StartKiosk="mycustomkiosk"
KioskCfgFile="kiosk.cfg"
```

*Note: these values are case sensitive and must match exactly the directory structure containing your customized kios's content.*

**TIP:** relative (~) paths are convenient when developing your site using the RStudio IDE.  When your kiosk 'goes-live' it will likely be run in the background by another account such as Admin, at ~/ will expand to the Admin account, not MOTUS_USER)

**2.4**   Use the SearchBox or right-click the TaskScheduler icon on your taskbar and choose "Run as administrator"

**2.5 - In TaskScheduler - Highlight "Task Scheduler Library" on the right side panel

**2.6** - In TaskScheduler Main Menubar:  Action > Create Task 

**2.7** - On the "General" tab

- The task will be named MOTUS_MSWINDOWS_STARTSERVER_TASK
- Location field is just a default backslash character

   - Type a short Description. e.g. 
   -  Check run under the Admin account. (ComputerName\Admin)·   

- Check the option  ‘Run whether user is logged on or not”

**2.8** - On the "Triggers" tab

- Click "New" button and in the pop-up, set "Begin the task" to run at “At Startup”
- Make sure the checkbox near the bottom of the panel here is “Enabled” (checked)
- Press "OK" button for the trigger.

**2.9** - On the "Actions" tab

- Click "New" button ; in the pop-up,  set  it’s 'Begin the task' dropdown to be “Start a  Program”
- In the "Program/script" section, use the browse button and navigate to the main projects    		      Motus_Kiosk/extras/ MOTUS_MSWINDOWS_STARTSERVER.bat and select it
- Set the "Start In:" field to C:\Users\MOTUS_USER\Projects\MOTUS_KIOSK\code
- Press "OK"  for the action button.

**2.10** - On the "Conditions" tab

- Uncheck the box "Start only if computer is on AC power"
- Press "OK"  for the action button.

**2.11** - On the "Settings" tab

- Only the following two boxes should be checked:
  - "Allow task to be run on demand"
  - "If task does not end when requested, force it to stop."
- Press "OK"  for the action button.

**2.12** - Click the final "OK" -  Windows will ask you for the Admin account password, then create the task. 

**2.13** - From within the TaskScheduler

- Highlight the MOTUS_MSWINDOWS_STARTSERVER_TASK task
-  Right-click and select "Run" from the dropdown.
- Open a browser and go to URL:  http:://localhost:8081 - the kiosk app should be displayed in the browser.

**2.14** - If you are able to get the Kiosk dashboard to display in a Web browser,  shutdown and reboot the PC. Then retest by again  pointing your web browser again to localhost:8081

Note that on a slow PC, sometimes it takes a few moment for the server to fully start.  Your browser may say it failed to connect, wait perhaps 5-10 seconds and retry.)

**2.15** - At this point you hopefully have a kiosk server that auto-starts whenever the PC is booted. 

If not... 

**2.16** **TROUBLE SHOOTING: ** If the browser doesnt display the dashboard correctly.

First look in the main project's Logs directory for any messages in the most recent log. If the program was able to get far enough to start logging and crashed, then there should be a timestamped log file in the C:\MOTUS_USER\Projects\MOTUS_KIOSK\logs directory

Else try opening a Cmd.exe window and R-Studio side-by-side. In the command window type the full command below all as a single line:

**WARNING**: sometimes a cut&paste from below will replace the single quotes that wrap the directory path  with a reversed quote (’). Its really hard to spot so make sure after the paste they both are true single quotes!  Same for the double-quotes. It should all be a single line in the cmd window.

**Substitute your installed version of R in the cmd below*

```
“C:\Program Files\R\R-4.3.2\bin\R.exe” -e “shiny::runApp('C:/Users/MOTUS_USER/Projects/MOTUS_KIOSK',port=8081)"
```

View the command output for hints to the error - sometimes it has been a failed package load and there will be a message like "No package xxxx not found" or needs to be updated. This can usually be cleared by typing install.package("xxxx") in the RStudio console.  (See also the START_HERE.md Section 3.0)

Once you are able to get the Kiosk dashboard to display in a Web browser,  shutdown and reboot the PC. Then point your web browser again to localhost:8081

(Note that on a slow PC, sometimes it takes a few moment for the server to fully start.  Your browser may say it failed to connect, wait perhaps 5-10 seconds and retry.) 

### 3.0 - Make user MOTUS_USER auto start kiosk gui on login

The kiosk gui that the user sees is displayed by OpenKiosk which is a completely locked down display so the public can not access anything on the computer except the gui we show them.  We want the kiosk to start up automatically when the MOTUS_USER user logs in.

It must open in its "own shell" - not the normal explorer.exe shell to prevent the user from being able to access the windows desktop or other applications such as cmd.exe

**3.1** Log in as MOTUS_USER

**3.2** In the Windows Search Box - type Powershell

**3.3** When the Powershell console app is displayed, right-click on it and select 'Run as administrator'

**3.4** Following enter command:   Set-ExecutionPolicy unrestricted

**3.5** Following enter command:  (all on one line) ( *Substitute your correct username if you arent using MOTUS_USER !!)*

powershell -File  "C:\Users\MOTUS_USER\Projects\MOTUS_KIOSK\code\SetOpenKioskAutostart.ps1" MOTUS_USER

**3.6** Finally, enter command (to) restore the restriction for safety).
Set-ExecutionPolicy restricted

**3.7** Log out, then log back in as MOTUS_USER You should see the auto-started kiosk app

**3.8** Click in kiosk window and type: Shift + F9  (to quit) and type the kiosk admin password.

**Troubleshooting:**  WARNING: Sometimes on system reboot, the kiosk will come up blank with "Unable To Connect"

That typically means the MOTUS_KIOSK_SERVER was either slow to start or failed to start at boot.  Wait a 10 seconds and "Try Again" If success -  If no luck... then in the Kiosk window type Shift-F9 and enter the password to quit

Go to Section 2.16  try to troubleshoot the auto-start at boot of the shiny server.



