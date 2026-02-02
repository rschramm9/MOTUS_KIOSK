
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
# https://bitbucket.org/statsconsult/clinrtoolsdemo/src/master/

# UI "skeleton" of the whole app.
# Individual module UI is attached via UI_<module_name> functions


library(shinyjs)


## languages supported is determined by presence of translations csv files
## available in the data/translations dir

# load the translations here
#suppress translator warning re. 'no translation yaml file' 
warn = getOption("warn")
options(warn=-1)
#message(paste0("In ui.R config.TranslationsPath:", config.TranslationsPath))
i18n <- Translator$new(translation_csvs_path = config.TranslationsPath,
                       separator_csv="|")
options(warn=warn)

active_ui_lang <- grep("ui",i18n$get_languages(), invert = TRUE, value = TRUE)

# then set the default
i18n$set_translation_language(default_UI_lang)  #set in global.R


# this language data frame  gets used in the language selector defined below in
# ui_titlebar() section
#  *** these must match EXACTLY the translations
#      present in in the data/translation dir
#
df <- data.frame(
  val = c("en","es","fr")
  #val=setNames(active_ui_lang,active_ui_lang)
)

## and the country flags - careful to match the order in df above
## - and note the css class is jhr
en=paste0(  "<img src='",  "images/flags/ENUS.png' width=30px height=20px><div class='jhr'>English</div></img>")
es=paste0(  "<img src='",  "images/flags/ES.png' width=30px height=20px><div class='jhr'>Español</div></img>")
fr=paste0(  "<img src='",  "images/flags/FR.png' width=30px height=20px><div class='jhr'>Français</div></img>")
# a dataframe holding image path
df$img = c(
  en, es, fr
) 

######### NEW ##########
ui_headerbar <- fluidRow(
  div(  
    id = "main_page_headerbar",
    actionButton("gotoMap", "Page Loading...", style = "height: 95%"),
    div( class = "headerbar-container",
         textOutput("headerbar_text")
    ),
    div(
      class = "lang-picker",
      tags$div(  tags$style(".jhr{
         display: inline;
         vertical-align: middle;
         padding-left: 10px;
      }")),
      
      pickerInput(
        inputId = "lang_pick",
        label = NULL,
        choices = df$val,
        choicesOpt = list(content = df$img),
        options = pickerOptions(container = "body"),
        width = "170px"
      )
    )
  )
)

ui_titlebar<- fluidRow( class = "title-bar",
                        



   tags$img(
     #src = "images/logos/ankenyhill_logo_hires_cropped.jpg",
     src = config.MainLogoFile,
     alt = "AHNC Logo"
     ) ,
   
   div( class = "title-bar-content",
       textOutput("main_page_title", inline = TRUE)
   ),
                        
   div( class = "picker-container",
        textOutput("available_receivers", inline = TRUE),
        
      # receiver picker can be styled as either a dropdown list or a
      # radio button group.
      if (config.ButtonStyleReceiverSelectors) { #use radio button group
          shinyWidgets::radioGroupButtons(
            inputId   = "receiver_pick",
            choices   = config.ReceiverShortNames,
            selected  = config.ReceiverShortNames[1],
            size      = "sm",
            direction = "vertical",
            status    = "default"    # <-- IMPORTANT
          )
      } else { #use dropdown list
          shinyWidgets::pickerInput(
            inputId  = "receiver_pick",
            label    = NULL,
            choices  = config.ReceiverShortNames,
            width    = "200px"
          )
      }
        
     
   ) #end div picker-container
   
)


###############################################################################
# Define Main "Home Page Readme" ui panel.
# It just holds a div for a Readme text blob at the moment that the server
# fill manage from html text files in the www/docs directory
###############################################################################
ui_mainpage <- fluidPage(
  
  #this needs to be here or else some parts of ui
  #dont get translated (eg. the navbar)
  shiny.i18n::usei18n(i18n),
  
  tags$div(id = 'homepagehere',
      div(id="homepagediv",
      tags$h4(i18n$t("ui_mainpage_loading"))
      )
  )
)  # end of main page layout


###############################################################################
## define the navbar portion of the ui.  holds the tab panels
## and the ui_mainpage (defined above) all others are as functions
## defined in modules
## *** note how the language translation is passed into the function**
###############################################################################

ui_navbar <-  div( class="navbar1", 
 
     navbarPage("",id="navbartabset",

     tabPanel(value="panel1", i18n$t("ui_nav_page_main"), 
       ui_mainpage
     ),
       
     tabPanel(value="panel2", i18n$t("ui_RCVR_title"),  
       UI_ReceiverDetections("ReceiverDetections", i18n=i18n),
     ),
                 
     if (config.EnableMotusNewsTab) { tabPanel(value="panel3", i18n$t("ui_MotusNews_title"),  
        UI_MotusNews("MotusNews", i18n=i18n),
     )},
            
     if (config.EnableLearnAboutMotusTab) { tabPanel(value="panel4", i18n$t("ui_AboutMotus_title"), 
        UI_AboutMotus("AboutMotus", i18n=i18n),
     )},
     
   ),
) #end the ui_navbar definition div


ui_hrow<-fluidRow(
  # horizontal line 
  hr(style="display: block;
            padding: 1px;
            margin-top: 0.25em;
            margin-bottom: 0.25em;"
  )
)

ui_footer<-fluidRow(
   div(class = "footer-row",
      div(uiOutput("versionInfo"), class = "version-info"), 
      div(uiOutput("motusState"), class = "motus-state") 
  )
)


###############################################################################
## assemble the UI from the pieces defined above
###############################################################################

ui <- fluidPage( 
  useShinyjs(), # Initialize shinyjs so we can use dynamic css to set colors
  
  # link it to the CSS style sheet in the www/css directory
  # uses a css resource path set in global.R
  
  #tags$link(rel = "stylesheet", type = "text/css", href = "css/motus_kiosk_default.css"),
  
  tags$head( 
    tags$link(rel = "stylesheet", type = "text/css", href = config.CssFile),
    tags$title("Motus Kiosk"),
    tags$script(src="scripts/var_change.js"),
    tags$script(inactivity)
  ),
             
   ###tags$script(inactivity),
             
   ui_headerbar,
   ui_titlebar,
   ui_navbar,
   ui_hrow,
   ui_footer,
  
)   # end of ui definition

