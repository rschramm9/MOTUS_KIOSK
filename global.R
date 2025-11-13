######## I put github release version and other data here ############
######## so it can be displayed on the footer of the kiosk window ####
gblFooterText <- "MOTUS_KIOSK vsn 6.2.4  10-Nov-2025"
gblUserAgentText <- "MOTUS_KIOSK vsn 6.2.4"
mytoggle<<-FALSE #useful global variable for debugging
###############################################################################
# Copyright 2022-2023 Richard Schramm
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# #
# **************************************************************************************
# ****  IN ADDITION - BY DOWNLOADING AND USING THIS SOFTWARE YOU ARE AGREEING TO: ******
# 1) Properly maintain citation and credit for the use of Motus data access tools courtesy
# of Bird Studies Canada. 2015. Motus Wildlife Tracking System. Port Rowan, Ontario.
# Available: http://www.motus-wts.org. 
# Citation: Birds Canada (2022). motus: Fetch and use data from the Motus Wildlife Tracking
# System. https://motusWTS.github.io/motus. 
# 
# 2) Any use or publication of the data presented through this application or its functions
# must conform to the terms of the Motus Collaboration Policy at https://motus.org/policy/
# and ensure proper recognition of Motus, Birds Canada, Motus researchers and projects.
# ***************************************************************************************
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################

# This app's structure utilizes techniques for creating a multilanguage
# modularized app as described by Eduard Parsadanyan in his article at: 
# https://www.linkedin.com/pulse/multilanguage-shiny-app-advanced-cases-eduard-parsadanyan/
# and was learned via exploring his ClinRTools modularized demo found at:
# https://bitbucket.org/statsconsult/clinrtoolsdemo/src/master/

# This app uses the shiny.i18n package to perform language translations
# shiny.i18n package is Copyright Copyright (c) 2023 Appsilon Sp. z o.o.
# and distributed under MIT license. see:https://github.com/Appsilon/shiny.i18n
# Citation: Nowicki J, Krzemiński D, Igras K, Sobolewski J (2023).
# shiny.i18n: Shiny Applications Internationalization.
# https://appsilon.github.io/shiny.i18n/, https://github.com/Appsilon/shiny.i18n.

# Globals: libraries, modules etc.

library(shiny)

library(shinymeta)
library(shinyjs)
library(shiny.i18n)

library(shinyWidgets)   # for pickerInput Widget flag thing

library(rvest)  #for  web scraping
library(tidyr) #for  web scraping

### read URLs with timeouts
library(httr)

library(units)

#### for leaflet map
library(leaflet)
library(leaflet.extras2) #for movingmarker
# movingmarkers needs flight_ df converted f to a 'simple features dataframe'
#using the coordinate reference system with columns: time,geometry

library(sf) #for making flightpath for movingmarker

### glue for building leaflet labels
library(glue)
library(lubridate) # for working with dates
library(tidyverse)
library(fs) #for path_home()

library(shinybusy) #for modal spinner displayed when busy

options(stringsAsFactors = FALSE)

default_UI_lang <- "en"

LOG_LEVEL_DEBUG=5  #print debug messages
LOG_LEVEL_INFO=4 #print info messages
LOG_LEVEL_WARNING=3 #print warning messages
LOG_LEVEL_ERROR=2
LOG_LEVEL_FATAL=1
LOG_LEVEL_NONE=0

LOG_LEVEL<-LOG_LEVEL_INFO #set an inital log level, after we read the config file we will overide this

###### read configuration key/value pairs
library(data.table)

## RStudio assumes .R code to be in the top level project directory.
## I keep it in a sub-directory named 'code' to keep it clearly separate.
## So this is a hack to test the working directory - if its the code subdir, then
## change fix it to the project top level dir, and assign it to a global
## variable 'projectdir'. Also set variable codedir a a subdir so we can
## source the necessary modules etc.

wd <- getwd()
message(paste0("getwd():", wd))

if( grepl('/code$', wd)){
  message(paste0("modifying working directory"))
  setwd("../")
  wd<-getwd()
}

projectdir <<- wd
codedir <<- paste0( projectdir,"/code")

message(paste0("projectdir is:", projectdir))
message(paste0("codedir is:", codedir))

# Add individual modules here
source(paste0(codedir,"/modules/configUtils.R"))
source(paste0(codedir,"/modules/utility_functions.R"))
source(paste0(codedir,"/modules/ReceiverDetections.R"))
source(paste0(codedir,"/modules/tagInfo.R"))
source(paste0(codedir,"/modules/pingMotus.R"))  
source(paste0(codedir,"/modules/tagDeploymentDetails.R"))          #tagDeploymentDetails
source(paste0(codedir,"/modules/tagDeploymentDetections.R"))       #the flightpath
source(paste0(codedir,"/modules/receiverDeploymentDetections.R"))  #whats been at our receiver
source(paste0(codedir,"/modules/receiverDeploymentDetails.R"))
source(paste0(codedir,"/modules/tagTrack.R"))  
source(paste0(codedir,"/modules/AboutMotus.R"))
source(paste0(codedir,"/modules/MotusNews.R"))  

     #read the startup configuration file (see configUtils.R)
     # to find which kiosk
     badCfg = getStartConfig()
     #halt if config processing didn't finish cleanly
     if( badCfg == TRUE){
       FatalPrint("There is a fatal error in your startup.cfg file")
       stop("Stopping because there is a serious error in your cfg file")
     }
    
     #message(paste0("Starting Kiosk named:", config.StartKiosk))
     InfoPrint(paste0("[global.R] Starting Kiosk named:", config.StartKiosk))
     badCfg<-getKioskConfig()
     if( badCfg == TRUE){
         FatalPrint("There is a fatal error in your kiosk.cfg file")
         stop("Stopping because there is a serious error in your cfg file")
     }

     ####printConfig()
     gblUserAgentText <- paste0(gblUserAgentText, ", KioskID:",config.StartKiosk, " Contact:", config.AdminContact) 
     message(paste0("UserAgent:", gblUserAgentText))
     
     
     
     #print("-----------------Done processing config----------------------------------")
     #set your desired log level in your config file
     #convert the string from config file to numeric constant from above
     LOG_LEVEL=switch(
       config.LogLevel,
       "LOG_LEVEL_DEBUG"=LOG_LEVEL_DEBUG,
       "LOG_LEVEL_INFO"=LOG_LEVEL_INFO,
       "LOG_LEVEL_WARNING"=LOG_LEVEL_WARNING,
       "LOG_LEVEL_ERROR"=LOG_LEVEL_ERROR,
       "LOG_LEVEL_FATAL"=LOG_LEVEL_FATAL,
       "LOG_LEVEL_NONE"=LOG_LEVEL_NONE,
     )
     
     #message(paste0("in global.R, config.SiteSpecificContent is:", config.SiteSpecificContent))
     
     # ambiguois detections
     # read a csv file for any bad or tags by tagDeploymentID. we want the gui to
     # ignore. Any receiver detection of a tag with matching TagDeploymentID
     # would have all detections of this tag at ANY receiver ignored
     # eg for a 'test tag' used a site where we dont want to show the public user
     # our test data.
     # these are filtered in receiverDeploymentDetections.R
     thefile<-paste0(config.SiteSpecificContent,"/data/ignoredetections/ignore_by_tag_receiver.csv")
     gblIgnoreByTagReceiver_df <<- ReadCsvToDataframe(thefile)
     if( is.null(gblIgnoreByTagReceiver_df) ) {
       ErrorPrint(paste0("Read of csv file returned NULL. File:",thefile))
     } else {
       #message("loaded FIRST csv file")
     }
    
     
     # ------------------------------------------------------------------------
     # Test tags - by tagDeploymentID
     # Ignore a tag when seen ANYWHERE .eg "test tags"
     # read a csv file for any bad or test tags by tagDeploymentID 
     # we want the gui to ignore ANY receiver detection of a tag with
     # matching a tagDeploymentID
     # these are filtered in receiverDeploymentDetections.R and in ReceiverDetections.R
     thefile<-paste0(config.SiteSpecificContent,"/data/ignoredetections/ignore_by_tag.csv") 
     #message(paste0("attempting to load ignore file:",thefile))
     gblIgnoreByTag_df <<- ReadCsvToDataframe(thefile)
     if( is.null(gblIgnoreByTag_df) ) {
       ErrorPrint(paste0("Read of csv file returned NULL. File:",thefile))
     } else {
       #message("loaded SECOND csv file")
     }
     
     # ------------------------------------------------------------------------
     # Wildpoints - by tag, receiver and date
     # read a csv file for any known bad tag detections at some receiver that we want the gui to ignore
     # these are individual detections of a tag at some receiver - eg wild point where the animal 
     # flies across the continent in a day = a false detections that motus hasnt filtered
     
     thefile<-paste0(config.SiteSpecificContent,"/data/ignoredetections/ignore_by_tag_receiver_date.csv") 
     # message(paste0("attempting to load file:",thefile))
     gblIgnoreByTagReceiverDate_df <<- ReadCsvToDataframe(thefile)
     if( is.null(gblIgnoreByTagReceiverDate_df) ) {
       ErrorPrint(paste0("Read of csv file returned NULL. File:",thefile))
     } else {
       #message("loaded THIRD csv file")
     }
     
     # ------------------------------------------------------------------------
     # Bad Receiver 
     # read a csv file for any known bad receiver that we want the gui to ignore
     # these are all detections of ANY tags at receiver - eg a known very noisy receiver
     thefile<-paste0(config.SiteSpecificContent,"/data/ignoredetections/ignore_by_receiver.csv") 
     #message(paste0("attempting to load file:",thefile))
     gblIgnoreByReceiver_df <<- ReadCsvToDataframe(thefile)
     if( is.null( gblIgnoreByReceiver_df) ) {
       ErrorPrint(paste0("Read of csv file returned NULL. File:",thefile))
     } else {
       #message("loaded Forth csv file")
     }

     #set some resource paths 
     
     # Generally about resourcePaths....
     # we need to add the directory containing the files as a resourcePath
     # so shiny can find the files.
     # The resourcePath is taken starting from the project top level working
     # directory. (typ. MOTUS_KIOSK)
     # We then form the kiosk's www relative path plus the target subdirectory
     # (the aboutmotuspages subdir)  Which we shall call here "therealdir"
     # This forms the true full 'project relative' path to the directory holding
     # the resource images.
     # Typically the "filename" we are going to pass to renderUI will be like
     # "virtualdirname/somefile.png" where vituradirname can be most anything
     # (though most often it will match the actual physical subdir name)
     # It is important that whatever the virtualdirnam is it MUST match the
     # prefix assigned in the addResourcePath call as in:
     #    addResourcePath(prefix="thevirtualdir", directoryPath=therealdir)
     # In practice as coded below, I set the thevirtualdir to be the same as 
     # the physical subdirectory (aboutmotuspages) but it is important to 
     # know that it is both the virtual prefix and the physical subdir.
     
     # resource path so that ui.R can find the kiosk-specifc.css file
     s = paste0(config.SiteSpecificContentWWW,"/css")
     addResourcePath("css", s)
     
     #moved from server.R
     s = paste0(config.SiteSpecificContentWWW,"/homepages/homepage_images")
     #message(paste0("setting homepage resource path:",s))
     addResourcePath("homepage_images", s)

     #moved from AboutMotus
     therealdir<-paste0(config.SiteSpecificContentWWW,"/aboutmotuspages")
     addResourcePath(prefix = "aboutmotuspages", directoryPath = therealdir)
     
     #moved from ReceiverDetections...
     s = paste0(config.SiteSpecificContentWWW,"/images/icons")
     addResourcePath("images/icons", s)
     
     s = paste0(config.SiteSpecificContentWWW,"/speciespages")
     addResourcePath("speciespages", s )
 
     # these appear to be not needed if resource path for speciespages is above
     # as of vsn 5.0.0
     #s = paste0(config.SiteSpecificContentWWW,"/speciespages/species_images")
     #addResourcePath("species_images", s)
     #s = paste0(config.SiteSpecificContentWWW,"/speciespages/species_css")
     #addResourcePath("species_css", s)
     

     s = paste0(config.SiteSpecificContentWWW,"/newspages")
     addResourcePath("newspages", s )
     # these appear to be not needed if resource path for newspages is above
     # as of vsn 5.0.0
     #s = paste0(config.SiteSpecificContentWWW,"/newspages/news_images")
     #addResourcePath("news_images", s)
     #s = paste0(config.SiteSpecificContentWWW,"/newspages/news_css")
     #addResourcePath("news_css", s)
     
     # www relative for images. logos and scripts
     s = paste0(config.SiteSpecificContentWWW,"/images/logos")
     addResourcePath("images/logos", s)
     s = paste0(config.SiteSpecificContentWWW,"/scripts")
     addResourcePath("scripts", s)
     
     #this works for flags
     s = paste0(config.SiteSpecificContentWWW,"/images/flags")
     addResourcePath("images/flags", s)
     
     # construct data frame to support the available receivers picklist
     # the shortnames list contains the visible choices on the dropdown
     # here we make a dataframe from the shortnames and the deployment ids, later we
     # use the reactive picklist choice to filter the dataframe to get the desired deployment id
     gblReceivers_df <<- data.frame(unlist(config.ReceiverShortNames),unlist(config.ReceiverDeployments))
     #to name the columns we use names() function
     names(gblReceivers_df) = c("shortName","receiverDeploymentID")
     config.ReceiverShortName<- toString(config.ReceiverShortNames[1])   #start with the first receiver on the list
     selectedreceiver <<- filter(gblReceivers_df, shortName == config.ReceiverShortName)
     
     # NOTE the use of global assignments
     gblReceiverDeploymentID <<- selectedreceiver["receiverDeploymentID"]
     InfoPrint(paste0("Start with receiver:", config.ReceiverShortName, "  ID:", gblReceiverDeploymentID))
 
     # for testing connection status to motus.org, I will always use this ID
     defaultReceiverID<<-gblReceiverDeploymentID 
       
     # Initially populate the dataframes here
     # dont allow a modal spinner as UI may not be 'up' yet
     
     # we want these to be global variables... (note the <<- ) 
     InfoPrint(paste0("global.R Make initial call to motus for receiverDeploymentDetections of receiver:", gblReceiverDeploymentID))
     

     #25Nov2024 Just populate an empty df - disable the looping otherwise the app
     #would hang in the loop if restarted while motus was offline and it wasnt
     #obvious to the kiosk user what was happening
     detections_df <<-empty_receiverDeploymentDetection_df()
     
     detections_subset_df<<-detections_df[c("tagDetectionDate", "tagDeploymentID","species" )]

     ## WARNING: below is javascript NOT R code !
     
     ## javascript idleTimer to reset gui when its been inactive 
     ## see also server.R  observeEvent(input$timeOut)
     #numInactivityTimeoutSecond <- 30 #seconds
     inactivity <- sprintf("function idleTimer() {
     var t = setTimeout(resetMe, %s);
     window.onmousemove = resetTimer; // catches mouse movements
     window.onmousedown = resetTimer; // catches mouse movements
     window.onclick = resetTimer;     // catches mouse clicks
     window.onscroll = resetTimer;    // catches scrolling
     window.onkeypress = resetTimer;  //catches keyboard actions

     function resetMe() {
       Shiny.setInputValue('timeOut', '%ss')
     }

     function resetTimer() {
       clearTimeout(t);
       t = setTimeout(resetMe, %s);  // time is in milliseconds (1000 is 1 second)
     }
   }

   idleTimer();", config.InactivityTimeoutSeconds*1000, config.InactivityTimeoutSeconds, config.InactivityTimeoutSeconds*1000)


    
    
