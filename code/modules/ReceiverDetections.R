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

# This app's structure utilizes techniques for creating a multilanguage
# modularized app as described by Eduard Parsadanyan in his article at: 
# https://www.linkedin.com/pulse/multilanguage-shiny-app-advanced-cases-eduard-parsadanyan/
# and was learned via exploring his ClinRTools modularized demo found at:
# https://bitbucket.org/statsconsult/clinrtoolsdemo/src/master/


#####################
#      UI PART      #
#####################
library(DT)

library(anytime)


UI_ReceiverDetections <- function(id, i18n) {
  
  ns <- NS(id)
  
  fluidPage(
    
    useShinyjs(),
    
    tags$head(
      tags$style(HTML("hr {border-top: 1px solid #000000;}"))
    ),
    
    titlePanel(
      span(
        div(
          textOutput("table_title"),
          i18n$t("ui_RCVR_title"), 
          style="display:inline-block;vertical-align:top;text-align:right !important;color:#8FBC8F;font-style: italic;font-size: 25px; background-color:white",
          #style="color:#8FBC8F;font-style: italic;font-size: 25px; background-color:white",
        ), #end div

        div(
          shinyjs::hidden(checkboxInput(ns("enablefilter"), label=i18n$t("ui_filter_velocity_checkbox_label"), value = FALSE, width = NULL)),
          style="display:inline-block;position:absolute;right:2em;vertical-align:top;text-align:right!important;color:#8FBC8F;font-style: italic;font-size: 18px;",
        ), #end div
        
      ) # end span1
    ), #end titlepanel
    
    #), #end fluid row
    
    sidebarLayout(
      sidebarPanel(width = 4,
                   #hr(),
                   #helpText(i18n$t("ui_RCVR_input_requery_label_help_text")),
                   #actionButton(ns("btnCalculate"),i18n$t("ui_RCVR_input_requery_button_caption")),
                   #p(),
                   DT::dataTableOutput( ns('mytable') )
                   
      ),
      mainPanel(width = 8,
                
                tabsetPanel(type = "tabs",
                            tabPanel(i18n$t("ui_RCVR_detections_details_tab_label"), 
                                     helpText(i18n$t("ui_RCVR_detections_details_tab_helptext")),
                                     DT::dataTableOutput( ns('tagdetail') )
                            ),
                            tabPanel(i18n$t("ui_RCVR_detections_flightpath_tab_label"), 
                                     helpText(i18n$t("ui_RCVR_detections_flightpath_tab_helptext")),
                                     DT::dataTableOutput( ns('flightpath') )
                                     
                            ),
                            
                            # Implement a map using leaflet
                           
                            # In v4.x, we needed both this tag style and the leafletOutput as shown rurther below.
                            # but this tag$style line causes the warning:
                            #  Warning: Navigation containers expect a collection of `bslib::nav_panel()`/`shiny::tabPanel()`s and/or `bslib::nav_menu()`/`shiny::navbarMenu()`s.
                            #  Consider using `header` or `footer` if you wish to place content above (or below) every panel's contents.
                            # tags$style(type = "text/css", paste0("#",ns('leaflet_map')), "{height: calc(100vh - 425px) !important;}"),
                            
                            #NOTE: vh = viewport height
                            
                            tabPanel(i18n$t("ui_RCVR_detections_leaflet_tab_label"), 
                                     helpText(i18n$t("ui_RCVR_detections_leaflet_tab_helptext")),
                                     actionButton( ns("fly"),    label = i18n$t("ui_RCVR_fly_button_caption")),
                                     actionButton( ns("stop"),   label = i18n$t("ui_RCVR_stop_button_caption")),
                                     actionButton( ns("pause"),  label = i18n$t("ui_RCVR_pause_button_caption")),
                                     actionButton( ns("resume"), label = i18n$t("ui_RCVR_resume_button_caption")),
                                     
                                     #vsn4.x #leafletOutput(ns("leaflet_map"), width = "100%", height="100%")
                                     # Height as percentage does not work, because the dashboardBody
                                     # has undefined height. But relative to the whole document is okay. 
                                     leafletOutput(ns('leaflet_map'), width = "100%", height="65vh")
                                     #leafletOutput(ns('leaflet_map'), width = "100%", height="60vh")
                                     
                            ),
                            
                            # enable this for the species tab
                            if(config.EnableSpeciesInfoTab) {
                              tabPanel( i18n$t("ui_RCVR_detections_species_tab_label"), 
                                        htmlOutput(ns("species"))
                              ) } #end tabPanel species
                            
                ) #end tabsetPanel            
      ) #end mainPanel
    ) # end sidebarLayout
  ) #end fluidPage
}  # end function def for UI_ReceiverDetections

#####################
#    SERVER PART    #
#####################

SERVER_ReceiverDetections <- function(id, i18n_r, lang, rcvr) {
  
  moduleServer(id, function(input, output, session) {
    
    # !!! session$ns is needed to properly address reactive UI elements from the Server function
    ns <- session$ns
    
    #show or hide the enablefilter checkbox on the UI
    if(config.EnableSuspectDetectionFilter==0){
      shinyjs::hide("enablefilter")
    } else {
      shinyjs::show("enablefilter")
    }
    
    #print("-----Initial selected species - module global scope -------------------")
    selected_species <- "unknown"
    species_key <- "unknown"
    
    # moved resourcepath for images/icons to global 
    
    birdIcon <- makeIcon(
      iconUrl = paste0(config.MovingMarkerIcon),
      iconWidth = config.MovingMarkerIconWidth, iconHeight = config.MovingMarkerIconHeight,
      iconAnchorX = 0, iconAnchorY = 0,
      shadowUrl = config.MovingMarkerIcon,
      shadowWidth = config.MovingMarkerIconWidth, shadowHeight = config.MovingMarkerIconHeight,
      shadowAnchorX = 0, shadowAnchorY = 0
    )
    
    # observer of the enablefilter control (checkbox)
    observeEvent(input$enablefilter, {
      updateDetectionsUI()
    })
    
    ################### methods to control MovingMarkers (bird in flight)
    observeEvent(input$fly, {
      proxy <- leafletProxy("leaflet_map")
      leaflet::invokeMethod(proxy,NULL,"startMoving","movingmarker")
    })
    
    observeEvent(input$pause, {
      proxy <- leafletProxy("leaflet_map")
      leaflet::invokeMethod(proxy,NULL,"pauseMoving","movingmarker")
    })
    
    observeEvent(input$resume, {
      proxy <- leafletProxy("leaflet_map")
      leaflet::invokeMethod(proxy,NULL,"resumeMoving","movingmarker")
    })
    
    observeEvent(input$stop, {
      proxy <- leafletProxy("leaflet_map")
      leaflet::invokeMethod(proxy,NULL,"stopMoving","movingmarker")
    })
    
    #####################################################################
    
    # Some code for UI observers, 
    #-------------------------------------------------------------------------------------------------------------
    #   
    #------------------------------------------------------------------------------------------------------------- 
    # function to take the species key and the current language setting and try
    # to load a species info html file containiong a photo and some interesting facts
    # about the currently selected bird 
    
    updateSpeciesInfo <- function() {    
      DebugPrint("entered update species")
      #file like "/Users/rich/Projects/MOTUS_KIOSK/www/speciespages/species_unknown_en.html") 
      #message("in updateSpeciesInfo get language for species as x")  
      x=lang()
      xxx = config.SpeciesPageEnglish
      
      #substitute the word 'unknown' in the filename with the species key
      DebugPrint(paste0("updatespecies lang is ",x))
      
      xxx <- str_replace(xxx,"unknown",species_key)
      if(x=='en'){
        thefile<-xxx 
      } else if (x=='es'){ 
        thefile<-str_replace(xxx,"_en.html","_es.html")
      } else if (x=='fr'){ 
        thefile<-str_replace(xxx,"_en.html","_fr.html")
      } 
      DebugPrint(paste0("updatespecies test a file"))
      # 'thefile' path is determined by addResourcePath defined in global.R
      # but we test for the existence of the actual file using 'project relative' path 
      testfile<<-paste0(config.SiteSpecificContentWWW,"/",thefile)
      if (!file.exists(testfile)) {
        message("species page is missing, substitute a default unknown file")
        thefile <- paste0("speciespages/species_unknown_en.html")
      } 
      
      DebugPrint(paste0("updatespecies render the file"))
      
      # before upgrade to R v 4.3.1 these workd,  after 
      # got: # Warning: `includeHTML()` was provided a `path` that appears to be a complete HTML document
      # so change below I to do it to an iframe.
      #thepage=includeHTML(thefile)
      #output$species <- renderUI(thepage)
      # note the prior need a project relative path, now its a www relative path set in addResourcePath
      # of global.R
      output$species <- renderUI({
        tags$iframe(seamless="seamless", src=thefile, style='width:100%;height:100vh;')
      })
      
      DebugPrint(paste0("exit updateSpecies"))
    } #end updateSpeciesInfo()
    
    #-------------------------------------------------------------------------------------------------------------
    #   
    #-------------------------------------------------------------------------------------------------------------  
    # A non-reactive function that will be available to each user session
    # populate global detections_df and detections_subset_df as needed and render to sidebar table
    myTagsToTable <- function(x) {
      
      #note <<- is assignment to global variable, also note receiverDeploymentID is global
      #detections_df <<- receiverDeploymentDetections(receiverDeploymentID)
      detections_df <<- receiverDeploymentDetections(receiverDeploymentID, config.EnableReadCache, config.ActiveCacheAgeLimitMinutes, withSpinner=FALSE,spinnerText=usespinnertext)
      if(nrow(detections_df)<=0) {  # failed to get results... try the inactive cache
        DebugPrint("receiverDeploymentDetections request failed - try Inactive cache")
        detections_df <<- receiverDeploymentDetections(receiverDeploymentID, config.EnableReadCache, config.InactiveCacheAgeLimitMinutes, withSpinner=FALSE,spinnerText=usespinnertext)
      }
      
      remove_modal_spinner() #shown by receiverDeploymentDetections
      
      DebugPrint("back from receiverDeploymentDetection.. results follow ")
      
      if( !is.data.frame(detections_df)){
        DebugPrint("receiverDeploymentDetections failed to return a dataframe... exit function")
        return()
      }
      
      DebugPrint("sort the detections")
      #sort detections so most recent appears at top of list notice we are working with a global variable ( <<- )
      detections_df <<- detections_df[ order(detections_df$tagDetectionDate,decreasing = TRUE), ]
      DebugPrint("back sort.. results follow ")
      #str(detections_df)
      
      #subset the data frame to form a frame with only the columns we want to show
      # note also it's a global assignment 
      detections_subset_df<<-detections_df[c("tagDetectionDate", "tagDeploymentID","species" )]
      
      DebugPrint("back from subset.. results follow ")
      #str(detections_subset_df)
      
      output$mytable <- DT::renderDataTable(detections_subset_df,
                                            selection = list(mode = 'single',
                                                             selected = c(1) ),
                                            extensions = c('ColReorder', 'FixedHeader', 'Scroller'),
                                            colnames = c("Date", "TagDepId", "Species") ,
                                            rownames=FALSE,
                                            options=list(dom = 'Bfrtip',
                                                         searching = F,
                                                         pageLength = 25,
                                                         searchHighlight = TRUE,
                                                         colReorder = TRUE,
                                                         fixedHeader = TRUE,
                                                         filter = 'bottom',
                                                         #buttons = c('copy', 'csv','excel', 'print'),
                                                         paging    = TRUE,
                                                         deferRender = TRUE,
                                                         scroller = TRUE,
                                                         scrollX = TRUE,
                                                         scrollY = 700
                                            ))
      
      DebugPrint("back from output table ")
    } # end function myTagsToTable
    
    #-------------------------------------------------------------------------------------------------------------
    #   
    #-------------------------------------------------------------------------------------------------------------  
    
    observeEvent( session$clientData, {
      #  message("**session started ***")
      DebugPrint("enter session started observerEvent")
      myTagsToTable()
      DebugPrint("session started observerEvent back from tags to table,,, exiting event")
    }) #end observeEvent for session start
    
    #-------------------------------------------------------------------------------------------------------------
    #   
    #-------------------------------------------------------------------------------------------------------------    
    ## requery motus button has been commented out as it was only for testing
    #  observeEvent(input$btnQuery, {
    #   message("**query button pressed ***")
    #   myTagsToTable()
    #  }) #end observeEvent for for requery button
    
    
    #-------------------------------------------------------------------------------------------------------------
    #   
    #------------------------------------------------------------------------------------------------------------- 
    # Some UI elements should be updated on the Server side:
    # Update text values when language is changed
    #note lang() is handle to the language input picklist passed in from server.R
    observeEvent(lang(), {
      i18n_r()$set_translation_language(lang())
      #message("-----observeevent(lang()------")
      #print(lang())
      #message("----------")
      
      # this is a hack, we want the spinner in tagDeploymnmentDetections.R to be mulitlingual
      # but the translator item is not passed in to that function...so we pass in this text
      x=lang()
      if(x=='en'){
        usespinnertext<<-"Requesting data."
      } else if (x=='es'){ 
        usespinnertext<<-"Solicitando datos."
      } else if (x=='fr'){ 
        usespinnertext<<-"Demander des données."
      } 
      
      updateSpeciesInfo()
    }) #end observeEvent(lang()
    
    #-------------------------------------------------------------------------------------------------------------
    #   
    #------------------------------------------------------------------------------------------------------------- 
    updateDetectionsUI <- function() {  
      
      
      
      #see:https://stackoverflow.com/questions/55799093/select-and-display-the-value-of-a-row-in-shiny-datatable   
      selectedrowindex <- input$mytable_rows_selected
      selectedrowindex <- as.numeric(selectedrowindex)
      selectedrow <- paste(detections_subset_df[selectedrowindex,],collapse = ", ")
      
      #this could return NA id the subset is empty... we will have to trap
      #those below by testing this value
      DebugPrint("entered updateDetectionsUI")
      tagDepID <- detections_subset_df[selectedrowindex,2]
      
      DebugPrint("updateDetectionsUI test tagDepID")
      DebugPrint(paste0( "class:", class(tagDepID)))
      DebugPrint(paste0( "value:", tagDepID))
      DebugPrint(paste0( "is_empty:", is_empty(tagDepID)   ))
      if(is_empty(tagDepID)){ #just return, nothing to do.. happens on startup
        DebugPrint("updateDetectionsUI just return()")
        return()
      }
      
      #updating the species information tab.
      #when a new row is selected in the tag deployments table
      #extract the selected species name and see if we can build a species name 'key'
      #that updateSpeciesInfo() can substitute into the default 'species_unknown_xx,html'
      #filename to pull in a new html file documenting the the species.
      # NOTE: global assignment operator as species_key is needed outside of this
      # functions scope 
      
      #get the selected species and strip unwanted chars and then lowercase() it
      #e.g."Swainson's Thrush" becomes key = "swainsonsthrush"
      selected_species <- detections_subset_df[selectedrowindex,3]
      #no special chars
      species_key <<- gsub('[^[:alnum:] ]','',selected_species)
      #no tabs or newline
      species_key <<- gsub('[\t\n]','',species_key)
      #no spaces
      species_key <<- gsub(' ','', species_key)
      #lowercase
      species_key <<- tolower(species_key)
    
      DebugPrint("calling updateSpeciesInfo")
      updateSpeciesInfo()
      DebugPrint("back from updateSpeciesInfo")
  

      if (is.na(tagDepID )) {
        DebugPrint("input$mytable_rows_selected observeEvent() - is.na tagDepID")
        ####mydf <- data.frame( matrix( ncol = 9, nrow = 1) )
        ###colnames(mydf) <- c('tagid', 'project', 'contact', 'started','species','lat','lon','ndays', 'nreceivers')
        ###tagdetails_df <- mydf
        tagdetails_df <- empty_tagDeploymentDetails_df()
      } else {
        DebugPrint(paste0("input$mytable_rows_selected observeEvent() - else calling tagDeploymentDetails w/tagDepID=",tagDepID))
        #next get and render the tagDeploymentDetails (who tagged, where, when etc)
        tagdetails_df <- tagDeploymentDetails(tagDepID, config.EnableReadCache, config.ActiveCacheAgeLimitMinutes)
        DebugPrint("back from tagDeploymentDetails")
        
        if(nrow(tagdetails_df)<=0) {  # failed to get results from active cache so try the inactive cache
          DebugPrint("tagDeploymentDetails request failed - try Inactive cache")
          tagdetails_df <- tagDeploymentDetails(tagDepID, config.EnableReadCache, config.InactiveCacheAgeLimitMinutes)
        }
        
        if(nrow(tagdetails_df)<=0) {  # still failed to get results from via the inactive cache
          DebugPrint("tagDeploymentDetails request from Inactive cache failed, set to empty df")
          tagdetails_df <- empty_tagDeploymentDetails_df()
        }
        
      }
      
      DebugPrint("input$mytable_rows_selected observeEvent() - renderTable")
      output$tagdetail <- DT::renderDataTable(tagdetails_df,
                                              selection = "single", 
                                              options=list(dom = 'Bfrtip',
                                                           searching = F,
                                                           language = list(zeroRecords = "No records to display - Motus.org possibly offline.")
                                              ) #end options
      ) #end renderDataTable()
      
      # trap for rare edge case for when motus.org is offline and the InactiveCache returns nothing 
      if(nrow(tagdetails_df)<=0){
        tagflight_df<-empty_tagDeploymentDetection_df()
        output$flightpath <- DT::renderDataTable(tagflight_df,
                                                 selection = "single", 
                                                 options=list(dom = 'Bfrtip',
                                                              searching = F,
                                                              "pageLength" = 18,
                                                              language = list(zeroRecords = "No records to display - Motus.org possibly offline.")
                                                 ) #end options
        ) #end renderDataTable()
        
        
        
        myLeafletMap = leaflet() %>% addTiles() #render the empty map
        output$leaflet_map = renderLeaflet(myLeafletMap) 
        DebugPrint("tagdetails_df nrows 0, just return after rendering empty map")
        return()
      }  
      
      DebugPrint("input$mytable_rows_selected observeEvent() - start on flight data")
      
      #if the tag deployment id is null there wont be any flight data, so just make an empty one
      if (is.na(tagDepID )) {
        DebugPrint("input$mytable_rows_selected observeEvent() - tagDepID is null so make dummy mydf")
        tagflight_df<-empty_tagDeploymentDetection_df()
      } else {

        
        #next get all of the detections associated with this tag deployment
        # note this is a local variable assignment
        DebugPrint(paste0("input$mytable_rows_selected observeEvent() - tagID NOT NA so call tagDeploymentDetections with tagDepID:",tagDepID))
 
               
        tagflight_df <- tagDeploymentDetections(tagDepID, config.EnableReadCache, config.ActiveCacheAgeLimitMinutes, withSpinner=TRUE, spinnerText=usespinnertext) 
        if(nrow(tagflight_df)<=0) {  # failed to get results... try the inactive cache
          DebugPrint("tagDeploymentDetections request failed - try Inactive cache")
          tagflight_df <- tagDeploymentDetections(tagDepID, config.EnableReadCache, config.InactiveCacheAgeLimitMinutes)
        }
        #print("--------- ReceiverDetections.R tagflight_df at line 521 --------")
        #print(tagflight_df)
        # print("----------------------------------------------------------------")
        
        # Now have records like:
        # date                         site     lat       lon receiverDeploymentID seq  use      usecs     doy   runstart     runend runcount
        # 2023-07-29                  tagging site 48.0634 -108.8518                    0   1 TRUE 1690656180 2023210 1690656180 1690656480        2
        # 2023-07-29                Lake Seventeen 48.0891 -108.8834                 8878   2 TRUE 1690670158 2023210 1690670158 1690671222        4
        # 2023-07-30                Lake Seventeen 48.0891 -108.8834                 8878   3 TRUE 1690745422 2023211 1690745422 1690754474        4
        # NOTE: one record per day
        
        # apply any flight data exclusions from .csv file read by global.R
        # this is the at Date, ReceiverID exclusion
        if( length(gblIgnoreDateTagReceiverDetections_df > 0 )){
          for(i in 1:nrow(gblIgnoreDateTagReceiverDetections_df)) {
            row <- gblIgnoreDateTagReceiverDetections_df[i,]
            theDate=row[["date"]]
            theID=row[["receiverDeploymentID"]]
            theSite=row[["site"]]
            #print(paste0("exclude"," date:",theDate, "  id:", theID,"  site:", theSite))
            tagflight_df <- tagflight_df[!(tagflight_df$receiverDeploymentID == theID & tagflight_df$date == theDate),] 
          }
        }

        # apply any flight data exclusions from .csv file read by global.R
        # this is the at ReceiverID on all dates exclusion
        if( length(gblIgnoreAllDetectionsAtReceiver_df > 0 )){
          for(i in 1:nrow(gblIgnoreAllDetectionsAtReceiver_df)) {
            row <- gblIgnoreAllDetectionsAtReceiver_df[i,]
            theLocalID=row[["localReceiverDeploymentID"]]
            theRemoteID=row[["remoteReceiverDeploymentID"]]
            theSite=row[["site"]]
            #print(paste0("exclude"," localID:",theLocalID, "  remoteID", theRemoteID,"  site:", theSite))
            if(theLocalID == receiverDeploymentID ){
                #print("localId matches")
                # the localId matches the currently selected receiver so do it
                tagflight_df <- tagflight_df[ !(tagflight_df$receiverDeploymentID == theRemoteID),] 
            }
          } #end for
        }   #endif
        #print(tagflight_df)
        
        if(config.EnableSuspectDetectionFilter==1){
           # Get ready to compute velocities and filter
           # add three columns to the dataframe
           tagflight_df$distance <- 0
           tagflight_df$duration <- 0
           tagflight_df$velocity <- 0

           # as we want to compute distance and velocity across rows, we need an extra row at both ends
           # of the dataframe (to prevent array bounds errors)
           # so here I duplicate the first row and last row of dataframe
           # these will be removed after the filtering

           a_df <- tagflight_df[1,]  #the first row
           tagflight_df <- insertRow(tagflight_df, a_df, 1)
           idx <- nrow(tagflight_df)
           a_df <- tagflight_df[idx,] #the last row
           tagflight_df <- insertRow(tagflight_df, a_df, idx)
   
           # now walk tagflight_df and compute velocity of adjacent detections
           DONE<-FALSE
           idx <- 2 #always start on row 2
           while(!DONE){
             if(idx > nrow(tagflight_df)){
               DONE <- TRUE
             } else {
               takeoff<-tagflight_df[idx-1,]
               landing<-row<-tagflight_df[idx,]
             
               site_takeoff <- takeoff[["site"]]
               lat_takeoff <- takeoff[["lat"]]
               lon_takeoff <- takeoff[["lon"]]
               usecs_takeoff <- takeoff[["runend"]]

               site_landing <- landing[["site"]]
               lat_landing <- landing[["lat"]]
               lon_landing <- landing[["lon"]]
               usecs_landing <- landing[["runstart"]]
             
               deltat <- usecs_landing - usecs_takeoff #seconds
   
               # st_distance wants a dataframe with a geometric structure
               df <- data.frame(lon = c(lon_takeoff, lon_landing), lat = c(lat_takeoff, lat_landing))
               mysf <- st_as_sf(df, coords = c("lon", "lat"), crs = "WGS84") %>% st_distance()
               distance = mysf[1,2]  #meters
               distance  <- drop_units(distance) #is a structure, want a numeric...
             
               if(deltat<=0){ deltat <- 1 } #dont divide by zero
             
               velocity<-(distance)/(deltat) #m/s

               #print(paste0( "velocity(m/s): ", velocity,"  distance(km): ", distance/1000, " hours: ", deltat/3600)) 
             
               tagflight_df[idx,]["distance"]<-distance/1000 #km
               tagflight_df[idx,]["duration"]<-deltat/3600 #hours
               tagflight_df[idx,]["velocity"]<-velocity
             
               # an animal can be detected simultaneously by passing between two sites ~50km apart.
               #if( (velocity >= config.VelocitySuspectMetersPerSecond) & (distance/1000 > 50) ) {
               if( velocity >= config.VelocitySuspectMetersPerSecond  ) {
                   tagflight_df[idx,]["use"]<-FALSE   # mark row as suspect
               }
             
               idx <- idx +1
             } #end else
           
           } #end while(!DONE)
  
           #and drop the extra first and last rows we added above...
           tagflight_df = tagflight_df[-1,, drop=F] #the first row
           tagflight_df <- tagflight_df[-nrow(tagflight_df),]  #the last row
       
           # filter the data
           # TODO: If we remove a line we should recompute distance and velocity
           # across the new adjacent rows
           if(input$enablefilter){
             # filter by keeping all rows with use=TRUE
             tagflight_df <- tagflight_df[(tagflight_df$use==TRUE),] 
           } 
        } #endif config.EnableSuspectDetectionFilter==1       
        
        #print("---  The final filtered summary flight df  line 622--------")
        #print(tagflight_df)
    
      } #end if else tagDepID is not na
      
      DebugPrint(paste0("input$mytable_rows_selected observeEvent() - render tagflight_df as table"))

      #table only shows a subset of columns
      if(config.EnableSuspectDetectionFilter==1){
         df<-tagflight_df[c("seq","date", "site","lat" ,"lon","receiverDeploymentID","duration","distance","velocity","use")]
         #our convention in tagflight_df is "use" true but for display we want to call the column "suspect"
         #so here we convert true to false and false to true to make suspect rows appear = TRUE
         df["use"]  = !df["use"]
         output$flightpath <- DT::renderDataTable({
           datatable( df,
                      selection = "single", 
                      rownames = FALSE,
                      colnames = c("seq","date", "site","lat" ,"lon","receiverDeploymentID","duration(hrs)","distance(km)","velocity(m/s)","suspect"),
                      options=list(dom = 'Bfrtip',
                                   searching = F,
                                   "pageLength" = 18,
                                   language = list(zeroRecords = "No records to display - Motus.org possibly offline.")
                      ) )  %>%  formatRound(columns=c("lat","lon"),digits=4)  %>%  formatRound(columns=c("distance","duration","velocity"),digits=1)  
           
         } ) #end renderDataTable
         
      } else {
         df<-tagflight_df[c("seq","date", "site","lat" ,"lon","receiverDeploymentID")]
         output$flightpath <- DT::renderDataTable({
           datatable( df,
                      selection = "single", 
                      rownames = FALSE,
                      colnames = c("seq","date", "site","lat" ,"lon","receiverDeploymentID"),
                      options=list(dom = 'Bfrtip',
                                   searching = F,
                                   "pageLength" = 18,
                                   language = list(zeroRecords = "No records to display - Motus.org possibly offline.")
                      ) )  %>%  formatRound(columns=c("lat","lon"),digits=4) 
           
         } ) #end renderDataTable
      } #end else
      
      
      remove_modal_spinner() # shown by tagDeploymentDetections
      
  
      

      if (is.na(tagDepID )) {   
        myLeafletMap = leaflet() %>% addTiles() #render the empty map
      } else {  #render the real map
        # next make the moving markers for the flightpath and then later assemble with the leaflet map
        
        # make a geometry dataframe for the moving marker
        # this will be our 'coordinate reference system'
        
        # this call generated sf layer warnings... below is a 
        #projcrs <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"  
        #Warning: sf layer has inconsistent datum (+proj=longlat +ellps=WGS84 +towgs84=0,0,0,0,0,0,0
        # +no_defs). Need '+proj=longlat +datum=WGS84'
        
        #the method below keeps up with"recent (and ongoing) changes in several
        #important geospatial libraries"
        #see https://inbo.github.io/tutorials/tutorials/spatial_crs_coding/
        projcrs <- st_crs(4326) # WGS 84 has EPSG code 4326
        
        # convert travel_df to a 'simple features dataframe' using the coordinate reference system
        # with columns: time,geometry
        # we will add the markers in constructing the leaflet map
        flight_sf <<- st_as_sf(x = tagflight_df,                         
                               coords = c("lon", "lat"),
                               crs = projcrs)
        
        # labels for leaflet map popups
        label_text <- glue(
          "<b>Name: </b> {tagflight_df$site}<br/>",
          "<b>Date: </b> {tagflight_df$date}<br/>",
          "<b>Latitude: </b> {tagflight_df$lat}<br/>",
          "<b>Longitude: </b> {tagflight_df$lon}<br/>") %>%
          lapply(htmltools::HTML)
        
        myLeafletMap = leaflet(data=tagflight_df) %>%
          addTiles() %>%
          
          addPolylines(lat= ~lat, lng = ~lon) %>%
          ### enable next line if we want site labels to appear as each new map is rendered
          ### addPopups(lat= ~lat, lng = ~lon, popup = ~site) %>%    
          
          addCircleMarkers(
            lng=~lon,
            lat=~lat,
            radius=5,
            stroke=FALSE,
            fillOpacity=0.5,
            #color=~color??, # color circle 
            popup=label_text,
            label=tagflight_df$site
          ) %>%
          
          # OPTIONAL: for touchscreens: we add a 2nd set of markers that have bigger radius and 
          # are completely transparent to implement a larger touchable target.
          addCircleMarkers(
            lng=~lon,
            lat=~lat,
            
            radius=15,
            stroke=FALSE,
            fillOpacity=0.0,
            popup=label_text,label=tagflight_df$site
          ) %>%
          
          #now add the MovingMarker layer
          addMovingMarker(data = flight_sf,
                          movingOptions = movingMarkerOptions(autostart = TRUE, loop = FALSE),
                          layerId="movingmarker",
                          duration=config.MapIconFlightDurationSeconds*1000,  #milliseconds
                          icon = birdIcon,
                          label=selected_species,
                          popup="")
        
      } # end else tagDepID is not null
      
      
      # render the output object named leaflet_map
      output$leaflet_map = renderLeaflet(myLeafletMap) 

    }
    
    #-------------------------------------------------------------------------------------------------------------
    #   
    #------------------------------------------------------------------------------------------------------------- 
    observeEvent(input$mytable_rows_selected,{
      updateDetectionsUI()
    })  # end observeEvent for mytable_rows_selected
    
    #-------------------------------------------------------------------------------------------------------------
    #   
    #-------------------------------------------------------------------------------------------------------------    
    # receivers picker input reactive observer
    # note the main page server.R also has an event observer for this input
    # note rcvr() is handle to the receivers input picklist passed in from server.R
    observeEvent(rcvr(), {
      DebugPrint("recvr picker observerEvent")
      # NOTE the use of global assignments
      strReceiverShortName <<- rcvr()  #global assignment
      
      DebugPrint(paste0("recvr picker observerEvent strReceiverShortName", strReceiverShortName))
      
      # on new receiver selection via the picker
      # update the global string strReceiverShortName
      # and use it to filter the global dataframe of shortnames and ID's to update
      # the global variable receiverDeploymentID. Then call myTagsToTable()
      #to populate the sidebar with a new list of detections
      
      selectedreceiver <- filter(gblReceivers_df, shortName == strReceiverShortName)      
      receiverDeploymentID <<- selectedreceiver["receiverDeploymentID"]
      
      DebugPrint(paste0("recvr picker observerEvent receiverDeploymentID", receiverDeploymentID))
      myTagsToTable()
      DebugPrint("recvr picker observerEvent back from tags to table")
      
      
      message(paste("set rcvr title to:",strReceiverShortName ))
      output$table_title<-renderText({strReceiverShortName})
      
    })  #end observeEvent input$receiver_pick
    
    
  }) #end moduleServer
  
}  # end SERVER_ReceiverDetections()




