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
# Purpose: Used only to "ping"
# Motus periodically to see if its up.
# Uses the known receiverID fpr MOTUS receiver at Ankeny Hill Nature Center
# 
# eg:  https://motus.org/data/receiver?id=5382 
#
# Info: Build the URL and submit to motus. Process the returns to scrape
# the receiver info.  parse the basic html table data 
# 

#NEW RETURNS:
# TRUE if results as expected or FALSE for any error or timeout
#
################################################################################

# Loading library 
library(stringr)
library(xml2)

################################################################################
# TRUE if results as expected or FALSE
################################################################################
pingMotus <- function() 
{
  
  strUrl <- paste( c('https://motus.org/data/receiver?id=',5382) ,collapse="")
  
  # call the URL 
  DebugPrint(paste0("make call to motus.org using URL:",strUrl))
  result <- lapply(strUrl, readUrlWithTimeout, timeoutsecs=config.HttpGetTimeoutSeconds)   #see utility_functions.R
  
  if( is.na(result)){
    InfoPrint("readUrl() no results - returning empty df (is.na(result) ***")
    return(FALSE)
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
    return(FALSE)
  }
  
  # next test for a redirect to motus HomePage 
  # eg. if called with an ID that doesnt exist,
  # motus.org may just redirect us to the motus.org home page. Here I test for the homepage title
  ans=testPageTitlenodes(page, "Motus |")
  if (ans==TRUE) {
    WarningPrint("Motus redirected to homepage. Likely no receiver found with ID. Returning empty df (Redirected) ")
    return(FALSE)
  }
  
  # next test for a redirect to legacy (pre Apr 2025) motus HomePage 
  # eg. if called with an ID that doesnt exist,
  # motus.org may just redirect us to the motus.org home page. Here I test for the homepage title
  ans=testPageTitlenodes(page, "Motus Wildlife Tracking System")
  if (ans==TRUE) {
    WarningPrint("Motus redirected to homepage. Likely no receiver found with ID. Returning empty df (Redirected) ")
    return(FALSE)
  }
  
  #test page title was as expected
  ans=testPageTitlenodes(page, "- Receiver - Motus")
  
  #page_title <- page %>% html_node("title") %>% html_text()
  
  if (ans==TRUE){
    InfoPrint("Motus responded with expected page title ")
  } else {
    message("failed page title")
  }
  
  # we dont process anything else from the html results.... we just wanted to ping
  # motus and get the expected page returned
  
  DebugPrint("end html result testing")
  DebugPrint("pingMotus done.")
  
  return(ans)
  
}