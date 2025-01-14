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
print(paste0("BuildCache STARTED AT:",begin_datetime))

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

# read a csv file for any bad or tags by tagID we want the gui to
# ignore. any receiver detection of a tag with matching TagID
# would have all detections of this tag at the receiver ignored
# eg for a 'test tag' used a site where we dont want to show the public user
# our test data
thefile<-paste0(config.SiteSpecificContent,"/data/ignoredetections/ignore_tags.csv") 
message(paste0("attempting to load ignore file:",thefile))
gblIgnoreTag_df <<- ReadCsvToDataframe(thefile)
if( is.null(gblIgnoreTag_df) ) {
  #message("the FIRST csv file returned NULL")
} else {
  #message("loaded FIRST csv file")
}
#print(gblIgnoreTag_df) 

# read a csv file for any bad or tags by tagDeploymentID we want the gui to
# ignore. any receiver detection of a tag with matching tagDeploymentID
# would have all detections of this tag at the receiver ignored
# eg for a 'test tag' that may be redeployed later on an animal
# where we dont want to show the public user the test data
####f <- paste0(getwd(),"/data/ignore_tag_deployments",".csv")
####gblIgnoreTagDeployment_df <<- ReadCsvToDataframe(f)

thefile<-paste0(config.SiteSpecificContent,"/data/ignoredetections/ignore_tag_deployments.csv") 
#message(paste0("attempting to load file:",thefile))
gblIgnoreTagDeployment_df <<- ReadCsvToDataframe(thefile)
if( is.null(gblIgnoreTag_df) ) {
  # message("SECOND csv file returned NULL")
} else {
  # message("loaded SECOND csv file")
}
#print(gblIgnoreTagDeployment_df) 


# read a csv file for any known bad tag detections at some receiver that we want the gui to ignore
# these are individual detections of a tag at some receiver - eg wild point where the animal 
# flies across the continent in a day = a false detections that motus hasnt filtered
# this hack isnt scalable but for now....
thefile<-paste0(config.SiteSpecificContent,"/data/ignoredetections/ignore_date_tag_receiver_detections.csv") 

# message(paste0("attempting to load file:",thefile))
gblIgnoreDateTagReceiverDetections_df <<- ReadCsvToDataframe(thefile)
if( is.null(gblIgnoreTag_df) ) {
  #message("THIRD csv file returned NULL")
} else {
  #message("loaded THIRD csv file")
}
#print(gblIgnoreDateTagReceiverDetections_df) 


# read a csv file for any known bad receiver that we want the gui to ignore
# these are all detections of a tag at receiver - eg a known very noisy receiver
# this hack isnt scalable but for now...
thefile<-paste0(config.SiteSpecificContent,"/data/ignoredetections/ignore_all_detections_at_receiver.csv") 

# message(paste0("attempting to load file:",thefile))
gblIgnoreAllDetectionsAtReceiver_df <<- ReadCsvToDataframe(thefile)
if( is.null(gblIgnoreTag_df) ) {
  #message("FOURTH csv file returned NULL")
} else {
  #message("loaded Forth csv file")
}
#print(gblIgnoreAllDetectionsAtReceiver_df) 


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

     be_nice <- 1 #seconds between hitting motus.org data server

     if (1==1){ #rebuild cache
       for (i in 1:nrow(gblReceivers_df)) {  #for each receiver
         
         row <- gblReceivers_df[i,]
         site=row[[1]]
         id=row[["receiverDeploymentID"]]
         print(paste0("********** Look for receiverDeploymentID:", id,"  site:", site, "***********"))
         
         Sys.sleep(be_nice)
         
         tic("receiverDeploymentDetails")
         receiverDetails_df = receiverDeploymentDetails(id,useReadCache=0) #dont care about cache age
         ###str(receiverDetails_df)
         toc()
         
         tic("receiverDeploymentDetections")
         data = receiverDeploymentDetections(id,useReadCache=0)
         unique_df <- data[!duplicated(data$tagDeploymentID), ] # Extract unique rows
         toc()
         
         #for each 
         for(j in 1:nrow(unique_df)){
           
           row <- unique_df[j,]
           tagdepid=row[["tagDeploymentID"]]
           print(paste0("****** Look for tag details for tagid:",tagdepid))
           
           Sys.sleep(be_nice)
           tic("tagDeploymentDetails")
           tagDetails_df = tagDeploymentDetails(tagdepid,useReadCache=0)
           toc()

           print(paste0("look for detections for tagid:",tagdepid))
           
           Sys.sleep(be_nice)
           tic("tagDeploymentDetections")
           tagflight_df <- tagDeploymentDetections(tagdepid, useReadCache=0)
           toc()
           
           print(paste0("look for taginfo for tagid:",tagdepid))
           Sys.sleep(be_nice)
           tic("tagInfo")
           tagflight_df <- tagInfo(tagdepid, useReadCache=0)
           toc()
   
         }
         
         print(paste0("***** Finished receiverDeploymentID:", id ))
       }
       
       print("****** Finished processing all receivers.")
       
       end_usec  <- as.numeric(Sys.time())
       end_datetime <- Sys.time()
       print(paste0("BuildCache STARTED AT:",begin_datetime))
       print(paste0("BuildCache ENDED AT:",end_datetime))
       print(paste0("BuildCache ELAPSED MINUTES:", (end_usec - begin_usec)/60))
       
     } #endif 1==1
     
     