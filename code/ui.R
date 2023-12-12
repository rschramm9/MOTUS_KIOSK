
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

#
# UI "skeleton" of the whole app.
# Individual module UI is attached via UI_<module_name> functions
# 

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

##### this works when run in local but not on shinyapps.io web - 12Dec23
#en=paste0(  "<img src='", "/images/flags/ENUS.png' width=30px height=20px><div class='jhr'>English</div></img>")
#es=paste0(  "<img src='", "/images/flags/ES.png' width=30px height=20px><div class='jhr'>Español</div></img>")
#fr=paste0(  "<img src='",  "/images/flags/FR.png' width=30px height=20px><div class='jhr'>Français</div></img>")

en=paste0(  "<img src='",  "images/flags/ENUS.png' width=30px height=20px><div class='jhr'>English</div></img>")
es=paste0(  "<img src='",  "images/flags/ES.png' width=30px height=20px><div class='jhr'>Español</div></img>")
fr=paste0(  "<img src='",  "images/flags/FR.png' width=30px height=20px><div class='jhr'>Français</div></img>")

df$img = c(
  en, es, fr
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
  
  tags$div(id = 'readmehere',
           div(id="readmediv",
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
#10Dec2022 - give the navbar and the tabpanels id's so we can specify them in the server on page reset

#navbar_css = paste(config.SiteSpecificContent,"my-custom-theme.css")
navbar_css = paste(config.SiteSpecificContentWWW,"my-custom-theme.css")
ui_navbar <-  div( class="navbar1",  style="font-family: Verdana font-style: normal;font-size: 20px;",
 #navbarPage("",id="inTabset",theme="custom-navbar.css", 
 ### from v4.1    navbarPage("",id="inTabset",theme="my-custom-theme.css",
 
 #####navbarPage("",id="inTabset",theme="css/my-custom-theme.css", 
 
            navbarPage("",id="inTabset",theme=navbar_css,

           
            
            tabPanel(value="panel1", i18n$t("ui_nav_page_main"),style="color:#000000;font-style: normal;font-size: 12px;",
            ###tabPanel(value="panel1", i18n$t("ui_nav_page_main"),
                          ui_mainpage
                 ),
       
                 tabPanel(value="panel2", i18n$t("ui_RCVR_title"),style="color:#000000;font-style: normal;font-size: 14px;",
                          UI_ReceiverDetections("ReceiverDetections", i18n=i18n),
                 ),
                 
                 if (config.EnableMotusNewsTab) { tabPanel(value="panel3", i18n$t("ui_MotusNews_title"),style="color:#000000;font-style: normal;font-size: 10px;",
                          UI_MotusNews("MotusNews", i18n=i18n),
                 )},
            
            if (config.EnableLearnAboutMotusTab) { tabPanel(value="panel4", i18n$t("ui_AboutMotus_title"),style="color:#000000;font-style: normal;font-size: 10px;",
                     UI_AboutMotus("AboutMotus", i18n=i18n),
            )},
            

      ),
) #end the ui_navbar definition

###############################################################################
##  define the title panel that holds the logo, main title and the
## language selector.  It will appear on all pages.
###############################################################################


ui_titlebar <- fluidRow(

  titlePanel(   
    tagList(
      # NOTE: Offseting logo -30PX to recover vertical space.. value determined by trial and error
      #div(style="display: inline-block;margin-top:-30px;",img(src = config.MainLogoFile, height = config.MainLogoHeight)),
      
      
      ## getting close:
#works1     div(style="display: inline-block;margin-top:-30px;",
#works1          img(src = "logos/ankenyhill_logo.png", height = config.MainLogoHeight)),

      #this STILL NOT works ------   

           div(style="display: inline-block;margin-top:-30px;",
                img(src = config.MainLogoFile, height = config.MainLogoHeight)),
 
      
      
      
      #div(style="display: inline-block;margin-top:-30px;",
       #   img(src = config.MainLogoFile, height = config.MainLogoHeight)),
      
      
      #span(style="color:#8FBC8F;font-style: italic;font-size: 25px;",
      span(style=paste0("color:",config.TitlebarColor,";font-style: italic;font-size: 25px;"), 
           
           div(style="display:inline-block;vertical-align:middle; width: 50%;", textOutput("main_page_title")),
           
           #div(style=paste0("color:",config.TitlebarColor,"; display: inline-block;vertical-align:middle; width: 50%;"), textOutput("main_page_title")),
           
           # a utility action button on titlebar for debugging
           # if you enable, also enable the observer function in server.R
           #actionButton("btnCommand","Command"),
           
           
           div(style="display: inline-block;vertical-align:top;width:120px", pickerInput(inputId = "receiver_pick",
                                   label = i18n$t("ui_mainpage_available_receivers"),
                                   width = 170,
                                   choices = config.ReceiverShortNames,
                                   options = pickerOptions(container = "body")
           )) ,
           
           
           span(
             tags$div(  tags$style(".jhr{
                       display: inline;
                       vertical-align: middle;
                       padding-left: 10px;
                        }")),
             
             pickerInput(inputId = "lang_pick",
                         label = "",
                         width = 170,
                         choices = df$val,
                         choicesOpt = list( content=df$img),
                         options = pickerOptions(container = "body")
             ),
             
             
             style = "position:absolute;right:2em;"
           ), #end span2
           
      ), #end span1
      
    ) # end taglist
    
  ), #end titlepanel
  
)  #end the ui_title fluidRow

###############################################################################
## assemble the UI from the pieces
###############################################################################


ui <- fluidPage( 
             tags$head( 
             tags$title("Motus Kiosk"),
             ##tags$script(src="var_change.js")),
             ###tags$script(src=scripts)),
             tags$script(src="scripts/var_change.js")),
             
             tags$script(inactivity),

  ui_titlebar,
  ui_navbar,
  
  # horizontal line and a small plain text footer 
  hr(style="display: block;
            padding: 1px;
            margin-top: 0.25em;
            margin-bottom: 0.25em;"
            ),
  
  span(
    div(
      textOutput("footer")%>% 
      tagAppendAttributes(style= 'font-size: 10px;
                        padding: 1px;
                        margin-bottom: 1px;
                        margin-top: 1px;
                        margin-left: 10px;
                        display: inline-block;
                        ') ,
  
     htmlOutput("motusState")%>% 
     tagAppendAttributes(style= 'font-size: 12px;
                        padding: 1px;
                        margin-bottom: 1px;
                        margin-top: 1px;
                        margin-left: 10px;
                        display: inline-block;
                        position:absolute;right:2em;
                        ') 
    ) # end div
  ) # end span
  
)   # end of ui definition


