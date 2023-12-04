library("rjson")

################################################################################
## create empty tagTrack data frame
## called within tagTrack() to return an
## empty data frame when that function has problems with
## what comes back from the motus server.
## WARNING: length and column names need to match exactly
## what is created by tagDeploymentDetections()
################################################################################

empty_tagTrack_df <- function()
{
  df <- data.frame( matrix( ncol = 8, nrow = 1) )
  df <- df %>% drop_na()
  colnames(df) <- c('usecs', 'date', 'site', 'lat', 'lon', 'receiverDeploymentID','seq', 'use')
  return (df)
}

# returns if tagid not found:
#  []
# class json::list  length:0

# normal returns like:
#  [49.0588,-123.1421,"Brunswick Point farm",[1666625957,1666626091,1666821932],,"tagging site",[1666113180,1666113480]]

# Returns for bad url https://motus.org/daxxta/json/track?tagDeploymentId=2343628
#  <title>  Page not foundMotus Wildlife Tracking System</title>

#https://motus.org/data/json/track?tagDeploymentId=44115

tagTrack <- function(tagDeploymentID, useReadCache=0, cacheAgeLimitMinutes=60) 
{
  
  url <- paste( c('https://motus.org/data/json/track?tagDeploymentId=',tagDeploymentID) ,collapse="")   
  ##url <- "https://motus.org/data/json/track?tagDeploymentId=45113"
  
  #url<-"https://motus.org/data/json/track?tagDeploymentId=944115"
  message(url)
  
  cacheFilename = paste0(config.CachePath,"/tagTrack_",tagDeploymentID,".Rda")
  
  df <-readCache(cacheFilename, useReadCache, cacheAgeLimitMinutes)   #see utility_functions.R
  
  if( is.data.frame(df)){
    DebugPrint("tagTrack returning cached file")
    return(df)
  } #else was NA
  
  #prepare an empty dataframe we can return if we encounter errors parsing query results
  onError_df <- empty_tagTrack_df()
  
  # we either already returned the valid cache df above and never reach this point,
  # or the cache system wasnt used or didnt return a cached dataframe,
  # so need to call the URL 
  InfoPrint(paste0("make call to motus.org using URL:",url))
  
  json <- rjson::fromJSON(file=url)
  
  if( !is.list(json)){
    ErrorPrint(paste("No json list object returned from url:",url))
    message("returning onError df")
    return(onError_df)           
  }

  l=length(json)
  if(l <= 0){
    ErrorPrint(paste("Empty json list object returned from url:",url))
    message("returning onError df")
    return(onError_df)           
  }

  # create five empty 'vectors'
  usecs<-c()
  date<-c()
  site<-c()
  lat<-c()
  lon<-c() 
  receiverDeploymentID<-c()
  seq<-c()
  use<-c()
  n<-0

  for (i in seq( 1, length(json), 4) ) {

    for(j in seq(1,length(json[[i+3]]),1 )){
      the_lat<-json[[i]]
      the_lon<-json[[i+1]]
      the_site <- json[[i+2]]
      the_usecs <- json[[i+3]][[j]]
      the_date <- as.POSIXct(as.numeric(the_usecs), origin = '1970-01-01', tz = 'GMT')

      usecs <- c( usecs, the_usecs )
      date <- c( date, as.character(the_date ))
      site <- c( site, the_site )
      lat <-  c( lat, the_lat  )
      lon <-  c( lon, the_lon )
      receiverDeploymentID<-c(receiverDeploymentID,0) #0=default 
      n<-n+1
      seq<-c(seq,n)
      use<-c(use,TRUE)
    } #end for j
  
  } #end for i
  
    df <-data.frame(usecs,date,site,lat,lon, receiverDeploymentID,seq,use)
  
    #finally, delete any rows with nulls
    df <- df %>% drop_na()

    if(config.EnableWriteCache == 1){
      DebugPrint("writing new cache file.")
      saveRDS(df,file=cacheFilename)
    }
    DebugPrint("tagDeploymentDetections done.")
    
    return(df)
}