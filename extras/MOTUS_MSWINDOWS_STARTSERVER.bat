REM Microsoft TaskScheduler .bat job which will start the kiosk code in
REM R-console and save console or error output to a log file
REM 04-Dec-2023
REM See also: https://stackoverflow.com/questions/8662024

cmd /c ""C:\Program Files\R\R-4.3.2\bin\R.exe" -e "shiny::runApp('C:/Users/MOTUS_USER/Projects/MOTUS_KIOSK/code',port=8081)"" > "C:/Users/MOTUS_USER/Projects/MOTUS_KIOSK/logs/Log_%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt" 2>&1
EXIT /B %ERRORLEVEL%
