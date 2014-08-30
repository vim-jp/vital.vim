@echo off

if not "%TEMP%" == "" (
  set _TEMP=%TEMP%
) else if not "%TMP%" == "" (
  set _TEMP=%TMP%
) else (
  echo ERROR: Please set environment TEMP or TMP
  goto end
)

where /q vim
if not errorlevel 0 (
  echo ERROR: vim is not found in your PATH
  goto end
)

set VIM=vim
set FIND=%windir%\system32\find.exe
set SPEC_FILE=nul
set VIMPROC=nul
set OUTFILE=%_TEMP%\vital_spec.result
set FATAL=false

type nul > %OUTFILE%


call :parse_args %1 %2 %3 %4 %5 %6 %7 %8 %9

if not "%SPEC_FILE%" == "nul" (
  %VIM% -u NONE -i NONE -N --cmd "filetype indent on" -S "%SPEC_FILE%" -c "FinUpdate %OUTFILE%"
  if not %errorlevel% == 0 set FATAL=true
) else (
  rem all test
  rem %%i = relative filepath
  rem TODO but fullpath on Windows7(32bit). why?
  for /r spec %%i in (*.vim) do (
    rem %%~ni = filename
    if not "%%~ni" == "base" (
      echo Testing... %%i
      if not "%VIMPROC%" == "nul" (
        %VIM% -u NONE -i NONE -N --cmd "let g:vimproc_path='%VIMPROC%'" --cmd "filetype indent on" -S "%%i" -c "FinUpdate %OUTFILE%"
      ) else (
        %VIM% -u NONE -i NONE -N --cmd "filetype indent on" -S "%%i" -c "FinUpdate %OUTFILE%"
      )
      if not %errorlevel% == 0 set FATAL=true
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

:: parsing arguments
:parse_args

if "%1" == "" (
  goto parse_args_end
) else if /i "%1" == "/p" (
  set VIMPROC=%2
  shift
) else (
  set SPEC_FILE=%1
)
shift
goto :parse_args

:parse_args_end
exit /b

:end

if %FATAL% == "true" (
  exit 1
) else (
  exit 0
)
