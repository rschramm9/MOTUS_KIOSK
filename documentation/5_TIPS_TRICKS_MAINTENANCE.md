# Tips, Tricks and Maintenance for Motus Kiosk

### For the MOTUS Nature Center Kiosk App v5.0.0

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

Each kiosk instance has three files in the MOTUS_KIOSK/kiosks/*kioskname*/data/ignoredetections folder.

For individual detections:  ignore_date_tag_receiver_detections.csv 

For a tag to ignore detections always (eg your test tags):  ignore_tags.csv

For a tag to ignore only for duration of one deployment (eg. if your tag was used for awhile but later deployed on an animal):  ignore_tag_deployments.csv

See the DEFAULT kiosk for examples.

### 4.0 - How to Cleanup Log Files

When running as a Windows locked down kiosk that is started at boot. - log messages get written to a file in the The app writes console messages to a log file in the MOTUS_KIOSK/kiosks/*kioskname*/logs folder.

Useful for debugging but may need a yearly cleanup to recover space

### 5.0 - How to Cleanup Data Cache

If a kiosk has its EnableWriteCache set to 1 (default) ,  recently retrieved detection data are stored in a local cache to reduce calls out to motus.org.  These can grow old and you may want to purge them after some period to recover space.   Each kiosk instance has its own data cache.  Cached files are in the MOTUS_KIOSK/kiosks/*kioskname*/data/cache folder. They all end in name .Rda  It is always completely safe to delete any or all of them.

