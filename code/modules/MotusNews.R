###############################################################################
# Copyright 2022 Richard Schramm
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
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


UI_MotusNews <- function(id, i18n) {
  
  ns <- NS(id)
  
  fluidPage(
    
    #this needs to be here or else some parts of ui
    #dont get translated (eg. the navbar)
    shiny.i18n::usei18n(i18n),
    
    tags$head(
      tags$style(HTML("hr {border-top: 1px solid #000000;}"))
    ),

    
    tags$div(id = 'newsgoeshere',
             div(id="readmediv",
                 #tags$h4(i18n$t("ui_motusnews_loading")),
                 htmlOutput(ns("news"))
             )
    )
   
  ) #end fluidPage
  
}  # end function def for UI_MotusNews

#####################
#    SERVER PART    #
#####################

SERVER_MotusNews <- function(id, i18n_r, lang, rcvr) {
  
  moduleServer(id, function(input, output, session) {
    
    # !!! session$ns is needed to properly address reactive UI elements from the Server function
    ns <- session$ns
    
    #---------------------------------------------------------------------------------------------------- 
    # A non-reactive function that will be available to each user session
    # populate the motus news section with either a default page or what was specifed in the config
    #---------------------------------------------------------------------------------------------------- 
    myRenderFunction <- function(x) {
        x=lang()
        #message(paste0("config.NewsPageEnglish is:",config.NewsPageEnglish))
    
        #DebugPrint(paste0("&&&&&&&&&&& config.NewsPageEnglish is:", config.NewsPageEnglish))
        xxx = config.NewsPageEnglish
    
        if(x=='en'){
           thefile<-xxx 
        } else if (x=='es'){ 
           thefile<-str_replace(xxx,"_en.html","_es.html")
        } else if (x=='fr'){ 
           thefile<-str_replace(xxx,"_en.html","_fr.html")
        } 

    
       #thepage <- includeHTML(thefile)
       #output$news <- renderUI(thepage)
        
        # after updating to R version 4.3.1 (2023-06-16)\
        # the above two lines started to generate following:
        # Warning: `includeHTML()` was provided a `path` that appears to be a complete HTML document.
        # Path: kiosks/AHNC/www/newspages/current_news_en.html
        # Use `tags$iframe()` to include an HTML document. You can either ensure `path` is
        # accessible in your app or document (see e.g. `shiny::addResourcePath()`)
        # and pass the relative path to the `src` argument. Or you can read the contents of `path` 
        # and pass the contents to `srcdoc`.
        # below three lines were the fix (plus the addResourcePath for newspages in global.R)
        
        #message(paste0("MotusNews thefile:",thefile) )
        
        
        output$news <- renderUI({
          ## works:   tags$iframe(seamless="seamless", src= "newspages/current_news_en.html", width=800, height=800)
          ## works:   tags$iframe(seamless="seamless", src= thefile, width=800, height=800)
          #tags$iframe(seamless="seamless", src= thefile, style='width:100vw;height:100vh;')
          tags$iframe(seamless="seamless", src= thefile,style='width:100%;height:100vh;')
        })
        
    } # end function myRenderFunction
    #---------------------------------------------------------------------------------------------------- 
    
    # Some UI elements should be updated on the Server side
    # -- when session starts
    # -- when language changes

    #-------------------------------------------------------------------------------------------------------------
    #   session start
    #-------------------------------------------------------------------------------------------------------------  
    observeEvent( session$clientData, {
      #  message("**session started ***")
      myRenderFunction()
    }) #end observeEvent for session start
  
    #-------------------------------------------------------------------------------------------------------------
    #   
    #------------------------------------------------------------------------------------------------------------- 
    # Update text values when language is changed
    # note lang() is handle to the language input picklist passed in from server.R
    observeEvent(lang(), {
      i18n_r()$set_translation_language(lang())
      myRenderFunction()
    }) #end observeEvent(lang()

    
  }) #end moduleServer

}  # end SERVER_MotusNews




