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
# 18-Jun-2024 Created - Descended from tagInfo 

################################################################################
# Purpose: function for getting all tag details,  specifically Im after the tag typ
# given the MOTUS tag ID.
# 
# eg: https://motus.org/data/tag?id=82338
#
# Info: Build the URL and submit to motus. Process the returns to scrape
# the tag details.  parse the basic table data 
# 
# Returns an empty data frame if it cant process the results (see function
# empty_tagInfo_df()
#
################################################################################

# Loading library 
library(stringr)
library(xml2)

################################################################################
## create empty tagInfo data frame
## called within tagInfo() to return an
## empty data frame when that function has problems with
## what comes back from the motus server.
## WARNING: BOTH length AND column names need to match exactly
## what is created by tagInfo()
################################################################################

empty_tagInfo_df <- function()
{
  df <- data.frame( matrix( ncol = 8, nrow = 1) )
  colnames(df) <- c('project','contact','manufacturer','manufacturerid','type','model','frequency','burstinterval')
  df <- df %>% drop_na()
  return (df)
}

################################################################################
#
################################################################################
tagInfo  <- function(tagID, useReadCache=1, cacheAgeLimitMinutes=60) 
{
  url <- paste( c('https://motus.org/data/tag?id=',tagID) ,collapse="")    
  # https://motus.org/data/tag?id=82338
  
  DebugPrint("********** Begin - start by testing cache ********")
  cacheFilename <- paste0(config.CachePath,"/tagInfo_",tagID,".Rda")
  
  df <-readCache(cacheFilename, useReadCache, cacheAgeLimitMinutes)   #see utility_functions.R
  
  if( is.data.frame(df)){
    DebugPrint("tagInfo returning cached file")
    return(df)
  } #else was NA
  
  #prepare an empty dataframe we can return if we encounter errors parsing query results
  onError_df <- empty_tagInfo_df()
  
  # we either already returned the valid cache df above and never reach this point,
  # or the cache system wasnt used or didnt return a cached dataframe,
  # so need to call the URL 
  
  InfoPrint(paste0("make call to motus.org using URL:",url))
  
  result <- lapply(url, readUrlWithTimeout)   #see utility_functions.R
  
  if( is.na(result)){
    DebugPrint("readUrl() no results - returning empty df (is.na(result) ***")
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
    WarningPrint(paste0("Motus redirected to homepage. Likely no tag deployment found with ID: ", tagID," Returning empty df (Redirected) "))
    return(onError_df)
  }
  
  
  # next check for any pnode containing:
  # for numeric id can get "No tag found" 
  # for non-numeric id can get "No tag found with ID")
  ans=testPagePnodes(page, "No tag")
  if (ans==TRUE) {
    WarningPrint("returning empty df (warning No tag found with ID)")
    return(onError_df)
  }
  
  ##if in future we care, implement this test
  ##next test page title was as expected
  #ans=testPageTitlenodes(page, "- Tag - Motus")
  #if (ans==TRUE){
  #  DebugPrint("Motus responded with expected page title - continue testing response")
  #}
  
  DebugPrint("end initial html result testing")
  
  # *************************************************************
  tbls <- page %>% html_nodes("table")
  
  tbl1 <- html_table(tbls[[1]],fill=TRUE)
  
  #DebugPrint("***** tagInfo  tbl1 ******")
  #print(class(tbl1))
  #print(tbl1)
  #num.cols<-dim(tbl1)[2]
  #num.rows<-dim(tbl1)[1]
  #print(dim(tbl1))

  project <- find4me(tbl1,"Project:")
  contact <- find4me(tbl1,"Project contact:")
  manufacturer <- find4me(tbl1,"Manufacturer:")
  manufacturersid <- find4me(tbl1,"Manufacturer's ID:")
  type <- find4me(tbl1,"Type:")
  model <- find4me(tbl1,"Model:")
  frequency <- find4me(tbl1,"Nominal frequency:")
  burstinterval <- find4me(tbl1,"Burst Interval:")

  #create empty frame with one row of nulls
  df <- empty_tagInfo_df()
  
  #append a row with our values
  df[2, ]<- list(project, contact, manufacturer,manufacturersid,type,model,frequency,burstinterval )
  #finally, delete any rows with nulls
  df <- df %>% drop_na()

  if(config.EnableWriteCache == 1){
    DebugPrint("tagInfo writing new cache file.")
      saveRDS(df,file=cacheFilename)
  }
  
  DebugPrint("tagInfo done.")

  return(df)
  
}