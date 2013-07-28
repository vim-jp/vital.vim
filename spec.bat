@echo off

if not "%TEMP%" == "" (
  set _TEMP=%TEMP%
) else if not "%TMP%" == "" (
  set _TEMP=%TMP%
) else (
  echo ERROR: Please set enviroment TEMP or TMP
  goto end
)

set VIM=vim
set FIND=%windir%\system32\find.exe
:: %1 may be empty.
set SPEC_FILE=%1
set OUTFILE=%_TEMP%\vital_spec.result
type nul > %OUTFILE%

if not "%SPEC_FILE%" == "" (
  %VIM% -u NONE -i NONE -N --cmd "filetype indent on" -S "%SPEC_FILE%" -c "FinUpdate %OUTFILE%"
) else (
  rem all test
  rem %%i = relative filepath
  rem TODO but fullpath on Windows7(32bit). why?
  for /r spec %%i in (*.vim) do (
    rem %%~ni = filename
    if not "%%~ni" == "base" (
      echo Testing... %%i
      %VIM% -u NONE -i NONE -N --cmd "filetype indent on" -S "%%i" -c "FinUpdate %OUTFILE%"
    )
  )
)

call :wc_l [F]
set FAILED_TEST_NUM=%ERRORLEVEL%
call :wc_l [.]
set /A ALL_TEST_NUM=%ERRORLEVEL%+%FAILED_TEST_NUM%
call :wc_l " - "
set FAILED_ASSERT_NUM=%ERRORLEVEL%

type %OUTFILE%

if %FAILED_TEST_NUM% == 0 (
  echo %ALL_TEST_NUM% tests success
) else (
  echo FAILURE!
  echo %ALL_TEST_NUM% tests. Failure: %FAILED_TEST_NUM% tests, %FAILED_ASSERT_NUM% assertions
)

del %OUTFILE%

goto end


::: sub routines

:: wc_l like "wc -l" on unix
:: count lines
:wc_l
:: clear %ERRORLEVEL%
cd

set PATTERN=%~1
if "%PATTERN%" == "" (
  echo ERROR: wc_l required arg
  goto end
)

set NUM=0
:: this find example:
::
:: > find /c "[.]" %OUTFILE%
:: ---------- C:\USERS\IT_USER\APPDATA\LOCAL\TEMP\VITAL_SPEC.RESULT: 96
for /f "usebackq tokens=3" %%n in (`%FIND% /c "%PATTERN%" %OUTFILE%`) do (
  rem example: %%n = 96
  set NUM=%%n
)
exit /b %NUM%

:end
