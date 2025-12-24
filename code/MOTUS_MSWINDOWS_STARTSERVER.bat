@echo off
setlocal EnableDelayedExpansion

REM -----------------------------------------------------------------------
REM   MOTUS_MSWINDOWS_STARTSERVER.bat
REM   Version 2.0  23-Dec-2025
REM   A Windows .bat file to run Rscript.
REM
REM   Usage: MOTUS_MSWINDOWS_STARTSERVER.bat
REM  
REM   Configure this script to be run manually in a cmd.exe window
REM   or run it at computer boot by the Windows task manager
REM
REM   Starts the MOTUS_KIOSK server application that runs forever in
REM   the background.
REM -----------------------------------------------------------------------

REM  You must customize this script with names and paths specific to
REM  your kiosk if you have a non-standard installation 

REM -----------------------------------------------------------------------
REM --- You can overide the following items for non-standard configurations.
REM -----------------------------------------------------------------------

REM --- set this is to where you installed the MOTUS_KIOSK project
set "SCRIPTS_PATH=C:\Users\MOTUS_USER\Projects\MOTUS_KIOSK"


REM --- set this is to the network port your app will listen
set "PORT_NUMBER=8081"


REM --- set this if you want to see debug output to console
REM --- DEBUG_MODE=1 for ON or 0 for OFF for
set "DEBUG_MODE=1"

REM Specify the log file name for stderr and stdout output

REM this would create a uniquew timestamp the logfile so it never gets overwitten
REM set "LOG_NAME=MotusKioskLog_%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"

REM This form will create a logfile name  with the hour appended.  Then if it
REM already exists from a prior run, it will delete the previous file
REM Extract the hour from %time% (the first two characters)

REM for /f "tokens=1 delims=:" %%A in ("%time%") do set "hour_number=%%A"
REM set "LOG_NAME=MotusKioskLog_%hour_number%.txt"


REM this form will create logfile name using the day of month
REM well suited to nightly runs where you only want to keep a month worth of logs
REM  for system dates in of form:Wed 01/15/2025 the day of month is token 3

for /f "tokens=3 delims=/- " %%A in ("%date%") do set "DAY_OF_MONTH=%%A"
set "LOG_NAME=MotusKioskLog_dom%DAY_OF_MONTH%.txt"


REM -----------------------------------------------------------------------
REM --- You should not need to modify below this line
REM -----------------------------------------------------------------------

REM --- define a macro for debug output to console
set "DEBUG_ECHO=if "%DEBUG_MODE%"=="1" echo"


REM -----------------------------------------------------------------------
REM --- Read the kiosks startup.cfg file to get kiosk name and
REM --- Set path to log file directory
REM -----------------------------------------------------------------------

REM --- make sure to use DOS file separators (backslash)
set "SCRIPTS_PATH=%SCRIPTS_PATH:/=\%"

REM --- read the startup.cfg that will point us to the target kiosk
set "CFG_FILE=%SCRIPTS_PATH%\startup.cfg"

echo Reading startup cfg from: %CFG_FILE%

REM --- Ensure config file exists ---
if not exist "%CFG_FILE%" (
  echo ERROR: Config file not found: "%CFG_FILE%"
  exit /b 1
)
REM -- Read it and extract target key/value pairs
for /f "usebackq tokens=1,* delims==" %%A in ("%CFG_FILE%") do (
  REM Skip blank lines and comment lines
  if not "%%A"=="" if not "%%A:~0,1%"=="#" (

    set "KEY=%%A"
    set "VAL=%%B"

    REM Strip surrounding quotes
    set "VAL=!VAL:"=!"

    if /i "!KEY!"=="KiosksPath" set "KIOSKS_PATH=!VAL!"
    if /i "!KEY!"=="StartKiosk" set "KIOSK_NAME=!VAL!"
  )
)

REM --- Validate required values ---
if not defined KIOSKS_PATH (
  echo ERROR: KiosksPath not defined in %CFG_FILE%
  exit /b 1
)

if not defined KIOSK_NAME (
  echo ERROR: StartKiosk not defined in %CFG_FILE%
  exit /b 1
)

REM --- Show results (debug) ---
%DEBUG_ECHO% KIOSKS_PATH=%KIOSKS_PATH%
%DEBUG_ECHO% KIOSK_NAME=%KIOSK_NAME%

set "LOGS_PATH=%KIOSKS_PATH%\%KIOSK_NAME%\logs"
REM make sure to use DOS file separators
set "LOGS_PATH=%LOGS_PATH:/=\%"
%DEBUG_ECHO% LOGS_PATH=%LOGS_PATH%

REM -----------------------------------------------------------------------
REM ---  R.exe  SETUP AND TESTS ------
REM -----------------------------------------------------------------------

REM --- Set the path to R were we will find Rscript.exe
REM --- Get R_HOME from registry (use the 64-bit view explicitly)

%DEBUG_ECHO%  Get path to R from the Registry
for /f "tokens=2,*" %%A in ('
  reg query "HKLM\Software\R-core\R" /v InstallPath /reg:64 2^>nul ^| find /i "InstallPath"
') do set "R_HOME=%%B"

%DEBUG_ECHO%  R_HOME=[%R_HOME%]
if not defined R_HOME (
  echo ERROR: R_HOME not found in registry.
  exit /b 1
) else ( %DEBUG_ECHO% "R_HOME found OK" )

set "R_EXE=%R_HOME%\bin\R.exe"
if exist "%R_HOME%\bin\x64\R.exe" set "R_EXE=%R_HOME%\bin\x64\R.exe"

%DEBUG_ECHO% R_EXE=[%R_EXE%]

%DEBUG_ECHO%  Checking for Rscript.exe: "%R_EXE%"
if not exist "%R_EXE%" (
  echo ERROR: R.exe not found at that path.
  echo Listing "%R_HOME%\bin" if it exists:
  dir "%R_HOME%\bin" 2>nul
  exit /b 1
) else ( %DEBUG_ECHO% R_EXE exists.)

%DEBUG_ECHO% Testing to see if R is runnable directly:
"%R_HOME%\bin\R.exe" --version
if errorlevel 1 (
  echo ERROR: R failed to run
  exit /b 1
) else (
  %DEBUG_ECHO% SUCCESS: R.exe exists and can be run.
)

%DEBUG_ECHO% [%SCRIPTS_PATH%]

REM -- Specify the log file name for stderr and stdout output
set "LOG_FILE=%LOGS_PATH%\%LOG_NAME%

REM R.exe wants linux style - this converts DOS to LINUX
set "LINUX_SCRIPTS_PATH=%SCRIPTS_PATH:\=/%"
echo Starting the server now on localhost port %PORT_NUMBER%
cmd /c ""%R_EXE%" -e "shiny::runApp('%LINUX_SCRIPTS_PATH%',port=%PORT_NUMBER%)"" > "%LOG_FILE%" 2>&1

REM Capture exit code immediately after Rscript
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    echo ERROR: R script execution failed. See log: "%LOG_FILE%"
    >> "%LOG_FILE%" echo ERROR: R script execution failed. Exit code %RC%
    exit /b %RC%
) else (
    echo SUCCESS: Rscript executed successfully.
    >> "%LOG_FILE%" echo SUCCESS: Rscript executed successfully. Exit code %RC%
    exit /b 0
)

EXIT /B "%RC%"
