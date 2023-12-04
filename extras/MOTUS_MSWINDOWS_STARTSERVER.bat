​REM Microsoft TaskScheduler .bat job which will start the Kiosk code in
REM R-console and save any console or error output to a logfile
REM 12-Nov-2022
REM
REM see also: https://stackoverflow.com/questions/8662024

cmd /c ""C:\Program Files\R\R-4.2.2\bin\R.exe" -e "shiny::runApp('C:/Users/MOTUS_KIOSK/Projects/AHNC_MOTUS_KIOSK',port=8081)"" > "Logs/Log_%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt" 2>&1
EXIT /B %ERRORLEVEL%
