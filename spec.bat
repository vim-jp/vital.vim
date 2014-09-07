@echo off
setlocal

if "%TEMP%" == "" (
  if not "%TMP%" == "" (
    set TEMP=%TMP%
  ) else (
    echo ERROR: Please set environment TEMP or TMP
    exit 1
  )
)

where /q vim
if not errorlevel 0 (
  echo ERROR: vim is not found in your PATH
  exit 1
)

call :strlen "%CD%"
set /a CD_LEN=%ERRORLEVEL% + 1

set VIM=vim -u NONE -i NONE -N -e -s
set SPEC_RESULT=%TEMP%\vital_spec.result
set SPEC_OUT=%TEMP%\vital_spec.out

set VERBOSE=0
set VIMPROC=
:getopts
set OPT=%~1
if "%OPT:~0,1%" == "/" (
  if /i "%OPT%" == "/p" (
    if not exist "%~2\autoload\vimproc.vim" (
      call :usage "invalid argument /p"
    )
    set VIMPROC=%~2
    shift
  ) else if /i "%OPT%" == "/v" (
    set /a VERBOSE+=1
  ) else if /i "%OPT%" == "/h" (
    call :usage
  ) else (
    call :usage "invalid option"
  )
  shift
  goto :getopts
)

if not "%2" == "" (
  call :usage "too many arguments"
)

if not "%1" == "" (
  if not exist "%~1" (
    echo ERROR: file not found: %~1
    exit 1
  )
  call :do_test %1 "%SPEC_RESULT%"
) else (
  rem all test
  for /r spec %%i in (*.vim) do (
    set SPEC=%%i
    setlocal enabledelayedexpansion
    rem absolute -> relative
    if "!SPEC:~0,%CD_LEN%!" == "%CD%\" (
      set SPEC=!SPEC:~%CD_LEN%!
    )

    if not "!SPEC!" == "spec\base.vim" (
      echo Testing... !SPEC!
      call :do_test "!SPEC!" "%SPEC_OUT%"

      type "%SPEC_OUT%" >> "%SPEC_RESULT%"
      del "%SPEC_OUT%"
    )
    endlocal
  )
)

echo.
if %VERBOSE% gtr 0 (
  type "%SPEC_RESULT%"
) else (
  setlocal enabledelayedexpansion
  for /f "usebackq delims=" %%l in (`findstr /b /r /v "/c:\[.\]" "%SPEC_RESULT%"`) do (
    echo %%l
    set /a CNT+=1
  )
  if !CNT! gtr 0 (
    echo.
  )
  endlocal
)

call :wc_l ^^\[.\]
set TESTS=%ERRORLEVEL%
call :wc_l ^^\[F\]
set F_TESTS=%ERRORLEVEL%
call :wc_l " - "
set F_ASSERTS=%ERRORLEVEL%
call :wc_l ^^\[E\]
set E_SPECS=%ERRORLEVEL%

del %SPEC_RESULT%

if %F_TESTS% equ 0 (
  echo %TESTS% tests success
) else (
  echo FAILURE!
  if %E_SPECS% equ 0 (
    echo %TESTS% tests. Failure: %F_TESTS% tests, %F_ASSERTS% assertions
  ) else (
    echo %TESTS% tests. Failure: %F_TESTS% tests, %F_ASSERTS% assertions. Error: %E_SPECS% specs
  )
  exit 1
)

goto :EOF

:: sub routines

:: usage
:usage
if not "%~1" == "" (
  echo %~1
)
echo Usage spec [/h][/v][/p ^<dir^>] [spec_file]
echo     /p: vimproc directory
echo     /h: display usage text
echo     /v: verbose mode
exit 1

:: do_test
:do_test
setlocal
if not "%VIMPROC%" == "" (
  set ARGS=%ARGS% --cmd "let g:vimproc_path='%VIMPROC%'"
)
set ARGS=%ARGS% --cmd "filetype indent on"
set ARGS=%ARGS% -S "%~1"
set ARGS=%ARGS% -c "FinUpdate "%~2""
%VIM% %ARGS%
:: report error when Vim was aborted
set RV=%ERRORLEVEL%
if not exist "%~2" (
  > "%~2" (
    @echo [E] %~1
    @echo.
    @echo Error
    @echo   %~1
    @echo     ^^! Vim exited with status %rv%
    @echo.
  )
)
exit /b %RV%

:: wc_l like "wc -l" on UNIX
:wc_l
setlocal
for /f "usebackq" %%l in (`findstr /r "/c:%~1" "%SPEC_RESULT%"`) do (
  set /a CNT+=1
)
exit /b %CNT%

:: strlen
:strlen
setlocal enabledelayedexpansion
set STR=%~1
for /l %%i in (0, 1, 260) do (
  if not "!STR:~%%i,1!" == "" (
    set /a LEN+=1
  )
)
exit /b %LEN%
