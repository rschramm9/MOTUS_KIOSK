This is the LOGS_README.md  Please do not delete. It is here mostly to force git to create the Logs directory when cloning the repository.  If the directery were to be empty - git would not create it. 

The Logs directory contains Motus Kiosk server log files for MS Windows deployments.

On windows boot, the TaskScheduler runs task MOTUS_MSWINDOWS_STARTSERVER_TASK_ which executes MOTUS_MSWINDOWS_STARTSERVER.bat 

MOTUS_MSWINDOWS_STARTSERVER.bat runs the kiosk via R and redirects console stdout and stderr messages to the log file which is helpful to debug startup issues.



