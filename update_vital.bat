@echo off
setlocal
set VITAL_HOME=%~dp0
set VITAL_HOME=%VITAL_HOME:~0,-1%
if %VITAL_HOME:~-1%==\ SET VITAL_HOME=%VITAL_HOME:~0,-1%

set TARGET=%1
if "%TARGET%" equ "" set TARGET=%CD%
ruby "%VITAL_HOME%\vitalize.rb" "%VITAL_HOME%" "%TARGET%"
endlocal
