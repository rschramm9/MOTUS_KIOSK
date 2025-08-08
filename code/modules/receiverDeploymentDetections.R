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
################################################################################
# Purpose: function for getting all tag detections at receiver given
# the MOTUS reciever deployment ID.
# eg https://motus.org/data/receiverDeploymentDetections?id=7948
#
# Info: Build the URL and submit to motus. Process the returns to scrape
# the tag detections. Two passes are made thru the page: first to parse
# the basic table data and then for the tagDeploymentID that is embedded
# in the the "<a href" data
# 
#
# Returns an empty data frame if it cant process the results (see function
# empty_receiverdetection_df() (nrow=0, ncol=7)
#
################################################################################

# Loading library 
library(stringr)
library(xml2)

### FOR TESTING TIMOUTS
library(httr)

################################################################################
## create empty receiverDeploymentDetections data frame
## called within receiverDeploymentDetections() to return an
## empty data frame when that function has problems with
## what comes back from the motus server.
## WARNING: length and column names need to match exactly
## what is created by receiverDeploymentDetections()
################################################################################
empty_receiverDeploymentDetection_df <- function()
{
  df <- data.frame( matrix( ncol = 8, nrow = 1 ) )
  colnames(df) <- c('tagDetectionDate','tagID','tagDeploymentID','tagDeploymentName','species','tagDeploymentDate','lat','lon')
  df <- df %>% drop_na()
  return (df)
}

################################################################################
# Purpose: function for getting all tag detections at receiver given
# the MOTUS receiverDeployment ID.
# eg https://motus.org/data/receiverDeploymentDetections?id=7948
#
# Info: Build the URL and submit to motus. Process the returns to scrape
# the tag detections. Two passes are made thru the page: first to parse
# the basic table data and then for the tagDeploymentID that is embedded
# in the the "<a href" data
# 
# Returns an empty data frame if it cant process the results (see function
# empty_receiverdetection_df()
#
################################################################################
## display modal busy spinner if we go query motus ( ie no cached data)
receiverDeploymentDetections <- function(receiverDeploymentID, useReadCache=1, cacheAgeLimitMinutes=60, withSpinner=FALSE, spinnerText="Requesting data.") 
{
  
  #url <- paste( c('https://motus.org/data/receiverDeploymentDetections?id=7948') ,collapse="")
  #possible detections motus returns are limited to 100 by default
  #so we use the hidden &n argument: https://motus.org/data/receiverDeploymentDetections?id=',receiverDeploymentID,'&n=1000' 
  url <- paste( c('https://motus.org/data/receiverDeploymentDetections?id=', receiverDeploymentID,'&n=1000') ,collapse="")
  
  DebugPrint("********** Begin - start by testing cache ********")
  cacheFilename <- paste0(config.CachePath,"/receiverDeploymentDetections_",receiverDeploymentID,".Rda")
  df <-readCache(cacheFilename, useReadCache, cacheAgeLimitMinutes)   #see utility_functions.R
  
  if( is.data.frame(df)){
    DebugPrint("receiverDeploymentDetections returning cached file")
    return(df)
  } #else was NA
  
  #prepare an empty dataframe we can return if we encounter errors parsing query results
  onError_df <- empty_receiverDeploymentDetection_df()
  
  # we either already returned the valid cache df above and never reach this point,
  # or the cache system wasnt used or didnt return a cached dataframe,
  # so need to call the URL 
  
  InfoPrint(paste0("make call to motus.org using URL:",url))
  
  if(withSpinner){
     Sys.sleep(1.5) #to avoid flashing effect
     show_modal_spinner(
     spin="fading-circle",
     color = "#2f77eb",
     text = spinnerText
     )
  }
  
  
  result <- lapply(url, readUrlWithTimeout)   #see utility_functions.R
  
  if( is.na(result)){
    InfoPrint("readUrl() no results - returning empty df (is.na(result) ***")
    return(onError_df)
  }
  
  DebugPrint("begin scraping html results")
  page <- result[[1]]
  #print(class(page))
  
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
  ans=testPageTitlenodes(page, "Motus |")
  if (ans==TRUE) {
    WarningPrint("Motus redirected to Motus | homepage. Likely no receiver deployment found with ID. Returning empty df (Redirected) ")
    return(onError_df)
  }
  
  # next test for a redirect to legacy (pre-Apr 2025) motus HomePage 
  # eg. if called with an ID that doesnt exist,
  # motus.org may just redirect us to the motus.org home page. Here I test for the homepage title
  ans=testPageTitlenodes(page, "Motus Wildlife Tracking System")
  if (ans==TRUE) {
    WarningPrint("Motus redirected to legacy homepage. Likely no receiver deployment found with ID. Returning empty df (Redirected) ")
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
  #ans=testPageTitlenodes(page, "Detections - ")
  #if (ans==TRUE){
  #  DebugPrint("Motus responded with expected page title - continue testing response")
  #}
  
  DebugPrint("end initial html result testing")
  
  
  # *************************************************************
  
  # now extract the data table
  tbls <- page %>% html_nodes("table")
  
  #message(paste("class tbls:", class(tbls)))
  #str(tbls)
  
  len=length(tbls)
  #message(paste("length of list:", len))
    
  if (len <= 0) {
      WarningPrint("returning empty df (empty detections table found in results for this receiver)")
      return(onError_df)
  }
  
  tbl1 <- html_table(tbls[[1]],fill=TRUE)
  num.cols<-dim(tbl1)[2]
  num.rows<-dim(tbl1)[1]
  #print ("dim(tbl1):")
  #print(dim(tbl1))
  #print("numrows:")
  #print(num.rows)
  #print ("numcols:")
  #print(num.cols)
#  for(i in 1:num.rows){
#    print(paste0("------------ for row i:",i," --------------"))
#    print( tbl1[[1]][i] ) 
#    print( tbl1[[2]][i] )
#    print( tbl1[[3]][i]  )
#    print( tbl1[[4]][i] )
#    print( tbl1[[5]][i] )
#    print( tbl1[[6]][i] )
#  } # end for

  
  # create empty 'vectors'
  tagDetectionDate<-c()
  tagDeploymentName<-c()
  species<-c()
  tagDeploymentDate <-c()
  lat<-c()
  lon<-c()
  tagDeploymentID<-c()
  tagID<-c()
  
 
  #[1] "character"
  # table entries are all class "character"
  n <- 0
  

  # html results node may have a 'row' of sort controls as a 'table footer' 
  # if it is there, then the first column of the last row will be the
  # string 'Detection date'
  # We need the true number of detection records to process in the
  # for loop that follows
  hasFooter <- str_detect(toString( tbl1[[1]][num.rows]), "Detection date" )
  if(hasFooter == 1){
    nrecords <- num.rows -1
  } else {
    nrecords <- num.rows
  }
  
  #build six vectors from table data for text in each cell
  for(i in 1:nrecords){
    n <- n+1
    tagDetectionDate <- c( tagDetectionDate,  tbl1[[1]][i]  )
    tagDeploymentName <- c( tagDeploymentName,  tbl1[[2]][i] )
    species <- c(species, tbl1[[3]][i] )
    tagDeploymentDate <-c( tagDeploymentDate, tbl1[[4]][i] )
    lat <-  c( lat,  tbl1[[5]][i]  )
    lon <-  c( lon,  tbl1[[6]][i] )
    
    #extract tagID that appears at the very end of the tagDeploymentName
    #see: https://stackoverflow.com/questions/70665269/extract-numbers-that-appear-last-in-the-string
    s1<-tbl1[[2]][i]
    s2<-stringr::str_extract(s1, stringr::regex("(\\d+)(?!.*\\d)"))
    tid<-as.numeric(s2)
    
    #print(paste0("NameString:",s1, "   TagID:",tid))
    tagID <- c(tagID, tid)  #add tagID to vector
  }
  
  #convert things that are not meant to be strings to correct type
  tagDetectionDate <- as.Date(tagDetectionDate)
  tagDeploymentDate <- as.Date(tagDeploymentDate)
  lat <-  gsub("[^0-9.-]", "", lat)
  lat <- as.numeric(lat)
  lon <-  gsub("[^0-9.-]", "", lon)
  lon <- as.numeric(lon)
  
  # ----------------------------------------------------------
  # process the page a second time for the tagDeploymentID's that
  # are embedded in the anchor tag of the tagDeploymentName cells.
  # get all the table rows, with <a href=
  a_nodes <- page %>%
  html_nodes("table") %>% html_nodes("tr") %>% html_nodes("a") %>%
  html_attr("href") #as above
  
  #print(a_nodes)
  #print("length of a_nodes is:")
  #print (length(a_nodes))
  # loop through the table rows and extract the tagDeployment URL
  # that looks like:  "tagDeployment?id=36196"
  # parse it to extract the numeric tagDeploymentID
  # and append it to the list...
  n <- 0
  for (node in a_nodes) {
    ans <- str_detect( toString(node), "tagDeployment" )
    if(ans) {
      n <- n+1
      theID <- as.numeric( sub("\\D*(\\d+).*", "\\1", node) )
      tagDeploymentID<- c( tagDeploymentID, theID  )
      #cat("n:",n," length:", length(tagDeploymentID), "theId:",theID, "\n")
    }
  }
  #got them...
  #print(tagDeploymentID)
  #---------------------------------------------------------- 
  
  # build the final dataframe
  df <-data.frame(tagDetectionDate, tagID, tagDeploymentID,tagDeploymentName,species,tagDeploymentDate,lat,lon)
  #colnames(df) <- c('tagDetectionDate','tagDeploymentID','tagDeploymentName','species','tagDeploymentDate','lat','lon')
  
  
  #
  # First filter we filter out any tags to be ignored from ignore_by_tag.csv file read by global.R
  #
  if( length(gblIgnoreByTag_df > 0 )){
    for(i in 1:nrow(gblIgnoreByTag_df)) {
      row <- gblIgnoreByTag_df[i,]
      theTagID=row[["tagDeploymentID"]]
      df <- df[!(df$tagDeploymentID == theTagID),]
    }
  }
  
  #
  # Second, from remainder we filter out any tags 
  # to be ignored from ignore_by_tag_receiver.csv file read by global.R
  # ie all tagDeployments of tag with tagID if seen by this receiver
  if( length(gblIgnoreByTagReceiver_df > 0 )){
    for(i in 1:nrow(gblIgnoreByTagReceiver_df)) {
      row <- gblIgnoreByTagReceiver_df[i,]
      rID=row[[1]]
      tID=row[[2]]
      if(rID == receiverDeploymentID ){ 
        df <- df[!(df$tagID == tID),]
      }
    }
  }

  #delete records with nulls
  df <- df %>% drop_na()
  #print(df)
  
  if(config.EnableWriteCache == 1){
    DebugPrint("receiverDeploymentDetections writing new cache file.")
     saveRDS(df,file=cacheFilename)
  }
 
  DebugPrint("receiverDeploymentDetections done.")
  return(df)
  
}
