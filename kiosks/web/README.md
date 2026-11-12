This is README.md for directory kiosks/web

**DO NOT DELETE THIS FILE**

**This file must remain in this directory even if the directory is otherwise empty to ensure git preserves the directory structure.**

This directory holds kiosk content for kiosks that get uploaded to a web hosting service like shinyapps.io

Normally individual kiosk content is maintained by users in directories outside of the main MOTUS_KIOSK project so software updates can occur and changes can be pulled by all users.  We dont want to manage user content in the projects github repo

Web hosted kiosks need the kiosk to be a subfolder in the project's path which breaks that rule. 

There is a .gitignore file in the root directory which tells git to ignore anything in directory kiosk/web

