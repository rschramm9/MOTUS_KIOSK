###############################################################################
# Copyright 2022 Richard Schramm
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
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

################################################################################
# 25-Apr-2022
# 08-May-2022 Handles missing values- now missing vals are 'unknown'
#             instead of NA, so rows dont get deleted from dataframe
################################################################################
# Purpose: function for getting  receiver deployment details
# given the MOTUS receiver deployment ID.
# 
# eg:  https://motus.org/data/receiverDeployment?id=9195 
#
# Info: Build the URL and submit to motus. Process the returns to scrape
# the receiver info.  parse the basic html table data 
# 

#NEW RETURNS:
# 
# Returns the empty_df if deploymentId is not found (
# Or either a fresh or cached df 
#
################################################################################

# Loading library 
library(stringr)
library(xml2)

################################################################################
## create empty receiverDeploymentDetails data frame
## called within receiverDeploymentDetails() to return an
## empty data frame when that function has problems with
## what comes back from the motus server.
## WARNING: BOTH length AND column names need to match exactly
## what is created by receiverDeploymentDetails()
################################################################################

empty_receiverDeploymentDetails_df <- function()
{
  df <- data.frame( matrix( ncol = 4, nrow = 1) )
  colnames(df) <- c('receiverid','status','lat','lon')
  df <- df %>% drop_na()
  return (df)
}

################################################################################
# return a dataframe - either processed or empty if an error
################################################################################
receiverDeploymentDetails <- function(receiverDeploymentID, useReadCache=1, cacheAgeLimitMinutes=60) 
{
  strUrl <- paste( c('https://motus.org/data/receiverDeployment?id=',receiverDeploymentID) ,collapse="")    
  #url <- paste( c('https://motus.org/data/receiverDeployment?id=',9195) ,collapse="")

  DebugPrint("********** Begin - start by testing cache ********")
  cacheFilename <- paste0(config.CachePath,"/receiverDeploymentDetails_",receiverDeploymentID,".Rda")
  df <-readCache(cacheFilename, useReadCache, cacheAgeLimitMinutes)   #see utility_functions.R
  #df iwill be either the cached dataframe or NA
  if( is.data.frame(df)){
     DebugPrint("receiverDeploymentDetails returning cached file")
      return(df)
  } #else was NA
   
  #prepare an empty dataframe we can return if we encounter errors parsing query results
  onError_df <- empty_receiverDeploymentDetails_df()
  
  # we either already returned the valid cache df above and never reach this point,
  # or the cache system wasnt used or didnt return a cached dataframe,
  # so need to call the URL 

  DebugPrint(paste0("make call to motus.org using URL:",strUrl))
  
  result <- lapply(strUrl, readUrlWithTimeout, timeoutsecs=config.HttpGetTimeoutSeconds)   #see utility_functions.R

  if( is.na(result)){
      InfoPrint("readUrl() no results - returning empty df (is.na(result) ***")
      return(onError_df)
  }
  
  DebugPrint("begin scraping html results")
  
  #result is a list object, extract the html output and assign to 'page'
  page <- result[[1]]
  
  #first test if its an xml document
  ans<-is(page,"xml_document")
  if(ans==TRUE){ 
    DebugPrint("We got an xml document page")
  }else{
    DebugPrint("We dont have an xml document - returning onError df")
    return(onError_df)
  }
  
  # next test for a redirect to motus HomePage 
  # eg. if called with an ID that doesnt exist,
  # motus.org may just redirect us to the motus.org home page. Here I test for the homepage title
  ans=testPageTitlenodes(page, "Motus Wildlife Tracking System")
  if (ans==TRUE) {
    WarningPrint("Motus redirected to homepage. Likely no receiver deployment found with ID. Returning empty df (Redirected) ")
    return(onError_df)
  }
  
  # next check for any pnode containing:
  # for numeric id can get "No receiver deployment found" 
  # for non-numeric id can get "No receiver deployment found with ID")
  ans=testPagePnodes(page, "No receiver deployment")
  if (ans==TRUE) {
    WarningPrint("returning empty df (warning No receiver deployment found with ID)")
    return(onError_df)
  }
  
  ##if in future we care, implement this test
  ##next test page title was as expected
  #ans=testPageTitlenodes(page, "- Receiver deployment - Motus")
  #if (ans==TRUE){
  #  InfoPrint("Motus responded with expected page title - continue testing response")
  #}
   
  DebugPrint("end initial html result testing")
  
  
  # *************************************************************
  tbls <- page %>% html_nodes("table")
  
  tbl1 <- html_table(tbls[[1]],fill=TRUE)
  
  #DebugPrint("***** receiverDeploymentDetails  tbl1 ******")
  #print(class(tbl1))
  #print(tbl1)
  
  num.cols<-dim(tbl1)[2]
  num.rows<-dim(tbl1)[1]
  
  #print(dim(tbl1))
  
  status<- find4me(tbl1,"Current status:")
  #project <- find4me(tbl1,"Project:")
  #contact <- find4me(tbl1,"Project contact:")
  #started <- find4me(tbl1,"Deployment started:")
  #species <- find4me(tbl1,"Species:")
  #ndays <- find4me(tbl1,"Days detected:")
  #nreceivers <- find4me(tbl1,"Receivers detected by:")
  location <- find4me(tbl1,"Location:")
  
  #location is string like: "Lat.: 49.1225°, Lon.: -125.8867° (map)"
  #so we extract to variables lat and lon
  if( str_detect(toString(location), "unknown") ) {
    lat <- "unknown"
    lon <- "unknown"
    DebugPrint("location is unknown")
  } else {
    s <- str_extract_all(location,"\\(?[0-9,.-]+\\)?")[[1]]
    #print(s)
    # note.. turn off warnings about
    #  "introduced by coercion"
    warn = getOption("warn")
    options(warn=-1)
    latlon <- as.numeric(s)
    options(warn=warn)
    #print(latlon)
    lat <- latlon[2] 
    lon <- latlon[5]
  } #end else if location is unknown
  
  #create empty frame with one row of nulls
  df <- empty_receiverDeploymentDetails_df()
  #append a row with our values
  df[2, ]<- list(receiverDeploymentID , status, lat, lon )
  #finally, delete any rows with nulls
  df <- df %>% drop_na()
  
  if(config.EnableWriteCache==1){
     DebugPrint("writing new cache file.")
     saveRDS(df,file=cacheFilename)
  }
  
  DebugPrint("receiverDeploymentDetails done.")
  return(df)
  
}