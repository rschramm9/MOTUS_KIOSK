@echo off
setlocal EnableDelayedExpansion

REM -----------------------------------------------------------------------
REM   MOTUS_MSWINDOWS_BUILDCACHE.bat
REM   Version 2.0  23-Dec-2025
REM   A Windows .bat file to run Rscript.
REM
REM   Usage: MOTUS_MSWINDOWS_BUILDCACHE.bat
REM  
REM   Configure this script to be run manually in a cmd.exe window
REM   or run it nightly by the Windows task manager
REM
REM   Runs the BuildCache.R script that walks receivers in the user's
REM   kiosk.cfg file and creates a cached dataset for tag detections at
REM   receivers so the kiosk gui can be more responsive
REM -----------------------------------------------------------------------

REM  As you must customize this script with names and paths specific to
REM  your kiosk if you have a non-standard installation 

REM -----------------------------------------------------------------------
REM --- You can overide the following items for non-standard configurations.
REM -----------------------------------------------------------------------

REM --- set this is to where you installed the MOTUS_KIOSK project
set "SCRIPTS_PATH=C:\Users\MOTUS_USER\Projects\MOTUS_KIOSK"

REM --- set the script to run relative to the SCRIPTS_PATH setingt above
set "RSCRIPT_FILE=code\modules\BuildCache.R"

REM --- set this if you want to see debug output to console
REM --- DEBUG_MODE=1 for ON or 0 for OFF for
set "DEBUG_MODE=1"


REM -----------------------------------------------------------------------
REM ----  You shouldnt need to modify anything below this line
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
    if /i "!KEY!"=="KioskCfgFile" set "KIOSK_CFG=!VAL!"
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

if not defined KIOSK_CFG (
  echo ERROR: kiosk.cfg not defined in %CFG_FILE%
  exit /b 1
)

REM convert to use DOS file separators
set "KIOSKS_PATH=%KIOSKS_PATH:/=\%"

REM --- Show results (debug) ---
%DEBUG_ECHO% KIOSKS_PATH=%KIOSKS_PATH%
%DEBUG_ECHO% KIOSK_NAME=%KIOSK_NAME%
%DEBUG_ECHO% KIOSK_CFG=%KIOSK_CFG%

set "LOGS_PATH=%KIOSKS_PATH%\%KIOSK_NAME%\logs"

REM make sure to use DOS file separators
set "LOGS_PATH=%LOGS_PATH:/=\%"
%DEBUG_ECHO% LOGS_PATH=%LOGS_PATH%

REM --- where the kiosk.cfg file lives within your kiosk
%DEBUG_ECHO% TWO - KIOSK_NAME=%KIOSK_NAME%
%DEBUG_ECHO% TWO - KIOSKS_PATH=%KIOSKS_PATH%
set "KIOSK_DIR=%KIOSKS_PATH%\%KIOSK_NAME%"
%DEBUG_ECHO% HERE WITH KIOSK_DIR=%KIOSK_DIR%

REM -- Ensure the kiosk directory exists (do NOT create it)
%DEBUG_ECHO% TESTING KIOSK DIR [%KIOSK_DIR%]

if not exist "%KIOSK_DIR%\" (
  echo ERROR: kiosk directory does not exist: "%KIOSK_DIR%"
  exit /b 1
) else ( %DEBUG_ECHO% directory found.) 

if not exist "%KIOSK_DIR%\%KIOSK_CFG%" (
  echo ERROR: Required file %KIOSK_CFG% not found in: "%KIOSK_DIR%"
  exit /b 1
 )else ( %DEBUG_ECHO% config found.) 


REM -----------------------------------------------------------------------
REM ---  RScript  SETUP AND TESTS ------
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

set "RSCRIPT_EXE=%R_HOME%\bin\Rscript.exe"
if exist "%R_HOME%\bin\x64\Rscript.exe" set "RSCRIPT_EXE=%R_HOME%\bin\x64\Rscript.exe"

%DEBUG_ECHO% RSCRIPT_EXE=[%RSCRIPT_EXE%]

%DEBUG_ECHO%  Checking for Rscript.exe: "%RSCRIPT_EXE%"
if not exist "%RSCRIPT_EXE%" (
  echo ERROR: Rscript.exe not found at that path.
  echo Listing "%R_HOME%\bin" if it exists:
  dir "%R_HOME%\bin" 2>nul
  exit /b 1
) else ( %DEBUG_ECHO% RSCRIPT_EXE exists.)

%DEBUG_ECHO% Testing to see if RScript is runnable directly:
"%R_HOME%\bin\Rscript.exe" --version
if errorlevel 1 (
  echo ERROR: Rscript failed to run
  exit /b 1
) else (
  %DEBUG_ECHO% SUCCESS: Rscript ran correctly
)

REM --- Set PATH for THIS script run ---
set "PATH=%R_HOME%\bin;%PATH%"

REM -----------------------------------------------------------------------
REM ---  LOG SETUP AND TESTS ------
REM -----------------------------------------------------------------------

REM -- Specify the log file name for stderr and stdout output
set "LOG_NAME=CacheBuilderLog_%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "LOG_FILE=%LOGS_PATH%\%LOG_NAME%

REM -- Resolve LOG_FILE to a full absolute path and print it
for %%F in ("%LOG_FILE%") do set "LOG_FILE=%%~fF"
%DEBUG_ECHO% LOG_FILE full path = "%LOG_FILE%"

REM -- Ensure the directory exists (do NOT create it)
REM -- It likely means the kiosk name is incorrect
for %%D in ("%LOG_FILE%") do (
  if not exist "%%~dpD" (
    echo ERROR: Logs directory does not exist: "%%~dpD"
    exit /b 1
  ) else (
    %DEBUG_ECHO% Log directory exists: "%%~dpD"
  )
)

REM -- Create/append a test line to the log, then VERIFY the file exists
>> "%LOG_FILE%" (echo --- Log initialized: %DATE% %TIME% ---)
if exist "%LOG_FILE%" (
  %DEBUG_ECHO%  Log file exists now: "%LOG_FILE%"
) else (
  echo ERROR: After writing, log file still not found: "%LOG_FILE%"
  echo Current directory is: "%CD%"
  exit /b 1
)

REM Show it in a directory listing (includes hidden/system)
REM dir /a "%LOG_FILE%"


REM -----------------------------------------------------------------------
REM ---  Run target .R file
REM -----------------------------------------------------------------------

REM --- R assumes this is the top-level directory and all files that your Rscript 
REM --- calls are relative to it. So we cd to it the execute R
cd "%SCRIPTS_PATH%"

REM --- make the call
echo Running the Rscript now.
"%RSCRIPT_EXE%" "%SCRIPTS_PATH%\%RSCRIPT_FILE%" >> "%LOG_FILE%" 2>&1

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
