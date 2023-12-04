###############################################################################
# Copyright 2022-2023 Richard Schramm
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

# This app's structure utilizes techniques for creating a multilanguage
# modularized app as described by Eduard Parsadanyan in his article at: 
# https://www.linkedin.com/pulse/multilanguage-shiny-app-advanced-cases-eduard-parsadanyan/
# and was learned via exploring his ClinRTools modularized demo found at:
# https://bitbucket.org/satsconsult/clinrtoolsdemo/src/master/

# 
# Dashboard sources all modules
# Each module has it's own UI and Server part
# Additionally, common module UI is called for each module (output, source code, system version)
# 

# Add all server functions from each module here
server <- function(input, output, session) {

  # Load translations
  # setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
  
  session$sendCustomMessage("color_change",config.NavbarColor)

  #suppress translator warning re. 'no translation yaml file' 
  warn = getOption("warn")
  options(warn=-1)
  #message(paste0("In server.R config.TranslationsPath:", config.TranslationsPath))
  i18n <- Translator$new(translation_csvs_path = config.TranslationsPath,
                       separator_csv="|")
  options(warn=warn)
  
  i18n$set_translation_language(default_UI_lang)
  
  ##############################################################
  #reactive variable for displaying motus on/off status on GUI
  #result<-receiverDeploymentDetails(defaultReceiverID, useReadCache=0) 
  #this creates and sets a global variable 'motus' to be a reactive value so
  #it can be observed

  motusServer<<-reactiveValues(status=FALSE,
               msg=paste("<span style=\"background-color:#fffb00\">MotusStatus:Unknown</span>"))

  # this binds the observer (an output widget) to the reactive value
  output$motusState<-renderText({motusServer$msg})

  ##############################################################
  #reactive timer to go test Motus periodically to see if online
  #autoInvalidate <- reactiveTimer(numCheckMotusUpIntervalSeconds) #60 seconds
  millisecs <- config.CheckMotusIntervalMinutes*60*1000 #milliseconds #see config file settings
  autoInvalidate <- reactiveTimer(millisecs)
  
  # render the versioning text string set in global.R to the
  # main page footer output
  output$footer<-renderText({gblFooterText})
  
# this button is for debugging 
#if you enable the observer here, also enable it in the ui.R
#  observeEvent(input$btnCommand, { 
#    WarningPrint("Button pressed.")
#  })
  
  
  #watch for timer to fire, reset it  and then go check on motus
  #sets reactive (global) variable
  observe({
    ## Invalidate and re-execute this reactive expression
    ## every time the timer fires.
    DebugPrint("Timer fired.")
    autoInvalidate()
    
    # result<-receiverDeploymentDetails(defaultReceiverID, useReadCache=numEnableCache) 
    # for the purpose of testing if Motus.org is up, we dont want to use cache to
    # force the function to hit the remote server.
    start_time <- Sys.time()
    result<-receiverDeploymentDetails(defaultReceiverID, useReadCache=0) #dont care about cache age...
    end_time <- Sys.time()
    elapsedtime=(end_time-start_time)
    InfoPrint(paste0("Back from html call - Elapsed time:",elapsedtime," secs"))
    
    if(nrow(result) > 0){
        if( motusServer$status == FALSE){ 
           WarningPrint("Motus status changed to online.")
           motusServer$status<<-TRUE 
           motusServer$msg<<-paste("<span style=\"background-color:#8aff0c\">MotusStatus:Online</span>")
        }
     
    } else { #is the empty_df
        if( motusServer$status == TRUE){
           WarningPrint("Motus status changed to offline due (no response timeout).")
           motusServer$status<<-FALSE
           motusServer$msg<<-paste("<span style=\"background-color:#fffb00\">MotusStatus:Offline</span>")
        }
    }

    
  })
  
  
  # On inactivity timeout, reset the dashboard UI to startup defaults
  observeEvent(input$timeOut, { 
    #print(paste0("Session (", session$token, ") timed out at: ", Sys.time()))
    session$reload()
  })
  

  # Language picker
  observeEvent(input$lang_pick, {
    # 07Feb2023 workaround bug found in shiny.i18n package update_lang() function
    # order of arguments reversed issue.. specify arguments by name instead of
    # by position.
    update_lang(session=session, language=input$lang_pick)
    

    
    #choose the correct homepage given language selected on UI
    x=input$lang_pick
    xxx = config.HomepageEnglish
    if(x=='en'){
      thefile<-xxx 
    } else if (x=='es'){ 
      thefile<-str_replace(xxx,"_en.html","_es.html")
    } else if (x=='fr'){ 
      thefile<-str_replace(xxx,"_en.html","_fr.html")
    } 
    
    if (!file.exists(thefile)) {
      message(paste0("LANGUAGE SPECIFIC FILE IS MISSING, USING DEFAULT HOMEPAGE FILE"))
      if(x=='en'){
        thefile <- paste0("www/DEFAULT/homepages/default_homepage_en.html") 
      } else if (x=='es'){ 
        thefile <- paste0("www/DEFAULT/homepages/default_homepage_es.html")
      } else if (x=='fr'){ 
        thefile <- paste0("www/DEFAULT/homepages/default_homepage_fr.html")
      } 
    }
    ###message(paste0("THEFILE:",thefile))
    ###thepage <-includeHTML(as.character(thefile))
    ###fixpath<-paste0("<img src=\"", "../", config.SiteSpecificContent, "/homepages/images/")
    #### message(fixpath)
    ###thepage<-str_replace(thepage,'<img src="images/', fixpath)
    
    
    #tx <-includeHTML(as.character(thefile))
    #tx2  <- gsub(pattern = "src=\"images", replace = "src=\"../AHNC/homepages/images", x = tx)
    
    
    
    ###fixpath<-paste0("<img src=\"", "../", config.SiteSpecificContent, "/homepages/images/")
    #### message(fixpath)
    ###thepage<-str_replace(thepage,'<img src="images/', fixpath)

    DebugPrint(paste0("********* the HOMEPAGE:",thefile, "  ************"))
    # Refresh homepage file on the main home page tab of the navbar
    removeUI(selector ="#readmediv", immediate = TRUE)
    insertUI(immediate = TRUE,
             selector = '#readmehere', session=session,
             ui = div(id="readmediv",
             includeHTML(thefile)
             )
    )
 
    # need to make sure the aboutMotus image gets set to correct language
    # even if its tab is not currently selected (exposed)
    xxx <- as.character(i18n$get_translations()["ui_about_motus_default",input$lang_pick])
    output$about_motus <- renderUI({
      img(src=xxx, height='95%')
    })
    
    # show the main title in selected language
    if(x=='en'){
      titletext<-config.MainTitleEnglish  
    } else if (x=='es'){ 
      titletext<-config.MainTitleSpanish
    } else if (x=='fr'){ 
      titletext<-config.MainTitleFrench
    } else {
      titletext<-config.MainTitleEnglish 
    }
    output$main_page_title<-renderText({
      dynamic_title <- input$receiver_pick
      paste(titletext, dynamic_title)})
    
  })  #end observeEvent langpick
  
  
  # the receiver picker input reactive observer need to update
  # the main page title when a new receiver is picked
  # note the SERVER_ReceiverDetections() also has an event observer for
  # this input, see ReceiverDetections.R
  observeEvent(input$receiver_pick, {
    #choose the correct homepage given language selected on UI
    x=input$lang_pick
    if(x=='en'){
      titletext<-config.MainTitleEnglish  
    } else if (x=='es'){ 
      titletext<-config.MainTitleSpanish
    } else if (x=='fr'){ 
      titletext<-config.MainTitleFrench
    } else {
      titletext<-config.MainTitleEnglish 
    }
    
    output$main_page_title<-renderText({
      dynamic_title <- input$receiver_pick
      paste(titletext, dynamic_title)})
    
  })  #end observeEvent input$receiver_pick
  
  #mainlogo = paste0(config.SiteSpecificContent,"/",config.MainLogoFile)
  #mainlogo = paste0(config.SiteSpecificContent,"/",config.MainLogoFile)
  #DebugPrint(paste0("********** MAIN LOGO:", mainlogo))
  
  
  # Pass language selection into the module for Server-side translations
  # If not done, some UI elements will not be updated upon language change
  # Also pass the receiver picker as it will need to be observed by a reactive
  # event in SERVER_ReceiverDetection also
 SERVER_ReceiverDetections("ReceiverDetections"  ,i18n_r = reactive(i18n), lang = reactive(input$lang_pick), rcvr= reactive(input$receiver_pick))
 SERVER_MotusNews("MotusNews",i18n_r = reactive(i18n), lang = reactive(input$lang_pick), rcvr= reactive(input$receiver_pick))
 SERVER_AboutMotus("AboutMotus",i18n_r = reactive(i18n), lang = reactive(input$lang_pick))
 }

