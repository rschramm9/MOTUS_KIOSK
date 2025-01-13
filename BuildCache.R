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
source(paste0(codedir,"/modules/tagDeploymentDetails.R"))          #tagDeploymentDetails
source(paste0(codedir,"/modules/tagDeploymentDetections.R"))       #the flightpath
source(paste0(codedir,"/modules/receiverDeploymentDetections.R"))  #whats been at our receiver
source(paste0(codedir,"/modules/receiverDeploymentDetails.R"))
source(paste0(codedir,"/modules/tagTrack.R"))  


LOG_LEVEL<<-4 #WARNING

begin_datetime <- Sys.time()
print(paste0("BuildCache STARTED AT:",begin_datetime))

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


# construct data frame to support the available receivers picklist
# the shortnames list contains the visible choices on the dropdown
# here we make a dataframe from the shortnames and the deployment ids, later we
# use the reactive picklist choice to filter the dataframe to get the desired deployment id
gblReceivers_df <<- data.frame(unlist(config.ReceiverShortNames),unlist(config.ReceiverDeployments))
#to name the columns we use names() function
names(gblReceivers_df) = c("shortName","receiverDeploymentID")
#print(gblReceivers_df)

     ##################################################
     # enable this code block to run to completely rebuild cache
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
       begin_datetime <- Sys.time()
       print(paste0("BuildCache STARTED AT:",begin_datetime))
       end_datetime <- Sys.time()
       print(paste0("BuildCache ENDED AT:",end_datetime))
       
     } #endif 1==1
     
     