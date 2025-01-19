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
  #suppress translator warning re. 'no translation yaml file' 
  warn = getOption("warn")
  options(warn=-1)
  # print(paste0("In server.R config.TranslationsPath:", config.TranslationsPath))
  i18n <- Translator$new(translation_csvs_path = config.TranslationsPath,
                       separator_csv="|")
  options(warn=warn)
  
  i18n$set_translation_language(default_UI_lang)
  

  ##############################################################
  #reactive variable for displaying motus on/off status at bottom of GUI
  #this creates and sets a global variable 'motusServerStatusReactive1'
  # to be a reactive value so it can be observed and bound to a ui element
  # Note: these reactives are recreated whenever the touchscreen/mouse
  # inactivity timer fires which causes a session$reload()
  
  motusServerStatusReactive1<<-reactiveValues(
       status=FALSE,
       msg=paste("MotusStatus:Unknown") )
  
       # this binds the observer (an output widget) to the reactive value
       output$motusState<-renderUI({
         msg <- motusServerStatusReactive1$msg
         background_color <- if (msg == "MotusStatus:Online") "lawngreen" else "yellow"
         div(class = "motus-state",
             style = paste("background-color:", background_color, "; color: black; padding: 5px;"),
             msg
         )
       })
         
      

  ############################################################## 
  # another reactive variable and it's bound ui element followed
  # by a function that can be called withing the server at
  # points that need to update the status and its bound control
  motusServerStatusReactive2<<-reactiveValues( status=FALSE, msg = paste("status unknown") )
  #output$main_page_subtitle<-renderText(motusServerStatusReactive2$msg)  #bind the msg to the UI control
  output$headerbar_text<-renderText(motusServerStatusReactive2$msg)  #bind the msg to the UI control
  ##############################################################
  # Function to manage the motusServerStatusReactive2 message
  # when it changes
  manageTitlebarMotusStatusMessage <- function(value=TRUE) {
    x=input$lang_pick
    motusServerStatusReactive2$status<<-value
    if(value){
       s <- paste("")
    } else {
       if(x=='en'){
          s<-"Warning: The Motus.org data server is temporarily offline or unreachable."
       } else if (x=='es'){ 
          s<-"Lo sentimos, el servidor de datos de Motus.org está temporalmente inaccesible."
       } else if (x=='fr'){ 
          s<-"Désolé, le serveur de données Motus.org est temporairement inaccessible."
       } else {
         s<-"languge not recognized"
       }
    }
    #update the reactive variable that causes the bound UI elements to render
    motusServerStatusReactive2$msg<<-paste(s)  
  }
  
 ##############################################################
  #reactive timer to go test Motus.org periodically to see if online.
  millisecs <- config.CheckMotusIntervalMinutes*60*1000 #milliseconds #see config file settings
  autoInvalidate <- reactiveTimer(millisecs)

  if(config.AppOpensToMap == 0){ 
    
  } else {
    updateNavbarPage(session, inputId = "navbartabset", selected = "panel2")
    updateTabsetPanel(session, inputId = "detectedtaginfotabset", selected = "tagflightmaptab")
  }
  
  ##############################################################    
  # render the versioning text string set in global.R to the
  # main page footer output
  #output$footer<-renderText({gblFooterText})
  ###output$versionInfo<-renderText({gblFooterText})

  # Set the footer version message
  # note this one is a uiOutput
  output$versionInfo <- renderUI({
    # div(class = "versionInfo", gblFooterText)
    div(class = "version-info", gblFooterText)
  })

  # Switch to "Receivers -> Flight Map" tab when the button is pressed
  observeEvent( input$gotoMap, {
    updateNavbarPage(session, inputId = "navbartabset", selected = "panel2")
    updateTabsetPanel(session, inputId = "detectedtaginfotabset", selected = "tagflightmaptab")
  }) #end observeEvent

 ##############################################################  
 # this button is for debugging 
 # if you enable the observer here, also enable th button in ui.R
  observeEvent(input$btnCommand, {
 # add your code here...
    WarningPrint("Button pressed.")
    mytoggle<<-!mytoggle  #a variable declared in global.R
})
  
  
  ##############################################################  
  #watch for the timer to fire, reset it and then go check on
  #motus.org Note its sets reactive (global) variable
  observe({
    ## Invalidate and re-execute this reactive expression
    ## every time the timer fires.
    DebugPrint("Timer fired.")
    autoInvalidate()
    
    # result<-receiverDeploymentDetails(defaultReceiverID, useReadCache=numEnableCache) 
    # for the purpose of testing if Motus.org is up, we dont want to use cache to
    # force the function to hit the remote server.
    # start_time <- Sys.time()
    result<-receiverDeploymentDetails(defaultReceiverID, useReadCache=0) #dont care about cache age...
    # end_time <- Sys.time()
    # elapsedtime=(end_time-start_time)
    # InfoPrint(paste0("Back from html call - Elapsed time:",elapsedtime," secs"))
    
    #Note to self: motusServer is a reactive variable that is bound to the UI htmlOutput("motusState") 
    
    if(nrow(result) > 0){
        if( motusServerStatusReactive1$status == FALSE){ 
           WarningPrint("Motus status changed to online.")
           motusServerStatusReactive1$status<<-TRUE 
           motusServerStatusReactive1$msg<<-paste("MotusStatus:Online")
           manageTitlebarMotusStatusMessage(TRUE)
        }
     } else { #is the empty_df
        if( motusServerStatusReactive1$status == TRUE){
           WarningPrint("Motus status changed to offline due (no response timeout).")
           motusServerStatusReactive1$status<<-FALSE
           motusServerStatusReactive1$msg<<-paste("MotusStatus:Offline")
           manageTitlebarMotusStatusMessage(FALSE)
        }
     } #end else
  }) #end timer observe()
  
  ############################################################## 
  # On mouse/touchscreen inactivity timeout, 
  # reset the dashboard UI to startup defaults
  observeEvent(input$timeOut, { 
    #print(paste0("Session (", session$token, ") timed out at: ", Sys.time()))
    session$reload()
  })
  
  ##############################################################
  # Language picker change event
  # all the UI elements that need to change if the language changes
  ##############################################################
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

    #DebugPrint(paste0("********* the HOMEPAGE:",thefile, "  ************"))
    # Refresh homepage file on the main home page tab of the navbar
    removeUI(selector ="#homepagediv", immediate = TRUE)
    insertUI(immediate = TRUE,
             selector = '#homepagehere', session=session,
             ui = div(id="homepagediv",
             includeHTML(thefile)
             )
    )
 
    # need to make sure the 'About Motus' image gets set to correct language
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
    
    updateActionButton(session, "gotoMap", label = i18n$t("ui_jump_to_button_text"))
    
    output$available_receivers<-renderText({  i18n$t("ui_mainpage_available_receivers") })
    
    xxx <- as.character(i18n$get_translations()["ui_about_motus_default",input$lang_pick])
    
    gblMainTabName <<- as.character(i18n$get_translations()["ui_RCVR_title",input$lang_pick])
    gblMapTabName <<- as.character(i18n$get_translations()["ui_RCVR_detections_leaflet_tab_label",input$lang_pick])
    
    #manage the titlebar message using what ever the current status is
    manageTitlebarMotusStatusMessage(motusServerStatusReactive2$status)
    
}) #end language picker change event
  
##############################################################
# receiver picker input reactive observer
##############################################################
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
  
  
  # Observe tab change to hide/show "gotoMap" button
  observe({
    if (input$navbartabset == "panel2") { # Check the value of the selected tab
      shinyjs::hide("gotoMap")
    } else {
      shinyjs::show("gotoMap")
    }
  })
  
  # Dynamically update the CSS variables for the desired colors etc
  s <- paste0(config.MainLogoHeight,"px")
  shinyjs::runjs(sprintf("document.documentElement.style.setProperty('--titlebar-logo-height', '%s');", s))

  shinyjs::runjs(sprintf("document.documentElement.style.setProperty('--titlebar-text-color', '%s');", config.TitlebarTextColor ))
  shinyjs::runjs(sprintf("document.documentElement.style.setProperty('--titlebar-background-color', '%s');", config.TitlebarBackgroundColor ))
  shinyjs::runjs(sprintf("document.documentElement.style.setProperty('--navbar-text-color', '%s');", config.NavbarTextColor ))
  shinyjs::runjs(sprintf("document.documentElement.style.setProperty('--navbar-background-color', '%s');", config.NavbarBackgroundColor ))
  shinyjs::runjs(sprintf("document.documentElement.style.setProperty('--base-page-background-color', '%s');", config.BodyPageBackgroundColor ))
  shinyjs::runjs(sprintf("document.documentElement.style.setProperty('--selected-tab-background-color', '%s');", config.SelectedTabBackgroundColor ))
  shinyjs::runjs(sprintf("document.documentElement.style.setProperty('--selected-tab-text-color', '%s');", config.SelectedTabTextColor ))
  shinyjs::runjs(sprintf("document.documentElement.style.setProperty('--base-page-text-color', '%s');", config.BodyPageTextColor ))
  shinyjs::runjs(sprintf("document.documentElement.style.setProperty('--jump-to-button-color', '%s');", config.JumpToButtonColor ))
  shinyjs::runjs(sprintf("document.documentElement.style.setProperty('--offline-text-color', '%s');", "darkorange" ))

  # Pass language selection into the module for Server-side translations
  # If not done, some UI elements will not be updated upon language change
  # Also pass the receiver picker as it will need to be observed by a reactive
  # event in SERVER_ReceiverDetection also
 SERVER_ReceiverDetections("ReceiverDetections"  ,i18n_r = reactive(i18n), lang = reactive(input$lang_pick), rcvr= reactive(input$receiver_pick))
 SERVER_MotusNews("MotusNews",i18n_r = reactive(i18n), lang = reactive(input$lang_pick), rcvr= reactive(input$receiver_pick))
 SERVER_AboutMotus("AboutMotus",i18n_r = reactive(i18n), lang = reactive(input$lang_pick))
 

 }

