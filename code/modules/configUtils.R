########################################################################################
# Utility functions for managing kiosk configuration 
########################################################################################

########################################################################################
# Read the startup.cfg to get the name of the target kiosk etc
# sets GLOBAL config parameters
# return TRUE if made it all the way thru or FALSE if there were issues.
#
########################################################################################
getStartConfig <- function() {
  
  tryCatch( 
    {  
      thefile<-paste0(projectdir,"/","startup.cfg")  # note projectdir is global set in global.R
      message(paste0("testing startup.cfg file:",thefile))
      if (!file.exists(thefile)) {
        message(paste0("ERROR: getStartConfig: startup.cfg file not found at:", thefile))
        stop("There is an error reading your cfg file")
      } #else file exists
      
      #attempt to read file from current directory
      configfrm <- read.table( file=thefile,
                               header=FALSE, 
                               sep='=',col.names=c('Key','Value'),
                               strip.white = TRUE, 
                               stringsAsFactors = FALSE) 
      
      InfoPrint("Loaded start configuration data from local file startup.cfg")
    },
    
    warning = function( w )
    {
      print() # dummy warning function to suppress the output of warnings
    },
    
    error = function( err ) 
    {
      WarningPrint("Could not read startup.cfg data from current working directory")
      ErrorPrint("Config file read error: Could not load start configuration data. Exiting Program")
      ErrorPrint("here is the err returned by the read:")
      ErrorPrint(err)
      ErrorPrint("Please check the location of your startup.cfg file.")
      ErrorPrint("Also check the last line startup.cfg file ends with a new blank line.")
      stop("There is an error reading your startup.cfg file")
    }
  )
  
  # conver from dataframe to datatable 
  configtbl <- data.table(configfrm, key='Key')
  
  badCfg<-FALSE  #assume a good config
  
  #print("------------ StartKiosk ----------------")
  list1 <- keyValueToList(configtbl,'StartKiosk')
  if( is.null(list1) ){
    badCfg<-TRUE
    config.StartKiosk<<-NULL
  } else {
    #I ultimately want a string
    config.StartKiosk<<- toString(list1[1])  
  }
  #message(paste0("Starting cfg for:",config.StartKiosk))
  
  #print("------------ KiosksPath ----------------")
  list1 <- keyValueToList(configtbl,'KiosksPath')
  if( is.null(list1) ){
    badCfg<-TRUE
    config.KiosksPath<<-NULL
  } else {
    #I ultimately want a string
    xxx <- toString(list1[1]) 
    message(paste0("path given:", xxx))
    # if path begins '~/' replace the ~ with users home directory
    if( grepl('^~/', xxx)){
      message(paste0("modifying config directory"))
      home<-path_home()  #in library fs
      message(paste0("Home is:",home))
      xxx=str_replace(xxx,"~",home)
      message(paste0("config path with tilde expanded:", xxx))
    }
    config.KiosksPath<<-xxx
  }
  #message(paste0("Using KioskPath:", config.KiosksPath))
  
  #print("------------ KioskCfgFile ----------------")
  list1 <- keyValueToList(configtbl,'KioskCfgFile')
  if( is.null(list1) ){
    badCfg<-TRUE
    config.KioskCfgFile<<-NULL
  } else {
    #I ultimately want a string
    config.KioskCfgFile<<- toString(list1[1])  
  }
  
  #message(paste0("Starting cfg for:",config.StartKiosk))
  return(badCfg)
  
} #end getStartConfig()


########################################################################################
# getKioskConfig sets GLOBAL config parameters
# return TRUE if made it all the way thru or FALSE if there were issues.
# WARNING:  You must call getStartConfig() before calling getKioskCfg()
########################################################################################
getKioskConfig <- function() {
  message(paste0("using global KiosksPath:", config.KiosksPath)) #/users/rich/Projects/kiosks
  message(paste0("using global StartKiosk:", config.StartKiosk))
  
  #first test the directory exists
  thedirectory<-paste0(config.KiosksPath,"/",config.StartKiosk)
  
  message(paste0("testing for the named kiosk's directory:",thedirectory))
  if (!file.exists(thedirectory)) {
    message(paste0("ERROR: getKioskConfig: no kiosk directory found at: ",thedirectory))
    ErrorPrint("Please check the name of your StartKiosk in the startup.cfg file.")
    ErrorPrint("and also check that a matching kiosk exists at that location.")
    stop("There is an error reading your startup.cfg file")
  } 
  
  thefile<-paste0(config.KiosksPath,"/",config.StartKiosk,"/",config.KioskCfgFile)
  if (!file.exists(thefile)) {
    message(paste0("ERROR: getKioskConfig: kiosk configuration file not found in kiosk's directory at:",thefile))
    ErrorPrint("Please check that the name of your KioskCfgFile in the startup.cfg file matches a config file in your kiosk's folder.")
    stop("There is an error reading your kiosk's configuration file.")
  }
  
  tryCatch( 
    {
      #attempt to read file from current directory
      configfrm <- read.table( file=thefile,
                               header=FALSE, 
                               sep='=',col.names=c('Key','Value'),
                               strip.white = TRUE, 
                               stringsAsFactors = FALSE) 
      
       InfoPrint(paste0("Loading kiosk configuration data from ", thefile))
    },
    warning = function( w )
    {
      print() # dummy warning function to suppress the output of warnings
    },
    error = function( err ) 
    {
      WarningPrint("Could not read your kiosk's configuration data from current directory")
      ErrorPrint("Config file read error: Could not load kiosk configuration data. Exiting Program")
      ErrorPrint("here is the err returned by the read:")
      ErrorPrint(err)
      ErrorPrint("Check location and contents of the kiosk configuration file named in startup.cfg.")
      ErrorPrint("Also check the last line of your configuration file ends with a new blank line.")
      stop("There is an error reading your kiosk's configuration file")
    }
  )
  
  # convert data.frame to data.table
  configtbl <- data.table(configfrm, key='Key')
 
  badCfg<-FALSE  #assume good config
  
  #config.SiteSpecificContent<<-paste0(projectdir,"/",config.KiosksPath,"/",config.StartKiosk)
  
  config.SiteSpecificContent<<-paste0(config.KiosksPath,"/",config.StartKiosk)
  #message(paste0("in configUtils, config.siteSpecificContent is:", config.SiteSpecificContent))
  InfoPrint(paste0("Site specific root directory is:", config.SiteSpecificContent))
  
  config.SiteSpecificContentWWW<<-paste0(config.SiteSpecificContent,"/www")
  #message(paste0("in configUtils, config.siteSpecificContentWWW is:", config.SiteSpecificContentWWW))
  InfoPrint(paste0("Site specific web content is:", config.SiteSpecificContentWWW))
  
  #print("------------ MainLogoFile ----------------")
  list1 <- keyValueToList(configtbl,'MainLogoFile')
  if( is.null(list1) ){
    badCfg<-TRUE
    config.MainLogoFile<<-NULL
  } else {
    #I ultimately want a string
    config.MainLogoFile<<- toString(list1[1])  
  }
  
  #print("------------ AdminContact ----------------")
  list1 <- keyValueToList(configtbl,'AdminContact')
  if( is.null(list1) ){
    badCfg<-TRUE
    config.AdminContact<<-NULL
  } else {
    #I ultimately want a string
    config.AdminContact<<- toString(list1[1])  
  }
  
  #print("------------ MainTitleFrench ----------------")
  list1 <- keyValueToList(configtbl,'MainTitleFrench')
  if( is.null(list1) ){
    badCfg<-TRUE 
    config.MainTitleFrench<<-NULL
  } else {
    #I ultimately want a string
    config.MainTitleFrench<<- toString(list1[1])  
  }
  
  #print("------------ MainTitleEnglish ----------------")
  list1 <- keyValueToList(configtbl,'MainTitleEnglish')
  if( is.null(list1) ){
    badCfg<-TRUE 
    config.MainTitleEnglish<<-NULL
  } else {
    #I ultimately want a string
    config.MainTitleEnglish<<- toString(list1[1])  
  }
  
  #print("------------ MainTitleSpanish ----------------")
  list1 <- keyValueToList(configtbl,'MainTitleSpanish')
  if( is.null(list1) ){
    badCfg<-TRUE 
    config.MainTitleSpanish<<-NULL
  } else {
    #I ultimately want a string
    config.MainTitleSpanish<<- toString(list1[1])  
  }
  
  #print("------------ MainLogoHeight --------------")
  list1 <- keyValueToList(configtbl,'MainLogoHeight')
  if( is.null(list1) ){
    badCfg<-TRUE 
    config.MainLogoHeight <<- NULL
  } else {
    config.MainLogoHeight <<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ Homepage----------------")
  #must be the _en.html page....
  #HomepageEnglish="homepages/ankeny_homepage_en.html"
  list1 <- keyValueToList(configtbl,'HomepageEnglish')
  if( is.null(list1) ){
    badCfg<-TRUE
    WarningPrint("Config file is missing entry for HomepageEnglish.")
  } else {
    #I ultimately want a string
    tmpstr<<- toString(list1[1])  
    config.HomepageEnglish<<-paste0(config.SiteSpecificContentWWW,"/",tmpstr)
  }
  
  #print("------------ Species----------------")
  #must be the _en.html page....
  list1 <- keyValueToList(configtbl,'SpeciesPageEnglish')
  if( is.null(list1) ){
    badCfg<-TRUE
    WarningPrint("Config file is missing entry for SpeciesPageEnglish")
  } else {
    #I ultimately want a string
    tmpstr<<- toString(list1[1])
    #config.SpeciesPageEnglish<<-paste0(config.SiteSpecificContentWWW,"/",tmpstr)
    config.SpeciesPageEnglish<<-tmpstr
  }
  
  #print("------------ Motus News----------------")
  #must be the _en.html page....
  list1 <- keyValueToList(configtbl,'NewsPageEnglish')
  if( is.null(list1) ){
    badCfg<-TRUE
    WarningPrint("Config file is missing entry for NewsPageEnglish")
    #config.NewsPageEnglish <<-paste0("kiosks/DEFAULT/www/newpages/news_unknown_en.html")
  } else {
    #I ultimately want a string
    tmpstr<<- toString(list1[1])  
    config.NewsPageEnglish<<-tmpstr
    #config.NewsPageEnglish<<-paste0(config.SiteSpecificContentWWW,"/",tmpstr)
  }
  
  #print("------------ About Motus ----------------")
  #must be the _en.html page....
  list1 <- keyValueToList(configtbl,'AboutMotusPageEnglish')
  if( is.null(list1) ){
    badCfg<-TRUE
    WarningPrint("Config file is missing entry for AboutMotusPageEnglish")
    #config.AboutMotusPageEnglish <<-"kiosks/DEFAULT/www/aboutmotuspages/MOTUS_infographic_final_en.png"
  } else {
    #I ultimately want a string
    tmpstr<<- toString(list1[1]) 
    config.AboutMotusPageEnglish<<-tmpstr
    #config.AboutMotusPageEnglish<<-paste0("www/",config.SiteSpecificContent,"/",tmpstr)
  }
  
  #print("------------ NavbarTextColor ----------------")
  # new for version 6.x 
  list1 <- keyValueToList(configtbl,'NavbarTextColor')
  if( is.null(list1) ){
    config.NavbarTextColor<<-"darkslategray"
  } else {
    config.NavbarTextColor<<- toString(list1[1]) 
  }
  
  #print("------------ NavbarBackgroundColor ----------------")
  # version 6.x name changed from NavbarColor to NavbarBackgroundColor
  list1 <- keyValueToList(configtbl,'NavbarBackgroundColor')
  if( is.null(list1) ){
    list1 <- keyValueToList(configtbl,'NavbarColor')
    if( is.null(list1) ){
      config.NavbarBackgroundColor<<-"#8FBC8F"  #ankeny green
    } else {
      config.NavbarBackgroundColor<<- toString(list1[1]) 
    }
  } else {
    #I ultimately want a string
    config.NavbarBackgroundColor<<- toString(list1[1]) 
  }
  
  
  # In version 6.x TitlebarColor has been replaced by TitlebarTextColor
  #print("------------ TitlebarTextColor ----------------")
  list1 <- keyValueToList(configtbl,'TitlebarTextColor')
  if( is.null(list1) ){
    config.TitlebarTextColor<<-"#8FBC8F"  #ankeny green
  } else {
    config.TitlebarTextColor<<- toString(list1[1]) 
  }
  
  # In version 6.x or later
  #print("------------ TitlebarBackgroundColor ----------------")
  list1 <- keyValueToList(configtbl,'TitlebarBackgroundColor')
  if( is.null(list1) ){
    config.TitlebarBackgroundColor<<-"#8FBC8F"  #ankeny green
  } else {
    #I ultimately want a string
    config.TitlebarBackgroundColor<<- toString(list1[1]) 
  }
  
  # In version 6.x or later
  #print("------------ BodyPageTextColor ----------------")
  list1 <- keyValueToList(configtbl,'BodyPageTextColor')
  if( is.null(list1) ){
    config.BodyPageTextColor<<-"darkslategray"
  } else {
    #I ultimately want a string
    config.BodyPageTextColor<<- toString(list1[1])  
  }
  
  # In version 6.x or later
  #print("------------ BodyPageBackgroundColor ----------------")
  list1 <- keyValueToList(configtbl,'BodyPageBackgroundColor')
  if( is.null(list1) ){
    config.BodyPageBackgroundColor<<-"white"
  } else {
    #I ultimately want a string
    config.BodyPageBackgroundColor<<- toString(list1[1])  
  }
  
  # In version 6.x or later
  #print("------------ SelectedTabTextColor ----------------")
  list1 <- keyValueToList(configtbl,'SelectedTabTextColor')
  if( is.null(list1) ){
    config.SelectedTabTextColor<<-"darkslategray"
  } else {
    #I ultimately want a string
    config.SelectedTabTextColor<<- toString(list1[1])  
  }
  
  # In version 6.x or later
  #print("------------ SelectedTabBackgroundColor ----------------")
  list1 <- keyValueToList(configtbl,'SelectedTabBackgroundColor')
  if( is.null(list1) ){
    config.SelectedTabBackgroundColor<<-"white"
  } else {
    #I ultimately want a string
    config.SelectedTabBackgroundColor<<- toString(list1[1])  
  }
  
  # In version 6.x or later
  #print("------------ JumpToButtonColor ----------------")
  list1 <- keyValueToList(configtbl,'JumpToButtonColor')
  if( is.null(list1) ){
    config.JumpToButtonColor<<-"#FAFA33" # not quite full-on yellow
  } else {
    #I ultimately want a string
    config.JumpToButtonColor<<- toString(list1[1])  
  }
  
  #print("------------ AppOpensToMap --------------")
  list1 <- keyValueToList(configtbl,'AppOpensToMap')
  if( is.null(list1) ){
    config.AppOpensToMap<<- 0
  } else {
    config.AppOpensToMap<<- as.numeric(list1[1]) #assume length=1
  }
  
  print("------------ ReceiverDeploymentID --------------")
  # set global parms of both the list and the first item on the list
  #the default target receiver is the first list item (set in global.R after processing config)
  #note this is actually an atomic vector of type character.
  # like: chr [1:13] "9195" "11454" "10758" "8691" "7474" "10626" "9526" "10611" "7948" "10716" "11046" "10780" "10633"
  config.ReceiverDeployments <<- str_squish(keyValueToList(configtbl,'ReceiverDeploymentID'))
  
  if( is.null(config.ReceiverDeployments)  ){
    message("Config is missing list of Receiver Deployment IDs")
    badCfg<-TRUE 
  }
  
  #print("------------ ReceiverShortName ----------------")
  # set global parms of both the list and the first item on the list
  
  #note this is actually a list of type character.
  #  $ : chr "Ankeny Hill OR"
  #  $ : chr "Hoodsport"
  #  $ : chr " Newport OR (HMSC)"
  #  $ : chr ".......
  #config.ReceiverShortNames<<-keyValueToList(configtbl,'ReceiverShortName')

  my_list<-keyValueToList(configtbl,'ReceiverShortName')
  config.ReceiverShortNames<<-lapply(my_list, trimws) #trim any leading/trailing whitespace
  if( is.null(config.ReceiverShortNames) ){
    badCfg<-TRUE
    message("Config is missing list of ReceiverShortNames")
  }
  
  # Since these two lists support the receiver Picklist they must be same length
  if( length(config.ReceiverShortNames) != length(config.ReceiverDeployments) ){
    message("There is a problem with your kiosk.cfg file. THe ReceiverShortName list must be same length as ReceiverIDs list")
    badCfg<-TRUE
  }
  
  #print("------------ MovingMarkerIcon ----------------")
  list1 <- keyValueToList(configtbl,'MovingMarkerIcon')
  if( is.null(list1) ){
    badCfg<-TRUE 
    config.MovingMarkerIcon<<-NULL
  } else {
    #I ultimately want a string
    config.MovingMarkerIcon<<- toString(list1[1])  
    ###config.MovingMarkerIcon <<-paste0( config.SiteSpecificContentWWW,"/",config.MovingMarkerIcon)
  }
  
  #print("------------ MovingMarkerIconWidth --------------")
  list1 <- keyValueToList(configtbl,'MovingMarkerIconWidth')
  if( is.null(list1) ){
    badCfg<-TRUE 
    config.MovingMarkerIconWidth<<-NULL
  } else {
    config.MovingMarkerIconWidth<<- as.numeric(list1[1]) #assume length=1
  }
  
  list1 <- keyValueToList(configtbl,'MovingMarkerIconHeight')
  if( is.null(list1) ){
    badCfg<-TRUE 
    config.MovingMarkerIconHeight<<-NULL
  } else {
    config.MovingMarkerIconHeight<<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ InactivityTimeoutSeconds --------------")
  list1 <- keyValueToList(configtbl,'InactivityTimeoutSeconds')
  if( is.null(list1) ){
    config.InactivityTimeoutSeconds<<-1800 #30 minutes
  } else {
    config.InactivityTimeoutSeconds<<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ CheckMotusIntervalMinutes --------------")
  list1 <- keyValueToList(configtbl,'CheckMotusIntervalMinutes')
  if( is.null(list1) ){
    config.CheckMotusIntervalMinutes<<-10 
  } else {
    config.CheckMotusIntervalMinutes<<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ EnableReadCache --------------")
  list1 <- keyValueToList(configtbl,'EnableReadCache')
  if( is.null(list1) ){
    config.EnableReadCache<<-1 #1=True, 0=False
  } else {
    config.EnableReadCache<<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ EnableWriteCache --------------")
  list1 <- keyValueToList(configtbl,'EnableWriteCache')
  if( is.null(list1) ){
    config.EnableWriteCache<<-1 #1=True, 0=False
  } else {
    config.EnableWriteCache<<- as.numeric(list1[1]) #assume length=1
  }
  
  
  #print("------------ ActiveCacheAgeLimitMinutes --------------")
  list1 <- keyValueToList(configtbl,'ActiveCacheAgeLimitMinutes')
  if( is.null(list1) ){
    config.ActiveCacheAgeLimitMinutes<<-300 #5 minutes
  } else {
    config.ActiveCacheAgeLimitMinutes<<- as.numeric(list1[1]) #assume length=1
  }
  
  
  #print("------------ InactiveCacheAgeLimitMinutes --------------")
  list1 <- keyValueToList(configtbl,'InactiveCacheAgeLimitMinutes')
  if( is.null(list1) ){
    config.InactiveCacheAgeLimitMinutes<<-20160
  } else {
    config.InactiveCacheAgeLimitMinutes<<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ HttpGetTimeoutSeconds --------------")
  list1 <- keyValueToList(configtbl,'HttpGetTimeoutSeconds')
  if( is.null(list1) ){
    config.HttpGetTimeoutSeconds<<-10 
  } else {
    config.HttpGetTimeoutSeconds<<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ CachePath ----------------")
  list1 <- keyValueToList(configtbl,'CachePath')
  if( is.null(list1) ){
    badCfg<-TRUE 
    config.CachePath<<-NULL
  } else {
    #I ultimately want a string
    config.CachePath<<- toString(list1[1])  
    config.CachePath<<-paste0(config.SiteSpecificContent,"/",config.CachePath)
  }
  
  
  #print("------------ EnableSpeciesInfoTab --------------")
  list1 <- keyValueToList(configtbl,'EnableSpeciesInfoTab')
  if( is.null(list1) ){
    config.EnableSpeciesInfoTab<<-1 #1=True, 0=False
  } else {
    config.EnableSpeciesInfoTab<<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ EnableMotusNewsTab --------------")
  list1 <- keyValueToList(configtbl,'EnableMotusNewsTab')
  if( is.null(list1) ){
    config.EnableMotusNewsTab<<-1 #1=True, 0=False
  } else {
    config.EnableMotusNewsTab<<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ EnableLearnAboutMotusTab --------------")
  list1 <- keyValueToList(configtbl,'EnableLearnAboutMotusTab')
  if( is.null(list1) ){
    config.EnableLearnAboutMotusTab<<-1 #1=True, 0=False
  } else {
    config.EnableLearnAboutMotusTab<<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ EnableSuspectDetectionFilter  --------------")
  list1 <- keyValueToList(configtbl,'EnableSuspectDetectionFilter')
  if( is.null(list1) ){
    config.EnableSuspectDetectionFilter<<-0  # 0=FALSE or 1=TRUE
  } else {
    config.EnableSuspectDetectionFilter<<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ VelocitySuspectMetersPerSecond  --------------")
  list1 <- keyValueToList(configtbl,'VelocitySuspectMetersPerSecond')
  if( is.null(list1) ){
    config.VelocitySuspectMetersPerSecond<<-20 
  } else {
    config.VelocitySuspectMetersPerSecond<<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ MapIconFlightDurationSeconds  --------------")
  list1 <- keyValueToList(configtbl,'MapIconFlightDurationSeconds')
  if( is.null(list1) ){
    config.MapIconFlightDurationSeconds<<-7 
  } else {
    config.MapIconFlightDurationSeconds<<- as.numeric(list1[1]) #assume length=1
  }
  
  #print("------------ LogLevel ----------------")
  list1 <- keyValueToList(configtbl,'LogLevel')
  if( is.null(list1) ){
    badCfg<-TRUE 
    config.LogLevel<<-LOG_LEVEL_WARNING
  } else {
    #I ultimately want a string
    config.LogLevel<<- toString(list1[1])  
  }
  
  result=switch(
    config.LogLevel,
    "LOG_LEVEL_DEBUG"=TRUE,
    "LOG_LEVEL_INFO"=TRUE,
    "LOG_LEVEL_WARNING"=TRUE,
    "LOG_LEVEL_ERROR"=TRUE,
    "LOG_LEVEL_FATAL"=TRUE,
    "LOG_LEVEL_NONE"=TRUE,
    FALSE
  )
  if(!result){
    message(paste0("Unrecognized log level in config file:", config.LogLevel))
    badCfg=TRUE
  }
  
  #print("------------ path to translations ----------------")
  config.TranslationsPath<<-paste0( config.SiteSpecificContent,"/data/translations")
  
  # Note this flag started out FALSE, if anything above failed
  # then it would have been set TRUE.
  return(badCfg) 
  
} #end getConfig()


##############################################################################################
#             print global config parameters
###############################################################################################
printConfig <- function() {
  
  TSprint(paste0("SiteSpecificContent:", config.SiteSpecificContent))
  TSprint(paste0("MainLogoFile:", config.MainLogoFile))
  TSprint(paste0("AdminContact",config.AdminContact))
  TSprint(paste0("MainTitleEnglish:",config.MainTitleEnglish))
  TSprint(paste0("MainTitleSpanish:",config.MainTitleSpanish))
  TSprint(paste0("MainTitleFrench:",config.MainTitleFrench))
  
  TSprint(paste0("MainLogoHeight:",config.MainLogoHeight))
  #TSprint(paste0("MainLogoTopOffsetPixels:",config.MainLogoTopOffsetPixels))
  
  TSprint(paste0("HomepageEnglish:",config.HomepageEnglish))
  TSprint(paste0("SpeciesPageEnglish:",config.SpeciesPageEnglish))
  TSprint(paste0("NewsPageEnglish:",config.NewsPageEnglish))
  TSprint(paste0("AboutMotusPageEnglish:",config.AboutMotusPageEnglish))
  
  TSprint(paste0("TitlebarTextColor:",config.TitlebarTextColor))
  TSprint(paste0("TitlebarBackgroundColor:",config.TitlebarBackgroundColor))
  
  TSprint(paste0("NavbarTextColor:",config.NavbarTextColor))
  TSprint(paste0("NavbarBackgroundColor:",config.NavbarBackgroundColor))
  TSprint(paste0("SelectedTabBackgroundColor:",config.SelectedTabBackgroundColor))
  TSprint(paste0("SelectedTabTextColor:",config.SelectedTabTextColor))
  
  TSprint(paste0("BodyPageBackgroundColor:",config.BodyPageBackgroundColor))
  TSprint(paste0("BodyPageTextColor:",config.BodyPageTextColor))
  TSprint(paste0("JumpToButtonColor:",config.JumpToButtonColor))
  TSprint(paste0("AppOpensToMap:",config.AppOpensToMap))
  
  for (i in seq_along(config.ReceiverDeployments)) {
    TSprint( paste0( "ReceiverDeployment ID [",i,"]:",config.ReceiverDeployments[i] ))
    #cat(i, ": ", x[i], "\n")
  }
  
  if ( is.list( config.ReceiverShortNames)) {
    for (i in 1:length(config.ReceiverShortNames)) {
      TSprint( paste0( "ReceiverShortName[",i,"]:",config.ReceiverShortNames[[i]] ))
    }
  }
  
  TSprint(paste0("MovingMarkerIcon:",config.MovingMarkerIcon))
  
  TSprint(paste0("MovingMarkerIconWidth:",config.MovingMarkerIconWidth))
  
  TSprint(paste0("MovingMarkerIconHeight:",config.MovingMarkerIconHeight))
  
  TSprint(paste0("InactivityTimeoutSeconds:",config.InactivityTimeoutSeconds))
  
  TSprint(paste0("CheckMotusIntervalMinutes:",config.CheckMotusIntervalMinutes))
  
  TSprint(paste0("EnableReadCache:",config.EnableReadCache))
  
  TSprint(paste0("EnableWriteCache:",config.EnableWriteCache))
  
  TSprint(paste0("ActiveCacheAgeLimitMinutes:",config.ActiveCacheAgeLimitMinutes))
  
  TSprint(paste0("InactiveCacheAgeLimitMinutes:",config.InactiveCacheAgeLimitMinutes))
  
  TSprint(paste0("CachePath:", config.CachePath))
  
  TSprint(paste0("LogLevel:", config.LogLevel))
  
  TSprint(paste0("HttpGetTimeoutSeconds:", config.HttpGetTimeoutSeconds))
  
  TSprint(paste0("EnableSpeciesInfoTab:", config.EnableSpeciesInfoTab))
  
  TSprint(paste0("EnableMotusNewsTab:", config.EnableMotusNewsTab))
  TSprint(paste0("EnableLearnAboutMotusTab:", config.EnableLearnAboutMotusTab))
  
  TSprint(paste0("EnableSuspectDetectionFilter:",config.EnableSuspectDetectionFilter))
  TSprint(paste0("VelocitySuspectMetersPerSecond:",config.VelocitySuspectMetersPerSecond))
  
  TSprint(paste0("MapIconFlightDurationSeconds:",config.MapIconFlightDurationSeconds))

  return()
  
} #end printConfig()