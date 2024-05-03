REM Microsoft TaskScheduler .bat job which will start the kiosk code in
REM R-console and save console or error output to a log file
REM 04-Dec-2023
REM See also: https://stackoverflow.com/questions/8662024

REM Check the following FOUR things in this script.

REM 1) Check the username. If you chose to run as a different user than MOTUS_USER
REM then substitute that username below in two places.

REM 2) Check the path to R carefully below. If you followed recommendations you should
REM find it in C:\R  However if it was installed previously or you chose a the
REM default R location it may be in C:\Program Files\R

REM 3) Check that the version portion of the path to R is correct for your installation,

REM 4) Also check the path to the logs directory. You will want to have logs written
REM in with your kiosk specific directory. If you have followed recommendations then that
REM logs directory will be in the same place as your kiosk.cfg file - (likely in
REM the C:/Users/MOTUS_USER/Documents/kiosks/yourkioskname path)

REM ** IMPORTANT Pay close attention to the user of "\" and "/" in the paths below
REM DOS requires paths using "\", R likes to see 'linux' type paths here - notice in the below
REM how the DOS portion of the cmd uses "\" and the parts that get passed to R use the "/" form 

cmd /c ""C:\R\R-4.3.3\bin\R.exe" -e "shiny::runApp('C:/Users/MOTUS_USER/Projects/MOTUS_KIOSK/code',port=8081)"" > "C:/Users/MOTUS_USER/Documents/kiosks/DEFAULT/logs/Log_%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt" 2>&1
EXIT /B %ERRORLEVEL%
