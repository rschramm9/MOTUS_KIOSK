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
  df <- data.frame( matrix( ncol = 9, nrow = 1) )
  df <- df %>% drop_na()
  colnames(df) <- c('date', 'site', 'lat', 'lon', 'receiverDeploymentID','seq', 'use','usecs','doy')
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

  # create empty 'vectors'
  usecs<-c()
  site<-c()
  lat<-c()
  lon<-c() 
  seq<-c()
  n<-0
  #convert json to vectors for dataframe
  for (i in seq( 1, length(json), 4) ) {
    for(j in seq(1,length(json[[i+3]]),1 )){
      
      lat <-  c( lat, json[[i]]  )
      lon <-  c( lon, json[[i+1]] )
      site <- c( site, json[[i+2]] )
      usecs <- c( usecs, json[[i+3]][[j]] )
      #bump counter, append to seq array
      n<-n+1
      seq<-c(seq,n)
    } #end for j
  } #end for i
  
  # and combine arrays into a dataframe
  df <-data.frame(site,lat,lon,seq,usecs)

  # and sort flight detection so most recent appears at bottom of the list
  df <- df[ order(df$usecs, decreasing = FALSE), ]
    
  #delete any rows with nulls
  df <- df %>% drop_na()
  
  df$receiverDeploymentID<-0
  df$date <- as.POSIXct(as.numeric(df$usecs), origin = '1970-01-01', tz = 'UTC')
  df$doy <- (as.numeric(strftime(df$date, format = "%Y", tz = "UTC"))) *1000 + (as.numeric(strftime(df$date, format = "%j", tz = "UTC")))
  df$use<-TRUE
  #add three columns to help with statistics
  df$runstart <- 0
  df$runend <- 0
  df$runcount <- 0
    
  #options(max.print=1000000)
  #print("---------------------tagTrack.R df  at line 114 ----------------")
  #print(df)
     
  if( nrow(df) >= 1 ){
  
      #first go thru df backwards to get the last detection timestamp for any date/site
      idxstrt<-nrow(df)
      idxend<-1
      current_site <- "dontcare"  #df[idxstrt, "site"]
      current_doy <- 0 #dont care
      n <- 0
      
      for (i in idxstrt:idxend){
        usecs <- df[i,"usecs"]
        if(  (df[i, "site"] == current_site)  & ( df[i,"doy"] == current_doy) ) {
          n <- n+1
        } else {
           departed <- usecs
           n <- 1
           current_site <- df[i, "site"]
           current_doy <- df[i,"doy"]
        }
        df[i,"runend"] <- departed
        df[i,"runcount"] <- n
      } # end for

      #then go thru forward to get the first (earliest) detection timestamp for any date/site
      #and the largest runcount for each date/site run
      idxstrt <- 1
      idxend <- nrow(df)
      current_site <- "dontcare"  #df[idxstrt, "site"]
      current_doy <- 0 #dont care
      
      for (i in idxstrt:idxend){
        usecs <- df[i,"usecs"]
        
        if(  (df[i, "site"] != current_site)  | ( df[i,"doy"] != current_doy) ) {
          #this is the first record of a new site/doy run
          arrived <- usecs
          runcount <- df[i,"runcount"]
          current_site <- df[i, "site"]
          current_doy <- df[i,"doy"]
        }
        
        df[i,"runstart"] <- arrived
        df[i,"runcount"] <- runcount
      } # end for
      
#      options(max.print=1000000)
#      print("---------------------tagTrack.R df  at line 176 ----------------")
#      print(df)
 
    }   #end if

    # save to cache
    if(config.EnableWriteCache == 1){
      DebugPrint("writing new cache file.")
      saveRDS(df,file=cacheFilename)
    }
    DebugPrint("tagDeploymentDetections done.")
    
    return(df)
}