@echo off
REM https://stackoverflow.com/questions/3258243/check-if-pull-needed-in-git

REM Fetch latest changes
git fetch

REM Set UPSTREAM to first argument or default to @{u}
SET "UPSTREAM=%~1"
IF "%UPSTREAM%"=="" SET "UPSTREAM=@{u}"

FOR /F "usebackq delims=" %%A IN (`git rev-parse @`) DO SET "LOCAL=%%A"
FOR /F "usebackq delims=" %%A IN (`git rev-parse "%UPSTREAM%"`) DO SET "REMOTE=%%A"
FOR /F "usebackq delims=" %%A IN (`git merge-base @ "%UPSTREAM%"`) DO SET "BASE=%%A"

IF "%LOCAL%"=="%REMOTE%" (
    ECHO Up-to-date
) ELSE IF "%LOCAL%"=="%BASE%" (
    ECHO Need to pull
) ELSE IF "%REMOTE%"=="%BASE%" (
    ECHO Need to push
) ELSE (
    ECHO Diverged
)
