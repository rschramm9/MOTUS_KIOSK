# Configuration Guide

### For the MOTUS Nature Center Kiosk App v6.2.3

**This** document is a guide on how to configure get the 'Motus Kiosk' Shiny web app. for Version 5.x and later.

### Who do I talk to?

-   Owner/Originator: Richard Schramm - [schramm.r@gmail.com](mailto:schramm.r@gmail.com){.email}

### 1.0 - Preliminaries

##### 1.1 - Edit the startup.cfg file to point to your kiosk.

In the project's top-level directory is a file called startup.cfg It contains the path and name of the kiosk you want to start. For the DEFAULT kiosk the startup.cfg file is:

```
KiosksPath="~/Projects/MOTUS_KIOSK/kiosks"
StartKiosk="DEFAULT"
KioskCfgFile="kiosk.cfg"
```

In the project's top-level directory is a file called startup.cfg.  It contains the path and name of the kiosk you want to start. Your customized kiosk should be installed in another location per instructions. If it was  installed in the expected location then the startup.cfg file is something like:The '~' in KiosksPath instructs R to open the kiosk *relative* to the logged in users home directory.

In the the above example, the DEFAULT directory in the kiosks folder contains all of the site-specific files that make up the content of the DEFAULT kiosk.  

If you followed all the steps in the **1_START_HERE** document you will have already cloned the default kiosk and given the clone your own kiosk name.  If not, I suggest you either go back to complete those steps, or if you already know what your doing then go ahead and edit the Startup.cfg file now and set the correct kiosk name you want to work on.

Below reflects that the kiosk folder was copied to the users Documents folder - (see instructions in  StartHere.md Sections 9.0)

Startup.cfg becomes:

```
KiosksPath="~/Documents/kiosks"
StartKiosk="your-kiosk-name-here"
KioskCfgFile="kiosk.cfg"
```

Or..

```
KiosksPath= "C:/Users/MOTUS_USER/Documents/kiosks"
StartKiosk="your-kiosk-name-here"
KioskCfgFile="kiosk.cfg"
```

*Note: these values are case sensitive and must match exactly the project directory structure containing your kiosk.*

**TIP:** relative (~) paths are convenient when developing your site using the RStudio IDE.  However when your kiosk 'goes-live' it will likely be run in the background by another account such as Admin.  At some point you will want to modify the startup.cfg to use the full absolute paths (eg.  C:/Users/MOTUS_USER/Documents/kiosks)  (See the FINAL_DEPLOYMENT document Section 2.0)



##### 1.2 - Locate your site's motus receiver deployment ID.

To locate all of your desired receiver's deployment IDs: Go to motus.org
- Sign in to yur Motus.org account
- Click "Explore Data"  on the Motus Dashboard.
- Click on the "Stations" tab which will load a list of all stations
- Type your Station Name into the "Search Stations" box to filter the list.
- Look for the "**Last configured**" line, it should have a (Deployment #nnnnnn).  That is your deployment ID. 
  ( *NOTE: in Motus terminology, a Project may have multiple Receivers. A Reciever may have multiple RecieverDeployments - we are looking for the currently active **ReceiverDeploymentID**)* 

**TIP:** If you want your kiosk to display detections from multiple receivers, simply make a list of the all of the active ReceiverDeploymentIDs and names to use in the next step.

##### 1.3 Find a suitable logo for your main page.

Locate a suitable logo for your organisation. A .jpg or .png that is not too tall and somewhat long that will fit nicely with the main page title. (The Ankeny logo I use is about 300x130 pixels). If the logo is too tall or too long it messes with the page layout.

Copy that file to  directory:  *top-level-project-dir/kiosks/yourkioskname/www/images*

You will be using that file path in a moment.

##### 1.4 - Edit your kiosk.cfg file.

The contents of the github project's DEFAULT ***kiosk.cfg*** file are shown below.  You should not modify the DEFAULT kiosk's config file.

Instead, you should make and modify your own copy of this file which must reside your own custom kiosk's directory as described below.

In your own kiosk directory (e.g. *top-level-project-dir/kiosks/yourkioskname*) is a file called kiosk.cfg.  It contains the default set of key value pairs that do things like set the target motus receiver deployment using its Motus database ID.

Edit your ***kiosk.cfg*** file to contain your own site's ID, your banner logo file and title etc.  For many custom kiosks,  you may be able to just set the  'startup.cfg ' (above) and perhaps the first 3-5 elements of the kiosk.cfg to get your kiosk up and running and looking like its your very own site.     

Below is the content of an entire sample configuration file for version Version 6.0.  Each element is described in the '2.0 Configurable Items' section that follows below.

```
# See CONFIGURATION_GUIDE.md for details.

AdminContact="schramm.r@gmail.com"
ReceiverDeploymentID=9195,11721,10758
ReceiverShortName="Ankeny Hill OR","Finley Wildlife Refuge", "Newport OR (HMSC)"
MainLogoFile="images/logos/ankenyhill_logo_hires_cropped.jpg"
MainLogoHeight=100
CssFile="css/motus_kiosk_default.css"
NavbarBackgroundColor="#8FBC8F" 
NavbarTextColor="darkslategray"
TitlebarTextColor="#8FBC8F"
TitlebarBackgroundColor="#fefefe"
TitlebarBackgroundGradientColor="#fefefe"
BodyPageTextColor="darkslategray"
BodyPageBackgroundColor="#fefefe"
SelectedTabTextColor="darkslategray"
SelectedTabBackgroundColor="#fefefe"
JumpToButtonColor="#f9f46d"
AppOpensToMap=0
MainTitleEnglish="Motus Receiver at:"
MainTitleSpanish="Receptor Motus en:"
MainTitleFrench="Récepteur Motus à:"
HomepageEnglish="homepages/default_homepage_en.html"
MovingMarkerIcon="images/icons/motus-bird.png"
MovingMarkerIconWidth=22
MovingMarkerIconHeight=22
InactivityTimeoutSeconds=300
EnableReadCache=1
EnableWriteCache=1
CachePath="data/cache"
ActiveCacheAgeLimitMinutes=120
InactiveCacheAgeLimitMinutes=10080
RebuildCacheDelaySeconds=10
RebuildCacheDepth=5
CheckMotusIntervalMinutes=1
HttpGetTimeoutSeconds=10
LogLevel=LOG_LEVEL_WARNING
EnableLearnAboutMotusTab=1
AboutMotusPageEnglish="aboutmotuspages/MOTUS_infographic_final_en.png"
EnableMotusNewsTab=1
NewsPageEnglish="newspages/current_news_en.html"
EnableSpeciesInfoTab=1
SpeciesPageEnglish="speciespages/species_unknown_en.html"
EnableSuspectDetectionFilter=0
VelocitySuspectMetersPerSecond=55
MapIconFlightDurationSeconds=3
ApiKey_1="none"
ApiKey_2="none"
```



### 2.0 - Configurable Items

##### 2.1 - Administrator Contact and ApiKeys

The AdminContact parameter is now required so that Motus.org can know who to contact if the Kiosk app is causing any concerns. Please use the correct email, or name and phone number of whoever is responsible for the kiosk within your organization.  *Note that the surrounding quotes are important* 

```
AdminContact="youremail@somewhere.org"
ApiKey_1="none"
ApiKey_2="none"
```

ApiKey_1 and ApiKey_2 are new for version 6.2.2.  They currently do nothing. They are there in preparation of Motus.org requiring some kind of authentication.

**2.2 - Receivers** 

You can configure your kiosk for browsing a single or multiple receivers. Below shows the configuration settings for a single receiver followed by a sample configuration for multiple receivers.

***Note that your are setting two configuration parameters and there must be an exact one-to-one correspondence between the element lists.*** 

for a single receiver:

```
ReceiverDeploymentID=9195
ReceiverShortName="Ankeny Hill OR"
```

or for multiple receivers:

``` code
ReceiverDeploymentID=9195,7948,8691,7474,7950
ReceiverShortName="Ankeny Hill OR", "Bullards Bridge OR", "Nisqually Delta WA", "Oysterville WA", "Tokeland WA"
```

##### 2.3 - Titles and Navbar Settings

These setting control the apperance of the title bar and navigation banner. LogoHeight is to be determined by trial&error given the particular customized logo provided for the application. 

*Note the the color is entered in 'hex format'*  or one of the standard HTML/CSS color names. The color shown is Ankeney Hill Nature Center's green.

The MainLogoFile is relative to the "www" directory:  *top-level-project-dir/kiosks/yourkioskname/www*/



```
MainLogoFile="images/logos/ankenyhill_logo.png"
NavbarBackgroundColor="#8FBC8F"
NavbarTextColor="#8FBC8F"
TitlebarTextColor="#8FBC8F"
TitlebarBackgroundColor="white"
TitlebarBackgroundGradientColor="white"
MainLogoHeight=140
CssFile = "css/motus_kiosk_default.css"
MainTitleEnglish="Motus Receiver at:"
MainTitleSpanish="Receptor Motus en:"
MainTitleFrench="Récepteur Motus à:"
BodyPageTextColor="darkslategray"
BodyPageBackgroundColor="#fefefe"
SelectedTabTextColor="darkslategray"
SelectedTabBackgroundColor="#fefefe"
JumpToButtonColor="#f9f46d"
```

The JumpToButton parameter was added in version 6 to make it more obvious for the kiosk user on how to quickly get to the tag detection data .  The JumpToButtonColor sets the background color of that control.

TitlebarBackgroundGradientColor was added in version 6.2.3 and allows a smooth gradient of color from TitlebarBackgroundColor to TitlebarBackgroundGradientColor.  If ommited or the set to the same value as TitlebarBackgroundColor then the backround color has a solid apperance as in prior versions.

##### 2.4 - "Home" tab content

The descriptive content that appears in the in the main page body when ever the "Home" tab is open comes from a language dependent .html file in the project sub-directory www/homepages.

```
HomepageEnglish="www/homepages/default_homepage_en.html"
```

There should be one file for each language that the application supports - currently: English, Spanish and French.  Only the english language page is entered in the kiosk.cfg file. 

Typically you will copy the default_homepage_en.html to something of your own choosing, then edit it for your site specific content.  Then come back here and change HomepageEnglish to point to your content (eg.  the AnkenyHill kiosk has homepage named ankeny_homepage_en.html)

Feel free to copy and edit the default pages provided. You can name the files what you like. Just make sure to set the filenames match except for the tag  _en, _es , _fr for the English, Spanish and French versions.

Edit these files carefully with an html editor or a text editor of your choice.

***IMPORTANT: *Someplace highly visible in your kiosk you must give proper credit to the Motus folks and Birds Canada and should include a statement regarding Acceptable Use***.* I have chosen to put that statement in the section "Credits" on the "Home" screen.

##### 2.5 - Moving Marker

These parameters set the icon and size of the marker the follows the flightpath of a bird on the leaflet map tab.

The additional parameter "MapIconFlightDurationSecond" controls the time the MovingMarkerIcon takes to travel the tagged animals flightpath over the map. 

The MovingMarkerIcon is relative to the "www" directory:  *top-level-project-dir/kiosks/yourkioskname/www*/

```
MovingMarkerIcon="images/icons/motus-bird.png"
MovingMarkerIconWidth=22
MovingMarkerIconHeight=22
MapIconFlightDurationSeconds=3
```

##### 2.6 - Inactivity Timeout

This parameter controls a timeout for inactivity of the user  interface.  If there is no touchscreen/mouse activity for the set period, the application will reset to the home screen and defaults.    (see also 2.14 AppOpensToMap)

```
InactivityTimeoutSeconds=3600
```

##### 2.7 - Cache Settings

These parameters control use of a local data storage cache. Caching is a way to improve user interface responsiveness and to reduce unnecessary data request calls out to motus.org. 

- Setting EnableReadCache=1 will cause application data requests to first return use any cached data it finds that meets the aging criteria. 
-  If cache is enabled for read it is used in two modes.

1) ActiveCache can be set to expire after a breif period. i.e. if you dont expect motus.org data to update more than once a day, you might set the active cache to expire after several hours. 
1) InactiveCache uses the same cached data files, but allows for a much longer timeout. The idea here is if  networking is lost, or if motus.org is unavailable due to maintenance etc. you may still want the application to show cached data even if it is much older (days or weeks?)

```
EnableReadCache=1
EnableWriteCache=1
CachePath="data/cache"
ActiveCacheAgeLimitMinutes=60
InactiveCacheAgeLimitMinutes=10080
RebuildCacheDelaySeconds=10
RebuildCacheDepth=5
```

CachePath is relative to your kiosk directory:  e.g  *top-level-project-dir/kiosks/yourkioskname/*

Setting EnableWriteCache=1 causes any successful HTTP request for data from Motus.org to be written to the data cache on the local file system.  

*NOTE: If you are pushing your app to a web hosting service such as shinyapps.io, the local file system is not available for writing.  In this case files in the cache system when the app was last pushed to the service are available, but since the web users sessions are restarted frequently, new data would not persist.  In these cases it is advisable to set EnableWriteCache=0 and possibly set the InActiveCacheAgeLimit to a higher number*   

If your kiosk was set up to run the BuildCache script nightly then the RebuildCacheDelaySeconds=10 and RebuildCacheDepth=5 configure that script.  This script can negatively impact the servers at Motus.org so limiting these parameters to small numbers keeps that impact negligable.  The delay is the number of seconds between each http request to the server.  The depth parameter is how many unique, most recent tag detections should be pre-fetched for each receiver.

##### 2.8 - Motus.org Response Timeout

This parameter controls the timeout waiting for a response to a motus.org data query.  Occasionally Motus.org may be down for maintenance etc or otherwise unreachable on the network. Rather than just hanging the user interface, this timeout will cancel the request and return control back to the user

```
HttpGetTimeoutSeconds=10
```

##### 2.9 - Check Motus Interval

This parameter controls the the period that the app will make a small data query to motus.org just to test connectivity. This is mostly a debugging tool, the status gets displayed on the homepage footer in the lower right corner.

```
CheckMotusIntervalMinutes=1
```

##### 2.10 - LogLevel

```
LogLevel=LOG_LEVEL_INFO
```

This parameter controls the level of messages written to the console or log file.  There is an order to the severity of messages in the system.  eg if the level is WARNING, only WARNING, ERROR and FATAL messages are written. 

The log level must must be one of :

```
LOG_LEVEL_DEBUG
LOG_LEVEL_INFO
LOG_LEVEL_WARNING
LOG_LEVEL_ERROR
LOG_LEVEL_FATAL
LOG_LEVEL_NONE
```

##### 2.11 - "LearnAboutMotus" tab content

The content about what the motus system is that appears in the in the main page body when ever the "LearnAboutMotus" tab is open comes from a language dependent image file in the project sub-directory www/aboutmotuspages.

```
EnableLearnAboutMotusTab=1
AboutMotusPageEnglish="aboutmotuspages/MOTUS_infographic_final_en.png"
```

There should be one file for each language that the application supports - currently: English, Spanish and French.  Only the english language page is entered in the kiosk.cfg file. 

##### 2.12 - "MotusNews" tab content

Optional short special interest stories you write about any motus activity at your site can appear in the main page body when ever the "MotusNews!" tab is open. It comes from a language dependent html file you create in the project sub-directory www/aboutmotuspages.

```
EnableMotusNewsTab=1
NewsPageEnglish="newspages/current_news_en.html"
```

There should be one file for each language that the application supports - currently: English, Spanish and French.  Only the english language page is entered in the kiosk.cfg file. 

##### 2.13 - "Species" tab content

There is an optional "Species" tab on the ReceiverDetections panel.  You can create and link to species specific content that your users can view when selecting any detectected bird.  It comes from  language dependent html files that you create in the project sub-directory www/speciespages. A few species pages are already written for you to use as templates. If a species is detected that has no content written for it then the default is displayed. (see also:
START_HERE.md  Section 12.0 - Configure your own "Species" tab content)

```
EnableSpeciesInfoTab=1
SpeciesPageEnglish="speciespages/species_unknown_en.html"
```

There should be one file for each language that the application supports - currently: English, Spanish and French.  Only the english language page is entered in the kiosk.cfg file. 

***WARNING:  when creating species page content, it is your responsibility to be sure you have legal permission to use all images, maps and text you incorporate. Be sure to give proper credit for anything you use. Most content taken from the web is protected by copyright or other terms of use. If you cant find and document a clear statement that you have the permission to use - don't use it.***  

##### 2.14 - Suspect Detections Filter

Starting with MOTUS_KIOSK Version 5.1.0  I have introduced an experimental attempt at filtering wild point "suspect" detection data. This feature can be turned on by setting the kiosk.cfg parameter EnableSuspectDetectionFilter to 1.  Enabling this feature currently places a checkbox on the ReceiverDetections panel so the user can toggle it on and off to see the filter effect. Disabling this feature hides the checkbox and bypasses all filtering logic.  

Another kiosk.cfg parameter "VelocitySuspectMetersPerSecond" parameter is currently used as the upper limit to bird's horizontal flight velocity.

```
EnableSuspectDetectionFilter=1
VelocitySuspectMetersPerSecond=55
```

Currently the algorithm is very unsophisticated and will hopefully be subject to improvements in future releases.    



##### 2.15 - Application Opens to Map

Starting with MOTUS_KIOSK Version 6.0.0  I have added a feature that allows you to choose if the application opens to the homepage or to the recievers tag flight map.

```
AppOpensToMap=0
```

When set to 1, the app opens to the flight map of the most recent detection of the currently selected receiver.  This happens on start and also on session reload whenever the InactivityTimeoutSeconds is reached (see 2.5).
