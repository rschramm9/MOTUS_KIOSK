REM  MOTUS_MSWINDOWS_BUILDCACHE.bat
REM  14-Jan-2025
REM  Version 1.0

REM  Runs the BuildCache.R script to walks all receivers in the user's
REM  kiosk.cfg file and create a complete
REM  cached dataset for all tag detections at all receivers so
REM  the kiosk gui can be more responsive

REM  Configure this script to be run nightly by the Windows task manager

REM  As you must customize this file with names and paths specific to your kiosk,
REM  it lives in the kiosk-specific directory in the 'extras' folder of the
REM  just below the directory with your kiosk.cfg file. 
REM  e.g. C:\Users\MOTUS_USER\Documents\kiosks\your-kiosk-name\extras

@echo off

C:

REM - Configure the following four items for your configuration

PATH "C:\R\R-4.4.2\bin
set "SCRIPTS_PATH=C:\Users\MOTUS_USER\Projects\MOTUS_KIOSK"
set "LOGS_PATH=C:\Users\MOTUS_USER\Documents\kiosks\DEFAULT\logs"
set "RSCRIPT_FILE=BuildCache.R"

REM - You shouldnt normally need to modify below this line
REM -----------------------------------------------------------------------

REM Specify the Rscript file name (ensure the script is in the SCRIPTS_PATH directory)
set "RSCRIPT_FILE=BuildCache.R"

REM Specify the log file name for stderr and stdout output
set "LOG_NAME=Log_%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "LOG_FILE=%LOGS_PATH%\%LOG_NAME%

REM Check if the Rscript file exists
if not exist "%SCRIPTS_PATH%\%RSCRIPT_FILE%" (
    echo R script not found on Desktop: "%RSCRIPT_FILE%" >> "%LOG_FILE%"
    exit /b 1
)

REM Execute the R script and redirect stdout and stderr
REM Rscript "%SCRIPTS_PATH%\%RSCRIPT_FILE%" > "%OUTPUT_FILE%" 2>> "%LOG_FILE%"

REM  R assumes this is the top-level directory and all files R calls are below it
cd "%SCRIPTS_PATH%"

REM make the call
Rscript "%SCRIPTS_PATH%\%RSCRIPT_FILE%" >> "%LOG_FILE%" 2>&1

REM Check if the Rscript command was successful
if %ERRORLEVEL% neq 0 (
    echo R script execution failed. See log file for details: "%LOG_FILE%" >> "%LOG_FILE%"
    exit /b %ERRORLEVEL%
)

echo R script executed successfully. Output saved to "%OUTPUT_FILE%". >> "%LOG_FILE%"

EXIT /B %ERRORLEVEL%