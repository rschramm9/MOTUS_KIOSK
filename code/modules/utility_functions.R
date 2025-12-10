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
# returns either a zero length list or NULL if key not found - so check for both
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

################################################################################
#function to safely load motus news pages yaml catalog
# returns a list of lists
# on error return NULL
################################################################################
read_motus_news_yaml <- function(path) {
  if (!file.exists(path)) {
    warning(sprintf("YAML file not found: %s", path))
    return(NULL)
  }
  
  yaml_obj <- tryCatch(
    yaml::read_yaml(path),
    error = function(e) {
      warning(sprintf(
        "Error reading motus news YAML file '%s': %s",
        path, e$message
      ))
      return(NULL)
    }
  )
  
  # If parse failed, yaml_obj will already be NULL
  if (is.null(yaml_obj)) return(NULL)
  
  if (!is.list(yaml_obj) || length(yaml_obj) == 0) {
    warning(sprintf("Motus news YAML file '%s' does not contain a valid list structure.", path))
    return(NULL)
  }
  ## str(yaml_obj)
  yaml_obj
}


################################################################################
# a function to 
# on error return NULL
################################################################################
validate_news_files <- function(df, yaml_path) {
  
  base_dir <- dirname(yaml_path)
  
  if (!dir.exists(base_dir)) {
    warning(sprintf("Base newspages directory does not exist: %s", base_dir))
    return(NULL)
  }
  
  if (nrow(df) == 0) return(NULL)
  
  bad <- logical(nrow(df))
  
  for (i in seq_len(nrow(df))) {
    
    story_dir <- file.path(base_dir, df$directory[i])
    
    # Extract English filename and derive es/fr variants
    file_en <- df$filename[i]
    
    # Must match pattern *_en.html
    if (!grepl("_en\\.html$", file_en)) {
      warning(sprintf(
        "YAML entry %d: English filename does not end in '_en.html': %s",
        i, file_en
      ))
      bad[i] <- TRUE
      next
    }
    
    # Build expected language filenames
    file_es <- sub("_en\\.html$", "_es.html", file_en)
    file_fr <- sub("_en\\.html$", "_fr.html", file_en)
    
    # Full paths
    path_en <- file.path(story_dir, file_en)
    path_es <- file.path(story_dir, file_es)
    path_fr <- file.path(story_dir, file_fr)
    
    # Check story folder exists
    if (!dir.exists(story_dir)) {
      warning(sprintf("YAML entry %d: directory not found: %s", i, story_dir))
      bad[i] <- TRUE
      next
    }
    
    # Check required HTML files exist
    missing <- c(
      if (!file.exists(path_en)) "EN",
      if (!file.exists(path_es)) "ES",
      if (!file.exists(path_fr)) "FR"
    )
    
    if (length(missing) > 0) {
      message(path_en)
      warning(sprintf(
        "YAML entry %d (%s): Missing HTML files: %s",
        i, df$directory[i], paste(missing, collapse=", ")
      ))
      bad[i] <- TRUE
    }
  }
  
  # Remove bad rows
  if (any(bad)) {
    df <- df[!bad, , drop = FALSE]
    if (nrow(df) == 0) {
      warning("All YAML entries failed file existence checks.")
      return(NULL)
    }
  }
  
  df
}







################################################################################
# a function to convert the motus news yaml object to a dataframe
# on error return NULL
################################################################################
motus_news_yaml_to_df <- function(yaml_list) {
  
  if (is.null(yaml_list)) return(NULL)
  
  required_fields <- c(
    "sequence", "directory", "filename",
    "title_en", "title_es", "title_fr",
    "subtitle_en", "subtitle_es", "subtitle_fr"
  )
  
  # Check required fields on each entry
  for (i in seq_along(yaml_list)) {
    entry <- yaml_list[[i]]
    for (field in required_fields) {
      if (is.null(entry[[field]])) {
        warning(sprintf(
          "Motus news YAML entry %d is missing required field '%s'.",
          i, field
        ))
        return(NULL)
      }
    }
  }
  
  df <- tryCatch(
    {
      data.frame(
        sequence     = as.numeric(sapply(yaml_list, `[[`, "sequence")),
        directory    = as.character(sapply(yaml_list, `[[`, "directory")),
        filename     = as.character(sapply(yaml_list, `[[`, "filename")),
        title_en     = as.character(sapply(yaml_list, `[[`, "title_en")),
        title_es     = as.character(sapply(yaml_list, `[[`, "title_es")),
        title_fr     = as.character(sapply(yaml_list, `[[`, "title_fr")),
        subtitle_en  = as.character(sapply(yaml_list, `[[`, "subtitle_en")),
        subtitle_es  = as.character(sapply(yaml_list, `[[`, "subtitle_es")),
        subtitle_fr  = as.character(sapply(yaml_list, `[[`, "subtitle_fr")),
        stringsAsFactors = FALSE
      )
    },
    error = function(e) {
      warning(sprintf("Error building Motus News dataframe from YAML: %s", e$message))
      return(NULL)
    }
  )
  
  if (is.null(df)) return(NULL)
  
  if (any(is.na(df$index))) {
    warning("Motus News error - one or more YAML entries contain invalid or missing 'sequence' values.")
    return(NULL)
  }
  
  df
}


################################################################################
# load the motus news catalog using the two function above.
# on error return NULL
################################################################################
load_motus_news_catalog <- function(path) {
  yaml_list <- read_motus_news_yaml(path)
  df <- motus_news_yaml_to_df(yaml_list)
  
  ###if (is.null(df)) return(NULL)
  
  df <- validate_news_files(df, path)
  if (is.null(df)) return(NULL)
  
  # Build iframe URL using your existing newspages resource path
  df$url <- sprintf("newspages/%s/%s", df$directory, df$filename)
  
  # Sort by sequence
  df <- df[order(df$sequence), ]
  
  df
}

################################################################################
# build the multilingual news stories choice names for MotusNews.R
################################################################################
build_choice_names <- function(df, lang_code) {
  
  # Pick the correct title column based on language
  title_col <- dplyr::case_when(
    lang_code == "es" ~ "title_es",
    lang_code == "fr" ~ "title_fr",
    TRUE              ~ "title_en"   # default English
  )
  
  # Pick the correct subtitle column similarly
  subtitle_col <- dplyr::case_when(
    lang_code == "es" ~ "subtitle_es",
    lang_code == "fr" ~ "subtitle_fr",
    TRUE              ~ "subtitle_en"
  )
  
  # Build the HTML label for each row
  lapply(seq_len(nrow(df)), function(i) {
    tagList(
      tags$strong(df[[title_col]][i]),
      tags$br(),
      tags$span(
        style = "font-size: 80%; color: #666;",
        df[[subtitle_col]][i]
      )
    )
  })
}


