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


UI_AboutMotus <- function(id, i18n) {
  
  ns <- NS(id)
  
  fluidPage(
    
    #this needs to be here or else some parts of ui
    #dont get translated (eg. the navbar)
    shiny.i18n::usei18n(i18n),
    
    tags$head(
      tags$style(HTML("hr {border-top: 1px solid #000000;}"))
    ),

    
    tags$div(id = 'aboutmotusgoeshere',
             div(id="aboutmotusdiv",
                 #tags$h4(i18n$t("ui_about_motus_loading")),
                 uiOutput(ns("about_motus"))
             )
    )
   
  ) #end fluidPage
  
}  # end function def for UI_AboutMotus

#####################
#    SERVER PART    #
#####################

SERVER_AboutMotus <- function(id, i18n_r, lang) {
  
  moduleServer(id, function(input, output, session) {
    
    # !!! session$ns is needed to properly address reactive UI elements from the Server function
    ns <- session$ns
    

    # A non-reactive function that will be available to each user session
    # populate the motus news section with either a default page or 'current'
    #-------------------------------------------------------------------------------------------------------------  
    myRenderFunction <- function(x) {

      # get filename matching the current language

      x=lang()
      xxx = config.AboutMotusPageEnglish
      
     #### NOTE WE ARE EXPECTING A .png file,(not .html)  
     if(x=='en'){
        thefile<-xxx 
      } else if (x=='es'){ 
        thefile<-str_replace(xxx,"_en.png","_es.png")
      } else if (x=='fr'){ 
        thefile<-str_replace(xxx,"_en.png","_fr.png")
      } 

      output$about_motus <- renderUI({
        img(src=thefile, height='95%')
      })

    } # end function myRenderFunction
   
  
    
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

}  # end SERVER_AboutMotus




