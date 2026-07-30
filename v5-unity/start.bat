@echo off
rem ---------------------------------------------------------------------------
rem Python Tutor - offline launcher for Windows (AddisCoder)
rem
rem HOW TO USE:
rem   Double-click this file.  (Or open a Command Prompt here and run start.bat)
rem
rem It starts the local server and opens Python Tutor in your web browser.
rem Everything runs on this machine only - no internet is used.
rem Leave this window open while you work. Close it (or press Ctrl-C) to stop.
rem
rem Mac and Linux users: run start.sh instead.
rem ---------------------------------------------------------------------------

setlocal

rem This script calls itself with --open-browser to open the browser in the
rem background while the server runs in this window. Students never pass it.
if "%~1"=="--open-browser" goto open_browser

rem Always run from this script's own folder, no matter where it's launched from.
cd /d "%~dp0"

set URL=http://localhost:8003/

rem If something is already listening on the port, don't start a second server
rem (that would crash with "Address already in use").
netstat -ano | findstr /r /c:":8003 .*LISTENING" >nul 2>&1
if not errorlevel 1 (
  echo Python Tutor is already running at:  %URL%
  echo Opening it in your browser...
  start "" "%URL%"
  echo.
  echo If that address does not work, another program may be using port 8003.
  echo To see what it is, run:   netstat -ano ^| findstr :8003
  echo Then stop that program, or restart your computer, and try again.
  echo.
  pause
  exit /b 0
)

rem Find a Python 3 interpreter. Prefer the official "py" launcher, which is
rem what the python.org installer sets up, then fall back to "python".
set PY=
where py >nul 2>&1
if not errorlevel 1 set PY=py -3
if not defined PY (
  where python >nul 2>&1
  if not errorlevel 1 set PY=python
)

if not defined PY (
  echo ERROR: Python 3 is not installed on this machine, or it is not on your PATH.
  echo Install Python 3 from https://www.python.org/downloads/ and be sure to tick
  echo "Add Python to PATH" in the installer, then run this again.
  echo.
  pause
  exit /b 1
)

rem Make sure it really is Python 3 and not an old Python 2.
%PY% -c "import sys; sys.exit(0 if sys.version_info[0] == 3 else 1)" >nul 2>&1
if errorlevel 1 (
  echo ERROR: "%PY%" is not Python 3.
  echo Install Python 3 from https://www.python.org/downloads/ and run this again.
  echo.
  pause
  exit /b 1
)

echo Starting Python Tutor...
echo.
echo Python Tutor will be running at:  %URL%
echo If a browser tab does not open, type that address into your browser.
echo Keep this window open. Press Ctrl-C (or close it) to stop.
echo.

rem Open the browser from a second copy of this script, once the server is up.
start "" /b "%~f0" --open-browser

rem Run the server in THIS window, so closing the window or pressing Ctrl-C
rem stops it and frees port 8003. Nothing is left running in the background.
%PY% bottle_server.py

rem Keep the window open if the server stopped because of an error - on a
rem double-click the window closes instantly, which would hide the message
rem saying what went wrong. A normal Ctrl-C stop exits 0 and stays quiet.
if errorlevel 1 (
  echo.
  echo Python Tutor stopped unexpectedly. The message above says why.
  pause
)

exit /b 0


rem ---------------------------------------------------------------------------
rem Waits (up to ~30s) until the server answers, then opens the browser.
rem ---------------------------------------------------------------------------
:open_browser
rem curl ships with Windows 10 (1803) and later. If it is missing, just wait a
rem few seconds and open the browser anyway.
where curl >nul 2>&1
if errorlevel 1 (
  rem "ping" is used as a sleep - "timeout" can fail when this script is run
  rem from another script rather than typed at a prompt.
  ping -n 5 127.0.0.1 >nul
  start "" "http://localhost:8003/"
  exit /b 0
)

for /l %%i in (1,1,30) do (
  curl -s -o nul --max-time 2 http://localhost:8003/ >nul 2>&1
  if not errorlevel 1 (
    start "" "http://localhost:8003/"
    exit /b 0
  )
  ping -n 2 127.0.0.1 >nul
)

rem Server never came up in time - open the browser anyway so the student sees
rem something rather than nothing.
start "" "http://localhost:8003/"
exit /b 0
