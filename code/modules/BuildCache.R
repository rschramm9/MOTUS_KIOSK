#########################################################
# R to build a complete cache for the receivers
# in that are in the kiosk config
# Usage:
# 1) assuming you are in the RStudio kiosk project home directory
#    and have successfully run the kiosk app project with a
#    properly config file
# 2) assuming you already have a data/cache directory
# 3) open this file in the RStudio IDE and have it 'selected' on the files tab bar
# 4) click the 'source' button
#########################################################
# can be a LOT of hits to motus.org data servlets
# so I set a 'be_nice' delay between each call out so they
# dont think they are being slammed....
#########################################################
library(shiny)
library(rvest)  #for  web scraping
library(tidyr) #for  web scraping

### read URLs with timeouts
library(httr)

###### read configuration key/value pairs
library(data.table)

library(tictoc)

library(fs)
library(dplyr)

LOG_LEVEL_DEBUG=5  #print debug messages
LOG_LEVEL_INFO=4 #print info messages
LOG_LEVEL_WARNING=3 #print warning messages
LOG_LEVEL_ERROR=2
LOG_LEVEL_FATAL=1
LOG_LEVEL_NONE=0
LOG_LEVEL = LOG_LEVEL_INFO #set an inital log level, after we read the config file we will overide this

## RStudio assumes .R code to be in the top level project directory.
## I keep it in a sub-directory named 'code' to keep it clearly separate.
## So this is a hack to test the working directory - if its the code subdir, then
## change fix it to the project top level dir, and assign it to a global
## variable 'projectdir'. Also set variable codedir a a subdir so we can
## source the necessary modules etc.

begin_usec  <- as.numeric(Sys.time())
begin_datetime <- Sys.time()
print(paste0("BuildCache V2 STARTED AT:",begin_datetime))

gblUserAgentText <- "MOTUS_KIOSK vsn 6.2.1"

wd <- getwd()
print(paste0("BuildCache.R getwd():", wd))

if( grepl('/code$', wd)){
  message(paste0("modifying working directory"))
  setwd("../")
  wd<-getwd()
}

projectdir <<- wd
codedir <<- paste0( projectdir,"/code")

print(paste0("projectdir is:", projectdir))
print(paste0("codedir is:", codedir))

# Add individual modules here
source(paste0(codedir,"/modules/configUtils.R"))
source(paste0(codedir,"/modules/utility_functions.R"))
source(paste0(codedir,"/modules/ReceiverDetections.R"))
source(paste0(codedir,"/modules/tagInfo.R"))      
source(paste0(codedir,"/modules/tagDeploymentDetails.R"))          #tagDeploymentDetails
source(paste0(codedir,"/modules/tagDeploymentDetections.R"))       #the flightpath
source(paste0(codedir,"/modules/receiverDeploymentDetections.R"))  #whats been at our receiver
source(paste0(codedir,"/modules/receiverDeploymentDetails.R"))
source(paste0(codedir,"/modules/tagTrack.R"))  


LOG_LEVEL<<-4 #WARNING

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

gblUserAgentText <- paste0(gblUserAgentText, ", KioskID:",config.StartKiosk, " Contact:", config.AdminContact) 
message(paste0("UserAgent:", gblUserAgentText))

#printConfig()

#print("-----------------Done processing config----------------------------------")

#set your desired log level in your config file ## I WILL OVERIDE THEI DOWN BELOW
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

#Overide the log level set in the users kiosk.cfg file
LOG_LEVEL<<-LOG_LEVEL_INFO

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


# construct data frame to support the available receivers picklist
# the shortnames list contains the visible choices on the dropdown
# here we make a dataframe from the shortnames and the deployment ids, later we
# use the reactive picklist choice to filter the dataframe to get the desired deployment id
gblReceivers_df <<- data.frame(unlist(config.ReceiverShortNames),unlist(config.ReceiverDeployments))
#to name the columns we use names() function
names(gblReceivers_df) = c("shortName","receiverDeploymentID")
#print(gblReceivers_df)


     ##################################################
     # code below here will completely rebuild cache
     # WARNING - For many receivers... this will take awhile and also
     # hits the motus.org server many times....
     ##################################################

     #be_nice <- 7 #seconds between hitting motus.org data server
     #num_tags <- 6 # how many most recent unique tags to process for each receiver
     
     be_nice <- config.RebuildCacheDelaySeconds #seconds between hitting motus.org data server
     num_tags <- config.RebuildCacheDepth # how many most recent unique detected tags to process for each receiver

     if (1==1){ #rebuild cache
         for (i in 1:nrow(gblReceivers_df)) {  #for each receiver
         #### for (i in 1:1) {  #for only the first receiver
         
         row <- gblReceivers_df[i,]
         site=row[[1]]
         id=row[["receiverDeploymentID"]]
         print(paste0("***************************************************************************"))
         print(paste0("*********** Look for receiverDeploymentID:", id,"  site:", site, "*************"))
         print(paste0("***************************************************************************"))
         
         Sys.sleep(be_nice)
         
         tic("receiverDeploymentDetails")
         receiverDetails_df = receiverDeploymentDetails(id,useReadCache=0) #dont care about cache age
         ###str(receiverDetails_df)
         toc()
         

         #fetch all tag detections at this receiver 
         tic("receiverDeploymentDetections")
         data_df = receiverDeploymentDetections(id,useReadCache=0)
           
         #Parse date column (assumed yyyy-mm-dd format) --
         data_df$tagDetectionDate <- as.POSIXct(data_df$tagDetectionDate, format = "%Y-%m-%d")

         # -- Step 3: Keep only the most recent row per tagDeploymentID --
         unique_df <- data_df %>%
         group_by(tagDeploymentID) %>%
         slice_max(order_by = tagDetectionDate, n = 1, with_ties = FALSE) %>%
         ungroup()

         # -- Step 4: Select the top N most recent deployments --
         recent_df <- unique_df %>%
         arrange(desc(tagDetectionDate)) %>%
         slice_head(n = num_tags)
         
         # for each tag detection
         for(j in 1:nrow(recent_df)){
           
           row <- recent_df[j,]
           tagdepid=row[["tagDeploymentID"]]
           
#           print(paste0("***************************************************************************"))
#           print(paste0("****** 1) Look for tag details for tagid:",tagdepid))
#           print(paste0("***************************************************************************"))
#           Sys.sleep(be_nice)
#           tic("tagDeploymentDetails")
#           tagDetails_df = tagDeploymentDetails(tagdepid,useReadCache=0)
#           toc()
           
           print(paste0("***************************************************************************"))
           print(paste0("****** 2) look for detections for tagid:",tagdepid))
           print(paste0("***************************************************************************"))
           Sys.sleep(be_nice)
           #### THIS IS THE ONE THAT CAN TAKE A LONG TIME DUE TO THE JSON CALL #######
           tic("tagDeploymentDetections")
           tagflight_df <- tagDeploymentDetections(tagdepid, useReadCache=0)
           toc()
           
#           print(paste0("***************************************************************************"))
#           print(paste0("******* 3) look for taginfo for tagid:",tagdepid))
#           print(paste0("***************************************************************************"))
#           Sys.sleep(be_nice)
#           tic("tagInfo")
#           tagflight_df <- tagInfo(tagdepid, useReadCache=0)
#           toc()
   
         } #end for
         print(paste0("***************************************************************************"))
         print(paste0("***** Finished for receiverDeploymentID:", id ))
         print(paste0("***************************************************************************"))
       }
       
       print(paste0("***************************************************************************"))
       print("****** Finished processing all receivers.")
       print(paste0("***************************************************************************"))
       
       end_usec  <- as.numeric(Sys.time())
       end_datetime <- Sys.time()
       print(paste0("BuildCache V2 STARTED AT:",begin_datetime))
       print(paste0("BuildCache V2 ENDED AT:",end_datetime))
       print(paste0("BuildCache V2 ELAPSED MINUTES:", (end_usec - begin_usec)/60))
       
     } #endif 1==1
     
     