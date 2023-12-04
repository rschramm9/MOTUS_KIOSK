# 1  Start Here

### Build the Motus Kiosk web app

**This** document is a guide on how to , the kiosk app out of source control (git), and how to do the first build.

In this document will guide you along the following path:

-   Present brief descriptions about the pieces that make up  the kiosk and how it works with motus.org
-   How get the  R and Studio  tools and packages  installed.
-   How to get the kiosk app out of source control (git).
-   Build and run the the default kiosk to make sure RStudio and everything setup and running correctly.
-   Clone the default kiosk into one that will become your own site-specific kiosk, ready to be customized.
-   Configure your copy of the kiosk.

At the end of these steps you should have your own copy of the shiny web app up-and-running using R-Studio on your local computer and ready to begin customizing it.

If you intend to deploy as a kiosk you will want to also complete steps in the document WINDOWS_FIRSTRUN_README.md in the project's top level directory.  Unfortunately there are quite a number of steps and tweaks to Windows 10 and the user accounts settings required to get the full, securely locked-down kiosk behavior we ultimately require. The provided document describes these settings and tweaks in full and painful detail.

The final deployment and configuration of the app to a kiosk-like display using OpenKiosk is described in the third companion document FINAL_DEPLOYMENT_WINDOWS_README.md in the project's top level directory.

There is a fourth document that describes  the available configuration parameters and performance 'tweeks' - CONFIGURATION_GUIDE_README.md

If you are wanting to modify or further develop the application there is a fifth document named DEVELOPERS_README.md that may be helpful.

### Who do I talk to?

-   Owner/Originator: Richard Schramm - [schramm.r@gmail.com](mailto:schramm.r@gmail.com){.email}

#### 1.0 - Preliminaries

The 'kiosk system' can be viewed as built on these .

-   The operating system
-   The kiosk is a container (special kind of web browser) that 'hosts' the web application (OpenKiosk)
-   The programing language and development environment that the application runs in (R, and R-Studio)
-   The web application that runs inside the kiosk window to render the user interface and obtain the data from motus.org ('the code and supporting files')
-   The motus.org remote data server.

![KioskArchitectureRev2](./md_images/BUILDING_KioskArchitectureRev2.png)

##### Operating System

Windows 10 Pro OS was specified a requirement for the Ankeny Hill Nature Center.

Nothing precludes you from choosing a different operation system. I have developed and run everything quite well at home under Mac OSX (v12.6) and deployed to Windows 10 target. It should also be able to be run on small generic linux machines although I have not attempted to verify.

##### The programming/language environment

The Motus developers work in the R programing language. R-Studio provides a rich development environment and also integrates with the R package "Shiny" - which is what the actual web app (dashboard) has been developed in.

##### The OpenKiosk

The OpenKiosk is a basically a specialized web browser with configurable restrictions that will connect to our web application (via an http connect to a port on a web server).

See: <https://openkiosk.mozdevgroup.com>

There are many other ways to display the application including 1) running it in R and RStudio  2) standard Chrome or Firefox browsers or 3) 'pushing' the web app to remote web server for access by the www 

*It is important to recognize this distinction between the Shiny dashboard web application and the kiosk behavior being provided by OpenKiosk.*

##### Motus.org

The Motus Collaboration Policy (<https://motus.org/policy/>) specifies we should only provide data from the public "Basic open-access dataset". That dataset is the coarse "summary-level detection information".

All of the desired tagged bird detection information is available via simple http requests to the public motus.org servers.

##### The Application

The application is built in R-Studio using the R package "Shiny" (see: <https://shiny.rstudio.com/>) Shiny is an R package that makes it easy to build interactive web apps straight from R. You can host standalone apps on a webpage or build dashboards. When run on the local machine from a cmd line it will start a 'shiny server' on a local machine URL that you can point your browser to.

#### 2.0 - Install R for your platform 

##### Windows:

Log in as administrator

If not already installed (see: <https://www.r-project.org/>) - Download the installer to your downloads folder

Double-click the installer.

Make sure it says to install into "C:\Program Files\R\R-4.4.2" (or whatever your downloaded version is)

You also may need to install Rtools  to be able to rebuild/install R packages . See: https://cran.r-project.org/bin/windows/Rtools/

**Other Operating systems:**

See:  https://cran.r-project.org/

For Apple OSX current version is  4.3.1 (2023-06-16)



#### 3.0 - Install R-studio IDE Free Edition for your platform

##### 3.1 - Install Required R Packages

Log in as administrator

If not already installed. (see:<https://www.rstudio.com/products/rstudio/download/>)

##### 3.2 - Install Required R Packages

You will need quite a few additional packages installed.  This can be a somewhat frustrating part depending on which revision levels  of R and the various packages are currently considered 'current'.

Some will cleanly install straight from binary distributions, others may need to recompile using Rtools. 

Run R console.

Enter the following cmds into the R Console just to make sure all are installed for the Admin user. I suggest doing them one at a time.  R may cleanly install or may report something like "The binary package is available but source versions are later".  

You can try installing with **install.packages("*thepkgname*", type="source")** to cause recompile with rTools or   **install.packages("*thepkgname*", type="binary")**  Compiling from source would probably be best to get the latest fixes etc.

Occasionally a package install may also hang with "package xxxx not found" displayed in the Console. So far that has been cleared by typing directly in the R-Studio Console like:

``` r
install.packages('xxxx', dependencies = TRUE)
or
install.packages('xxxx', dependencies = TRUE, repos='http://cran.rstudio.com/')
```



Note R may ask you to select a mirror site - Use one physically close to you. I used OSU's mirror

    install.packages("shiny")
    install.packages("shinymeta")
    install.packages("shinyjs")
    install.packages("shiny.i18n")
    install.packages("shinyWidgets")
    install.packages("rvest")
    install.packages("tidyr")
    install.packages("lubridate")
    install.packages("sf")
    install.packages("tidyverse")
    install.packages("DT")
    install.packages("leaflet")
    install.packages("leaflet.extras2")
    install.packages("httr")
    install.packages("glue")
    install.packages("data.table")
    install.packages("anytime")
    install.packages("stringr")
    install.packages("xml2")
    install.packages("sf")
    install.packages("rjson")
    install.packages("fs")

#### 4.0 - Create the MOTUS_USER user account

This and all other accompanying documentation assumes a particular Windows10 user account (username=MOTUS_USER)

*While you may use any account to get the web app dashboard up-and-running - you will save yourself needing to repeat some of this work if you do it within the username and home directory on the local machine that you intend to deploy on.*

Whichever username you want the code to live under, navigate to that user's home directory and create a new folder to hold your project.  *I will use a folder named "Projects"  for the throughout this documentation.*

#### 5.0 - Installing  git

git is the cloud repository that contains the code and documentation. Presumably if you are viewing this file you have at least visited the repository. 

You will first (as administrator) need to install the program 'git' on the machine you wish to download the project to. (See: <https://git-scm.com/book/en/v2/Getting-Started-Installing-Git>)

NOTE: This install on windows machines can be a bit frustrating due to the variations of Windows 10 installations. WIndows 10 Pro was pretty straight forward. With Windows 10 Home Edition it is challenging to get git.exe recognized on the path. Persistence is key.. the git.exe install should be to C:\Program Files. You may need to 'cd' there in the cmd.exe window to run git...

#### 6.0 - Getting the code project

Log in as user = MOTUS_USER (or your intended username from step 4.0)

This and all other accompanying documentation assumes a particular Windows10 user account (username=MOTUS_USER) and project directory structure: C:\Users\MOTUS_USER\_KIOSK\Projects

Create a directory for the project - for example on Windows I use **C:\Users\MOTUS_USER\Projects** as my top-level directory. If you dont already have the above Projects folder - create it now as User=MOTUS_USER

You shouldnt need to create a github account to clone a repository but it can be helpful to do so if you want to submit bug reports etc.

Open a command window such as Cmd.exe (windows)  or iTerm (macs) and type:

``` code
cd  C:\Users\MOTUS_USER\Projects
git clone https://github.com/rschramm9/MOTUS_KIOSK.git
```

You shouldnt need to create a github account to clone a repository but it can be helpful to do so if you want to submit bug reports etc.  Git may pop-up an authentication options window in which case you will need to register.

Git may pop-up an authentication options window -- provide your git credentials via a web browser if asked. Once authenticated, the download should proceed along the lines of:

``` code
Cloning into 'MOTUS_KIOSK'...
remote: Enumerating objects: 11, done.
remote: Counting objects: 100% (11/11), done.
remote: Compressing objects: 100% (10/10), done.
remote: Total 11 (delta 4), reused 5 (delta 1), pack-reused 0
Receiving objects: 100% (11/11), 13.99 KiB | 2.33 MiB/s, done.
Resolving deltas: 100% (4/4), done.
```

A complete copy of the repository should now be in subdirectory at: C:\Users\MOTUS\_USER\Projects\MOTUS_KIOSK

#### 7.0 - Your first test build

Run the R-Studio IDE. Once open, Click File \> New Project

From the shown "New Project Wizard" select "Existing Directory"

"Browse" **INTO** the folder: C:\Users\MOTUS\_USER\Projects\MOTUS_KIOSK and click "Open"

Once back in the wizard, Click "Create Project" button

From the IDE Right-side "Files" Panel/Tab, Click to open the file ***global.R***

Check at the top of the main source code window for a warning regarding several packages that may need still need to be installed... Go ahead and click the "Install" and Wait while it installs numerous package dependencies. This can take around 4 to 5 minutes....

Note: see hints back in section 3.1 regarding getting packages to install.

Repeat checking for other packages still needing to be installed (if any) for these source code files:

1.  ui.R

2.  server.R

    (And in the modules sub-folder....)

3.  modules/receiverDeploymentDetections.R

4.  modules/ReceiverDetections.R

5.  modules/tagDeploymentDetails.R

6.  modules/tagDeploymentDetections.R

Now close the tabs for all source code files **EXCEPT** global.R, ui.R and server.R

With one of those three files selected for view in the code window, notice a green arrow labeled "Run App" should be visible -click that.

After RStudio builds the app it should pop-up the app in its own browser window.

Two other things to observe...

1-When the app is running - on the Console tab will be a red stop-sign. Use that to halt the app to make changes or reload the config file etc

2-Just after the app starts up, if you scroll down thru the output in the Console tab, you will find:

"Listening on [http://127.0.0.1:####](http://127.0.0.1:####){.uri}". This is the temporary URL server and port that Shiny assigns. You may be curious to try cutting that URL to your clipboard and pasting it into any browser on any machine on your local network. It should work!

#### 8.0 - Make your own kiosk to customize

Next we will create a clone of the DEFAULT kiosk and give it your own name.  This will become the kiosk you modify and run, customized with your own content and receivers etc.

Open the RStudio project.  ( at: MOTUS\_USER\Projects\MOTUS_KIOSK\MotusKiosk.Rproj)

Click on the IDE top menubar:  File > NewFile> R Script   This will pop a new untitled  blank window on the IDE.

Cut and paste these two lines into the window,  modifying 'yourkioskname' of course (and keeping the single quotes)

```
source("code/modules/utility_functions.R")
CloneKiosk("DEFAULT", "yourkioskname")
```

Then in that untitled panel, in the upper right corner find and click on the 'source' button. This will execute the script.  If all goes well, you should see a message in the lower console window saying "creating kiosk"

Close that untitled1 panel by clicking on the x next to 'untitled1' and without saving - we wont need it again.



#### 9.0 - Configuration

##### 9.1 - Point the starup.cfg to run your kiosk.

Now notice the row of tabs on the IDE right-side panel approximately mid page.  Select the 'Files' tab and navigate to the top-level project folder and find startup.cfg and open it. It should look like below.

```
KiosksPath="kiosks"
StartKiosk="DEFAULT"
```

Change the StartKiosk from DEFAULT to whatever yourkioskname you used above.

```
KiosksPath="kiosks"
StartKiosk="yourkioskname" 
```

Save it and close the Startup.cfg file ( dont forget the 'Save' !)

Check your work: Select the global.R file again and click 'Run app' button.  The app should run properly and if you scroll back in the console window and you should see a line like  "global KioskName:yourkioskname" 

From now on, you will be running and working to customize your own copy of the kiosk.

##### 9.2 - Edit your kiosk.cfg file.

In your own kiosk directory (e.g. *top-level-project-dir/kiosks/yourkioskname*)  is a file called kiosk.cfg.  It contains the default set of key value pairs that do things like set the target motus receiver deployment(s), your icons , banner logos, main title etc.

Jump over to the document **2_CONFIGURATION_GUIDE_README.md** and set the parameters in your kiosk.cfg as described there. (Initially you may only need to change the top few items)

Then restart the web application in Studio to verify the results.

##### 9.3 - Configure your own "Home" tab content

The descriptive content that appears in the in the main page body when ever the "Home" tab is open comes from a language dependent .html file in the project sub-directory www/homepages

There should be one file for each language that the application supports - currently: English, Spanish and French.  Feel free to copy and edit the default pages provided.  And make sure to set the correct filenames in your configuration file

-   default_homepage_en.html for English

-   default_homepage_es.html for Spanish

-   default_homepage_fr.html for French

Edit these files carefully with an html editor or a text editor of your choice.

*Someplace visible in your kiosk you **must** give proper credit to the Motus folks and Birds Canada and should include a statement regarding Acceptable Use.* I have chosen to put that in the section "Credits" on the "Home" screen.

**WARNING:** Teaching html document structure is beyond the scope of this documentation. Be careful to maintain correct opening and closing html tags and verify that your changes render correctly in an html browser such as firefox or chrome before replacing the existing files.

##### 9.4 - Configure your own "Species" tab content

*It is up to you if you want to work on creating your own species page content at this point. You can easily delay this task and jump to configuring windows to autostart and run the application as a locked-down kiosk.*

The descriptive content that appears in the in the in the "Species" tab when ever a new animal is selected comes from a language dependent .html file in the project sub-directory www/speciespages.

There should be a files for each species you want to describe, one in each language you wish to support.

***File name choice is critical.*** The software builds a compacted lowercase 'key' using the motus species name field and tries to match that to a file in the speciespages directory.

To add your own species files, copy any group files (one for each language) to use as templates and edit them carefully with an html editor or a text editor for the species of your choice. Save them using the filename pattern described above.

**WARNING:** Teaching html document structure is beyond the scope of this documentation. Be careful to maintain correct opening and closing html tags and verify that your changes render correctly in an html browser such as firefox or chrome before replacing the existing files.
