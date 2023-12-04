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

# Add individual modules here
source("modules/configUtils.R")
source("modules/utility_functions.R")

source("modules/tagDeploymentDetails.R")      
source("modules/tagDeploymentDetections.R") 
source("modules/tagTrack.R")
source("modules/receiverDeploymentDetections.R")
source("modules/receiverDeploymentDetails.R")


LOG_LEVEL<<-4 #WARNING

badCfg = getConfig()
#halt if config processing didn't finish cleanly
if( badCfg == TRUE){
  FatalPrint("There is a fatal error in your cfg file")
  stop("Stopping because there is a serious error in your cfg file")
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
     # enable this code block to run to completely rebuild cache
     # WARNING - For many receivers... this will take awhile and also
     # hits the motus.org server many times....
     ##################################################

     be_nice<-1 #seconds between hitting motus.org data server

     if (1==1){ #rebuild cache
       for (i in 1:nrow(gblReceivers_df)) {
         
         row <- gblReceivers_df[i,]
         site=row[[1]]
         id=row[["receiverDeploymentID"]]
         print(paste0("look for id:", id,"  site:", site))
         
         Sys.sleep(be_nice)
         receiverDetails_df = receiverDeploymentDetails(id,useReadCache=0) #dont care about cache age
         str(receiverDetails_df)
         
         data = receiverDeploymentDetections(id,useReadCache=0)
         unique_df <- data[!duplicated(data$tagDeploymentID), ] # Extract unique rows
         for(j in 1:nrow(unique_df)){
           
           row <- unique_df[j,]
           tagdepid=row[["tagDeploymentID"]]
           print(paste0("look for details for tagid:",tagdepid))
           
           Sys.sleep(be_nice)
           tagDetails_df = tagDeploymentDetails(tagdepid,useReadCache=0)

           print(paste0("look for detections for tagid:",tagdepid))
           
           Sys.sleep(be_nice)
           tagflight_df <- tagDeploymentDetections(tagdepid, useReadCache=0)
   
         }
       }
     } #endif 1==1
     
     