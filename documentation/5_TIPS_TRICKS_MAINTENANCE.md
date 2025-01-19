# Tips, Tricks and Maintenance for Motus Kiosk

### For the MOTUS Nature Center Kiosk App v5.1.0

### Who do I talk to?

-   Owner/Originator: Richard Schramm - [schramm.r@gmail.com](mailto:schramm.r@gmail.com){.email}



### 1.0 - One Kiosk Monitoring Multiple Motus Receivers

A single kiosk can monitor one or many receivers. Users select which receiver to display data from in the dropdown menu in the upper-right corner. See Configuration_Guide Section 2.1

### 2.0 - Manage different configurations of a Kiosk 

A single kiosk can have multiple kiosk.cfg files - e.g. one for the local computer running a locked down display and another for a web deployed version for the same kiosk app. 

- Where your current kiosk.cfg file is, Just a copy with a different name.  
- Modify it as needed
- Edit the startup.cfg file to point to the second file.

### 3.0 - Manage Multiple Kiosks

You may be responsible for kiosks at different sites or locations that have different look&feel or content.  

The best way to manage this is to keep all of the site-specific content in (logos, images, html pages etc) in a folder like yourusername/Documents/kiosks.

Create that directory, then copy the 'kiosks'  folder from the the R Project directory to it.

Then point the startup.cfg file to whichever one you want to run at any given time.

### 4.0 - Remove Wild points, false detections or "Test Tags"

#### 4.1 The 'ignore files'

Each kiosk instance has three files in the MOTUS_KIOSK/kiosks/*kioskname*/data/ignoredetections folder.

For individual detections:  ignore_date_tag_receiver_detections.csv 

For a tag to ignore detections always (eg your test tags):  ignore_tags.csv

For a tag to ignore only for duration of one deployment (eg. if your tag was used for awhile but later deployed on an animal):  ignore_tag_deployments.csv

See the DEFAULT kiosk for examples.

### 5.0 - Suspect Detections Filter

Starting with MOTUS_KIOSK Version 5.1.0  I have introduced an experimental attempt at filtering wild point "suspect" detection data. This feature can be turned on by setting the kiosk.cfg parameter EnableSuspectDetectionFilter to 1.  Enabling this feature currently places a checkbox on the ReceiverDetections panel so the user can toggle it on and off to see the filter effect. Disabling this feature hides the checkbox and bypasses all filtering logic.  

Another kiosk.cfg parameter "VelocitySuspectMetersPerSecond" parameter is currently used as the upper limit to bird's horizontal flight velocity.

```
EnableSuspectDetectionFilter=1
VelocitySuspectMetersPerSecond=55
```

Currently the algorithm is very unsophisticated and will hopefully be subject to improvements in future releases.    



### 6.0 - How to Cleanup Log Files

When running as a Windows locked down kiosk that is started at boot. - log messages get written to a file in the The app writes console messages to a log file in the MOTUS_KIOSK/kiosks/*kioskname*/logs folder.

Useful for debugging but may need a yearly cleanup to recover space

### 7.0 - How to Cleanup Data Cache

If a kiosk has its EnableWriteCache set to 1 (default) ,  recently retrieved detection data are stored in a local cache to reduce calls out to motus.org.  These can grow old and you may want to purge them after some period to recover space.   Each kiosk instance has its own data cache.  Cached files are in the MOTUS_KIOSK/kiosks/*kioskname*/data/cache folder. They all end in name .Rda  It is always completely safe to delete any or all of them.



### 8.0 - Build a complete data cache nightly

The kiosk app utilizes a data cache to improve performance by storing recent data requests in al local file. If  data cached on disk is older than the age threshold set in the kiosk.cfg file, fresh data is requested from motus.org.  Some sites are frequented by birds with high burst rates or significant residence times, that make the motus.org request take 30-445 seconds to load.  This can make the user interface frustrating to use. 

One approach to consider to improve performance is to build a complete cache for all detected tags for all of the available receivers in your kiosk.cfg. I you build the cache late at night and set the cache maximum age to 24 hrs then cached data will always be available and up-to-date withing 24 hrs.

The script BuildCache.R in the main project directory will do this.  It can be made to run from a Windows batch file that is started nightly via the **Windows Task Scheduler**.  (Similar to how the kiosk server is started at boot.)

**8.1** - Login as administrator Admin

**8.2** - First we need to make a couple of edits a command .bat file to set the path to the installed version of the R language, the user account to run as, and a path to a directory for log files etc

​	**8.2.1**  Using the File Explorer, find the folder where you installed R.  If you followed recommendations then is should be in C:\R.  If its not there then most likely its in C:\Program Files\R  

​	**8.2.1** Open the folder and then make note of the version of R.  (e.g R-4.2.2)  folder C:\Program Files\R. 

Make a note of the **BOTH** the path and the version for use below.

​	**8.2.2** Using the File Explorer navigate to your 'extras' directory that contains the .bat file we need to edit.  Likely C:\MOTUS_USER\Documents\kiosks\yourkioskname\extras 

​	**8.2.3** Open this file for editing in notepad MOTUS_MSWINDOWS_BUILDCACHE.bat

** WARNING:** make sure your editing the .bat file in your own kiosk (not in the DEFAULT kiosk). 

** IMPORTANT Pay close attention to the user of forward-slash and back-slash characters in the paths in the .bat file.  DOS requires paths using forward-slash,  R likes to see 'linux' type paths using bask-slash. Notice where the DOS portion of the cmd line uses forward-slash and the parts that get passed to R use the back-slash form.

	 - Set the path to R in the cmd shown in the .bat file to the location discovered above.
	 - Set the R version field in the path to match your installed version discovered above.

  - Check the username. If you chose to run as a different user than MOTUS_USER
    then substitute that username below in two places.
  - check the path to the logs directory. You will want to have logs written
    in with your kiosk specific directory. If you have followed recommendations then that
    logs directory will be in the same place as your kiosk.cfg file - (likely in
    the path: C:\Users\MOTUS_USER\Documents\kiosks\yourkioskname )

​	**8.2.4**   "Save" the file and exit.

**8.3** Your startup.cfg file in the MOTUS_KIOSK project will be used. It should already be set correctly if you are able to run the kiosk application.

**8.4**   Using the Windows desktop 'SearchBox'  to find the Task Scheduler' (or the TaskScheduler icon on if you have it one your taskbar). **Right-click and choose "Run as administrator"**

**8.5** - In TaskScheduler - Highlight "Task Scheduler Library" on the right side panel

**8.6** - In TaskScheduler Main Menubar:  Action > Create Task 

**8.7** - On the "General" tab

- Name the task: MOTUS_MSWINDOWS_BUILDCACHE_TASK
- Location field is just a default backslash character

  - Type a short Description. e.g. 
  - Check run under the Admin account. (ComputerName\Admin)·   

- Check the option  ‘Run whether user is logged on or not”

**8.8** - On the "Triggers" tab

- Click "New" button and in the pop-up, set "Begin the task" to run at “On a schedule”
- Set it to run daily
-  Recure every: 1 days
- Set the start to be tomorrows date and some time like 4:00 AM 
- Make sure the checkbox near the bottom of the panel here is “Enabled” (checked)
- Press "OK" button for the trigger.

**8.9** - On the "Actions" tab

- Click "New" button ; in the pop-up,  set  it’s 'Begin the task' dropdown to be “Start a  Program”
- In the "Program/script" section, use the browse button and navigate to the .bat file you prepared above. Likely: <br>C:\Users\MOTUS_USER\Documents\kiosks\yourkioskname\extras\MOTUS_MSWINDOWS_BUILDCACHE.bat and select it.
- Set the "Start In:" field to C:\Users\MOTUS_USER\Projects\MOTUS_KIOSK
- Press "OK"  for the action button.

**8.10** - On the "Conditions" tab

- Uncheck the box "Start only if computer is on AC power"
- Press "OK"  for the action button.

**8.11** - On the "Settings" tab

- Only the following two boxes should be checked:
  - "Allow task to be run on demand"
  - Stop the task if it runs longer than:  choose 2 hours.
  - "If task does not end when requested, force it to stop."
  - In the 'If the task is already running rule'  dropdown menu, pick "Stop the existing instance"
- Press "OK"  for the action button.

**8.12** - Click the final "OK" -  Windows will ask you for the Admin account password, then create the task. 

**8.13** - From within the TaskScheduler

Highlight the MOTUS_MSWINDOWS_BUILDCACHE_TASK task

Right-click and select "Run" from the dropdown.

In C:\Users\MOTUS_USER\ Documents\kiosk\your-kiosk-name\logs directory you should see a new logfile

In C:\Users\MOTUS_USER\ Documents\kiosk\your-kiosk-name\data\cache  directory you should see new .Rda datafile.

Depending one how nmany receivers are in your kiosk.cfg file, and how many detections at those receivers, the task may take anywhere from a a few minutes to a half hour or more.

the the Task Scheduler, periodically right-click on the 'Task Schedular Library' in the left panel, and chose 'Refresh'.   In the list of tasks, the he Status column MOTUS_MSWINDOWS_BUILDCACHE_TASK task will change from 'Running' to 'Ready' when the task finishes.

**8.14** - *Dont forget to modify your kiosk.cfg file to set the ActiveCacheAgeLimitMinutes=1440* 

**

**
