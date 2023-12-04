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
# 25-Apr-2022 Original
# 19-Jan-23  Added check for extra row caused by 'sort footer' in html results table
#            Also added second pass to extract the receiverDeploymentID from the
#            sitename "<a href" data
#20-Jan-2023 Process flightpath to remove excluded point from .scv file
#            that was read in global.R
################################################################################
# Purpose: function for getting all tag detections for any tag deployment
# given the MOTUS tag deployment ID.
# 
# eg:  https://motus.org/data/tagDeploymentDetections?id=32022
#
# returns daily 'summary' data which is basically the 'flight history' of a
# deployment of a tag using its tagDeploymentID

# Info: Build the URL and submit to motus. Process the returns to scrape
# the tag detections. Two passes are made thru the page: first to parse
# the basic table data and then to recover the receiverDeploymentID that
# is embedded in the the "<a href" data for the site name which is
# the returned 'ReceiverDeployment' column)
# 
# Returns an empty data frame if it cant process the results (see function
# empty_tagdetection_df()
#
################################################################################

# Loading library 
library(stringr)
library(xml2)

#see:https://stackoverflow.com/questions/1699046/for-each-row-in-an-r-dataframe
rows = function(x) lapply(seq_len(nrow(x)), function(i) lapply(x,"[",i))



################################################################################
## create empty tagDeploymentDetections data frame
## called within tagDeploymentDetections() to return an
## empty data frame when that function has problems with
## what comes back from the motus server.
## WARNING: length and column names need to match exactly
## what is created by tagDeploymentDetections()
################################################################################

empty_tagDeploymentDetection_df <- function()
{
  df <- data.frame( matrix( ncol = 7, nrow = 1) )
  df <- df %>% drop_na()
  colnames(df) <- c('date', 'site', 'lat', 'lon', 'receiverDeploymentID', 'seq', 'use')
  return (df)
}


################################################################################
#
################################################################################
tagDeploymentDetections <- function(tagDeploymentID, useReadCache=1, cacheAgeLimitMinutes=60) 
{

  #possible detections returns are limited to 100 by default
  #if so - might try https://motus.org/data/tagDeploymentDetections?id=',tagDeploymentID,'&n=1000' ?
  #where n is a hidden argument(see page source)
url <- paste( c('https://motus.org/data/tagDeploymentDetections?id=',tagDeploymentID,'&n=1000') ,collapse="")    
##url <- paste( c('https://motus.org/data/tagDeploymentDetections?id=',32025) ,collapse="")


cacheFilename = paste0(config.CachePath,"/tagDeploymentDetections_",tagDeploymentID,".Rda")


summaryFlight_df <-readCache(cacheFilename, useReadCache, cacheAgeLimitMinutes)   #see utility_functions.R

if( is.data.frame(summaryFlight_df)){
  DebugPrint("tagDeploymentDetections returning cached file")
  return(summaryFlight_df)
} #else was NA

#prepare an empty dataframe we can return if we encounter errors parsing query results
onError_df <- empty_tagDeploymentDetection_df()

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
  WarningPrint("Motus redirected to homepage. Likely no tag deployment found with ID. Returning empty df (Redirected) ")
  return(onError_df)
}

# next check for any pnode containing:
# for numeric id can get "No tag deployment found" 
# for non-numeric id can get "No tag deployment found with ID")
ans=testPagePnodes(page, "No tag deployment")
if (ans==TRUE) {
  WarningPrint("returning empty df (warning No tag deployment found with ID)")
  return(onError_df)
}

##if in future we care, implement this test
##next test page title was as expected
#ans=testPageTitlenodes(page, "Detections - Tag deployment")
#if (ans==TRUE){
#  DebugPrint("Motus responded with expected page title - continue testing response")
#}

DebugPrint("end initial html result testing")


# *************************************************************

tbls <- page %>% html_nodes("table")

##print(length(tbls))
#[1] 1

tbl1 <- html_table(tbls[[1]],fill=TRUE)
##print(tbl1)

num.cols<-dim(tbl1)[2]
num.rows<-dim(tbl1)[1]
#print(dim(tbl1))

# create five empty 'vectors'
date<-c()
site<-c()
lat<-c()
lon<-c() 
receiverDeploymentID<-c()
seq<-c()
use<-c()

#> print(class(tbl1[[1]][i]))  
#[1] "character"
# table entries are all class "character"

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



#build four vectors from table data
#for(i in 1:num.rows){
n <- 0
for(i in 1:nrecords){
  n<-n+1

  date <- c( date,  tbl1[[1]][i]  )
  site <- c( site,  tbl1[[2]][i] )
  lat <-  c( lat,  tbl1[[3]][i]  )
  lon <-  c( lon,  tbl1[[4]][i] )
  seq <- c(seq,n)
  use <- c(use,TRUE)
}

#convert strings to correct type
date <- as.Date(date)
lat <-  gsub("[^0-9.-]", "", lat)
lat <- as.numeric(lat)
lon <-  gsub("[^0-9.-]", "", lon)
lon <- as.numeric(lon)

# ----------------------------------------------------------
# process the page a second time for the receiverDeploymentID's that
# are embedded in the anchor tag of the site name cells.
# get all the table rows, with <a href=
a_nodes <- page %>%
  html_nodes("table") %>% html_nodes("tr") %>% html_nodes("a") %>%
  html_attr("href") #as above

#print(a_nodes)
#print("length of a_nodes is:")
#print (length(a_nodes))
# loop through the table rows and extract the tagDeployment URL
# that looks like:  "receiverDeployment?id=9195"
# parse it to extract the numeric receiverDeploymentID
# and append it to the list...
n <- 0
for (node in a_nodes) {
  #print(node)
  #print(class(node))
  ans <- str_detect( toString(node), "receiverDeployment" )
  if(ans) {
    n <- n+1
    theID <- as.numeric( sub("\\D*(\\d+).*", "\\1", node) )
    receiverDeploymentID<- c( receiverDeploymentID, theID  )
    #cat("n:",n," length:", length(receiverDeploymentID), "theId:",theID, "\n")
  }
}

summaryFlight_df <-data.frame(date,site,lat,lon,receiverDeploymentID,seq,use)

# obtain the track data with so we can correctly order the daily summary data
# tagTrack_df <- tagTrack(tagDeploymentID, config.EnableReadCache, config.ActiveCacheAgeLimitMinutes)

#dont read or write cache this df is a by product used to create
#the summary flight df so if that cached product would be the same age
#if we wrote this to cache... ie its redundant to cache this
tagTrack_df <- tagTrack(tagDeploymentID, 0, 0) 

# we need the correct receiverDeploymentID to support the ability to filter out
# specific wild points detections in later steps.
# Make a compact df of all unique sites from the tagTrack_df
# for each distinct site, use the summaryFlight_df to lookup the receiverDeploymentID
# using the site name and replace the dummy default receiver on the tagTrack_df 

distinctSites_df<-tagTrack_df[!duplicated(tagTrack_df[ , c("site") ]),]
if( length(distinctSites_df > 0 )){
  for(i in 1:nrow(distinctSites_df)) {
    row <- distinctSites_df[i,]
    theDate=row[["date"]]
    theID=row[["receiverDeploymentID"]]
    theSite=row[["site"]]
    
    #search for a row in summary containing the target site name 
    res <- subset(summaryFlight_df, site==theSite)
    res <- subset(res, 
                  subset = !duplicated(res[c("site", "receiverDeploymentID")]) )
    #if found, use the receiverDeploymentID to overwrite the dummy default value
    if(nrow(res==1)){
      theReceiverDeploymentID<-res$receiverDeploymentID
      tagTrack_df$receiverDeploymentID[ tagTrack_df$site == theSite] <- theReceiverDeploymentID
    } #else site was not found on summaryFlight_df - ignore
  } # end for each row
} #endif length distinct sites

#sort flight detection so most recent appears at bottom of the list
tagTrack_df <- tagTrack_df[ order(tagTrack_df$usecs, decreasing = FALSE), ]

#options(max.print=1000000)
#print(tagTrack_df)


# we are done with the original summary df
# we build a new summaryFlight_df from time ordered df sequence number
n<-0
prior_doy<-0
prior_rcvr<-9999

if( nrow(tagTrack_df) >= 1 ){
  summaryFlight_df<-empty_tagDeploymentDetection_df() #zero it our so we can rebuild it
  
  for (row in 1:nrow(tagTrack_df)) {
  seq <- n #overwrites seq from raw dataframe
  theUsecs <- tagTrack_df[row, "usecs"]
  date <- tagTrack_df[row, "date"]
  site <- tagTrack_df[row, "site"]
  lat <- tagTrack_df[row, "lat"]
  lon <- tagTrack_df[row, "lon"]
  receiverDeploymentID <- tagTrack_df[row, "receiverDeploymentID"]
  use <- tagTrack_df[row, "use"]
  yr <- as.numeric(strftime(date, format = "%Y"))
  doy <- as.numeric(strftime(date, format = "%j"))
  #now ready truncate the datetime to date part only
  s<-strftime(date, format = "%Y-%m-%d")
  date<-s

  # we want to build a new data frame only using only the first detection of
  # tag + day + station (with new sequence number)
  if( (doy == prior_doy) &  (receiverDeploymentID == prior_rcvr ) ){
    use<-FALSE
  } else { 
    use<-TRUE
    # create new frame and append 
    n<-n+1
    seq<-n
    a_df<-data.frame(date, site, lat, lon, receiverDeploymentID,seq,use)
    summaryFlight_df[nrow(summaryFlight_df) + 1,] <- a_df
    prior_doy = doy
    prior_rcvr = receiverDeploymentID
  }
}  #end for each row

} #endif nrows(tagTrack_df)>0

#remove any other rows with 'use' field = FALSE
summaryFlight_df <- summaryFlight_df[!(summaryFlight_df$use == FALSE),]

#double check sort flight detection so most recent appears at bottom of the list
summaryFlight_df <- summaryFlight_df[ order(summaryFlight_df$seq, decreasing = FALSE), ]

#finally, delete any rows with nulls
summaryFlight_df <- summaryFlight_df %>% drop_na()

if(config.EnableWriteCache == 1){
  DebugPrint("writing new cache file.")
  saveRDS(summaryFlight_df,file=cacheFilename)
}
DebugPrint("tagDeploymentDetections done.")

#message("finished flight summary")
#print(summaryFlight_df)

return(summaryFlight_df)
}