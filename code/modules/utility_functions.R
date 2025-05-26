################################################################################
# insert row in dataframe
# from https://stackoverflow.com/questions/11561856/add-new-row-to-dataframe-at-specific-row-index-not-appended
################################################################################
insertRow <- function(existingDF, newrow, r) {
  existingDF[seq(r+1,nrow(existingDF)+1),] <- existingDF[seq(r,nrow(existingDF)),]
  existingDF[r,] <- newrow
  existingDF
}


################################################################################
# 
################################################################################
CloneKiosk <- function(from, to)
{ 
  #kiosks='./kiosks/'
  fromkiosk<-paste0(from)
  tokiosk<-paste0(to)
  if (!file.exists(fromkiosk)) {
    message(paste0("ERROR: kiosk", fromkiosk," not found."))
  } else {
    
    if (!file.exists(tokiosk)) {
      message("creating kiosk")
      R.utils::copyDirectory( fromkiosk, tokiosk)
    } else {
      message(paste0("ERROR: kiosk",tokiosk," name already exists."))
    }
    
  }
}

################################################################################
# 
################################################################################

ReadCsvToDataframe <-function(fname,hasHeader){
  
  if(missing(hasHeader)) {
    hasHeader<-TRUE
  }
  
  # read a csv file if exists... any error returns NA
  tryCatch ( 
    {  
      if (file.exists(fname)){
        df <- read.table(file=fname, sep = ",", as.is = TRUE, header=hasHeader)
      } else { 
        df <- NULL }
    },
    #warning = function( w )
    #{
    #   WarningPrint("") # dummy warning function to suppress the output of warnings
    # df <- NULL
    #},
    error = function( err )
    {
      ErrorPrint("ReadCsvToDataframe read error")
      ErrorPrint( paste(" reading file:",fname))
      ErrorPrint(" here is the err returned by the read:")
      ErrorPrint(err)
      df<- NULL
    } )
    
  return(df)
}





################################################################################
# given HTML page and a target string 'title'
# will return TRUE if any html title node title string contains target
# else return FALSE if not found or no match
################################################################################
testPageTitlenodesOld <-function(page,target){
  mynodes <- html_nodes(page, "title")
  print(mynodes)
  # note.. turn off warnings that str_detects about
  # argument is not an atomic vector; coercing
  warn = getOption("warn")
  options(warn=-1)
  ans <- str_detect(toString( mynodes), target )
  print(paste0("Answer:", ans))
  options(warn=warn)
  newans <- any(ans, na.rm = TRUE)  #collapse vector to one element
  print(paste0("NewAnswer:", newans))
  if (newans > 0) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}
################################################################################
# given HTML page and a target string 'title'
# will return TRUE if any html title node title string contains target
# else return FALSE if not found or no match
################################################################################
testPageTitlenodes <-function(page,target){
  # Extract all <title> node texts from the parsed HTML
  titles <- html_nodes(page, "title") %>% html_text()
  
  # Return TRUE if any title contains the target substring
  return(any(grepl(target, titles, fixed = TRUE)))
}




################################################################################
# given HTML page and a target string 
# will return TRUE if any html Paragraph node string contains target
# else return FALSE if not found or no match
################################################################################
testPagePnodes <-function(page,target){
  mynodes <- html_nodes(page, "p")
  # note.. turn off warnings that str_detects about
  # argument is not an atomic vector; coercing
  warn = getOption("warn")
  options(warn=-1)
  ans <- str_detect(toString( mynodes), target )
  options(warn=warn)
  newans <- any(ans, na.rm = TRUE)  #collapse vector to one element
  if (newans > 0) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}

################################################################################
# given table with two columns: key and value, will return the value for
#the key (if found) else "unknown"
################################################################################
find4me <-function(mytbl,target){
  
  idxarray <-which(mytbl == target, arr.ind = TRUE)
  if( nrow(idxarray) > 0 ){
    idx=idxarray[1]
    result <-mytbl[[2]][idx]
  } else {
    DebugPrint("target item not found in results:")
    DebugPrint(target)
    result <- "unknown"
  }
  return(result)
}

################################################################################
# define function for reading the URL
# returns html page contents or error msg string
################################################################################
readUrlWithTimeout <- function(url, timeoutsecs=config.HttpGetTimeoutSeconds) {

  out <- tryCatch(
    { 

      ###read_html(url)
      ###url %>% GET(., timeout(timeoutsecs)) %>% read_html
      ###### change to include a "UserAgent" so folks at motus.org can see
      ###### who is making the request to help with thier monitoring
      
      # Make the request with timeout and user agent
      custom_agent <- user_agent(gblUserAgentText)
      url %>%
        GET(., timeout(timeoutsecs), custom_agent) %>%
        read_html()
    },
    error=function(cond) {
      WarningPrint(paste("URL caused ERROR  does not seem to exist:", url))
      WarningPrint("Here's the original error:")  #404 for bad URL
      s = cond[[1]]
      WarningPrint(s)
      return(s)
    },
    warning=function(cond) {
      WarningPrint(paste("URL caused a WARNING:", url))
      WarningPrint("Here's the original warning:")
      s = cond[[1]]
      WarningPrint(s)
      return(s)
    },
    finally={
      # Here goes everything that should be executed at the end,
      # regardless of success or error.
      InfoPrint(paste("Completed HTML request for URL:", url))
    }
    
  ) # end catch
  
  return(out)
}  ### end readUrl()


################################################################################
# function for reading the cache file
# returns:
#   dataframe if read in from cache 
#   else NA
# 
################################################################################
readCache <- function(cacheFilename, useReadCache=1, cacheAgeLimitMinutes=60) 
{
   cacheAgeLimitSeconds=cacheAgeLimitMinutes*60
   DebugPrint(paste0("Entered readCache with useReadCache:", useReadCache," cacheAgeLimitMinutes:",cacheAgeLimitMinutes,
                  " (", cacheAgeLimitSeconds, " seconds.)"))
   DebugPrint(paste0("And cacheFilename:", cacheFilename ))
   if(useReadCache<=0){
      DebugPrint(paste0("cache skipped because useReadCache=0"))
      return(NA)  #<<<<<<<<<<<<<<<<
   }
  
  tryCatch( {
   if (!file.exists(cacheFilename))  {
     DebugPrint(paste0("cache file was not found"))
   } else {
     DebugPrint("cache file exists")
      info <- file.info(cacheFilename)
      tnow<-Sys.time()
      tfile<-info$mtime
      deltat<-difftime(tnow,tfile, units = "secs")   
      DebugPrint(paste0(cacheFilename," is ",deltat," seconds old."))
    
      if ( deltat <= cacheAgeLimitSeconds ) {
        DebugPrint(paste0("reading from active cache"))
         df<-readRDS(cacheFilename)
         DebugPrint(paste0("returning with the active cache dataframe"))
         return(df)  #<<<<<<<<<<<<<<<< we are done, return the cache df here
      } else {
        DebugPrint(paste0("active cache expired"))
      }
   } #end else
    DebugPrint("finished trycatch")
  },  #trycatch
  error = function(e) NULL
  ) # end trycatch
   DebugPrint("fall-thru returning NA")
  #if we got here - there was no cache df to return so return NA
  return(NA)   #  <<<<<<<<
}  ### end readCache()


################################################################################
# function to take a Key and the config table
# and return the value as list, typically length 1 but could be multiple
# eg. a ReceiverShortName lstValue could be "Ankeny Hill","Bullards Bridge"
# would return a list of length=2 with items list[1] and list[2]
# or only "Ankeny Hill" we get a list of length=1 and the item is at list[1]
# returns NULL if key not found
################################################################################
keyValueToList <- function(cfg,key) {
  ##keyValueToList <- function(theTable,theKey) {
  # get the value for the key, convert to numeric
  # print(paste0("in keyValueToList() with key:",key))
  
  if (!key %in% names(cfg)) {
    warning(sprintf("Key '%s' not found in configuration.", key))
    return(list())  #return empty list
  }
  
  val <- cfg[[key]]
  
  # Case 1: Character vector with a single comma-separated string
  if (is.character(val) && length(val) == 1 && grepl(",", val)) {
    split_vals <- strsplit(val, ",")[[1]]
    split_vals <- trimws(split_vals)            # Remove leading/trailing spaces
    #split_vals <- gsub('^"|"$', '', split_vals) # Remove leading/trailing quotes
    cleaned <- trimws(gsub('^"|"$', '', split_vals))  # remove quotes
    return(as.list(cleaned))
  }
  
  # Case 2: Numeric vector → convert each number into a list element
  if (is.numeric(val)) {
    return(as.list(val))
  }
  
  # Case 3: Regular character vector (e.g., already split quoted names)
  if (is.character(val)) {
    cleaned <- trimws(gsub('^"|"$', '', val))
    return(as.list(cleaned))
  }
  
  # Case 4: Already a list
  if (is.list(val)) {
    return(val)
  }
  
  # Fallback: wrap in list
  return(list(val))
  
} #end function keyValueToList()

################################################################################
# Function to print string preceded with a timestamp and function name
################################################################################
TSprint <- function(s="") {
  ts = format(Sys.time(), "%d.%m.%Y %H:%M:%OS")
  prefix<-0
  functionname<-curfnfinder(skipframes=prefix+1) #note: the +1 is there to avoid returning catw itself
  m = paste0('[', ts, ']', ' [', functionname,  '] ', s)
  cat(m,"\n")
  gblLastDebugPrintTime <<- Sys.time()
}

################################################################################
# Function to print string preceded with a timestamp and function name
################################################################################
DebugPrint <- function(s="") {
  if(LOG_LEVEL < LOG_LEVEL_DEBUG){ return() }
  ts = format(Sys.time(), "%d.%m.%Y %H:%M:%OS")
  prefix<-0
  functionname<-curfnfinder(skipframes=prefix+1) #note: the +1 is there to avoid returning catw itself
  m = paste0('[', ts, ']', ' [DEBUG] [', functionname,  '] ', s)
  cat(m,"\n")
  gblLastDebugPrintTime <<- Sys.time()
}

InfoPrint <- function(s="") {
  if(LOG_LEVEL < LOG_LEVEL_INFO){ return() }
  ts = format(Sys.time(), "%d.%m.%Y %H:%M:%OS")
  prefix<-0
  functionname<-curfnfinder(skipframes=prefix+1) #note: the +1 is there to avoid returning catw itself
  m = paste0('[', ts, ']', ' [INFO]  [', functionname,  '] ', s)
  cat(m,"\n")
  gblLastDebugPrintTime <<- Sys.time()
}

WarningPrint <- function(s="") {
  if(LOG_LEVEL < LOG_LEVEL_WARNING){ return() }
  ts = format(Sys.time(), "%d.%m.%Y %H:%M:%OS")
  prefix<-0
  functionname<-curfnfinder(skipframes=prefix+1) #note: the +1 is there to avoid returning catw itself
  m = paste0('[', ts, ']', ' [WARNING] [', functionname,  '] ', s)
  cat(m,"\n")
  gblLastDebugPrintTime <<- Sys.time()
}

ErrorPrint <- function(s="") {
  if(LOG_LEVEL < LOG_LEVEL_ERROR){ return() }
  ts = format(Sys.time(), "%d.%m.%Y %H:%M:%OS")
  prefix<-0
  functionname<-curfnfinder(skipframes=prefix+1) #note: the +1 is there to avoid returning catw itself
  m = paste0('[', ts, ']', ' [ERROR] [', functionname,  '] ', s)
  cat(m,"\n")
  gblLastDebugPrintTime <<- Sys.time()
}


FatalPrint <- function(s="") {
  if(LOG_LEVEL < LOG_LEVEL_FATAL){ return() }
  ts = format(Sys.time(), "%d.%m.%Y %H:%M:%OS")
  prefix<-0
  functionname<-curfnfinder(skipframes=prefix+1) #note: the +1 is there to avoid returning catw itself
  m = paste0('[', ts, ']', ' [FATAL] [', functionname,  '] ', s)
  cat(m,"\n")
  gblLastDebugPrintTime <<- Sys.time()
}





################################################################################
# get name of current function  -  used by TSprint()
# FROM: https://stackoverflow.com/questions/7307987/logging-current-function-name
################################################################################

curfnfinder<-function(skipframes=0, skipnames="(FUN)|(.+apply)|(replicate)",
                      retIfNone="Not in function", retStack=FALSE, extraPrefPerLevel="")
{
  prefix<-sapply(3 + skipframes+1:sys.nframe(), function(i){
    currv<-sys.call(sys.parent(n=i))[[1]]
    return(currv)
  })
  prefix[grep(skipnames, prefix)] <- NULL
  prefix<-gsub("function \\(.*", "do.call", prefix)
  if(length(prefix)==0)
  {
    return(retIfNone)
  }
  else if(retStack)
  {
    return(paste(rev(prefix), collapse = "|"))
  }
  else
  {
    retval<-as.character(unlist(prefix[1]))
    if(length(prefix) > 1)
    {
      retval<-paste(paste(rep(extraPrefPerLevel, length(prefix) - 1), collapse=""), retval, sep="")
    }
    return(retval)
  }
}
################################################################################
## a function to determine the platform os
## Usage:  os <- get_os()
##         message(paste0("The operating system is:",os))
################################################################################
#get_os <- function(){
#  sysinf <- Sys.info()
#  if (!is.null(sysinf)){
#    os <- sysinf['sysname']
#    if (os == 'Darwin')
#      os <- "osx"
#  } else { ## mystery machine
#    os <- .Platform$OS.type
#    if (grepl("^darwin", R.version$os))
#      os <- "osx"
#    if (grepl("linux-gnu", R.version$os))
#      os <- "linux"
#  }
#  tolower(os)
#}

