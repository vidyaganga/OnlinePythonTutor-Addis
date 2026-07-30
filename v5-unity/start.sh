#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Python Tutor - offline launcher for Mac and Linux (AddisCoder)
#
# HOW TO USE:
#   Open a terminal in this folder and run:   ./start.sh
#   (or double-click it and choose "Run in Terminal")
#
# Windows users: double-click start.bat instead.
#
# It starts the local server and opens Python Tutor in your web browser.
# Everything runs on this machine only - no internet is used.
# Leave the terminal window open while you work. Close it (or press Ctrl-C)
# to stop.
# ---------------------------------------------------------------------------

# Always run from this script's own folder, no matter where it's launched from.
cd "$(dirname "$0")" || exit 1

# Find a Python 3 interpreter.
if command -v python3 >/dev/null 2>&1; then
  PY=python3
elif command -v python >/dev/null 2>&1; then
  PY=python
else
  echo "ERROR: Python 3 is not installed on this machine."
  echo "Install Python 3, then run this again."
  read -r -p "Press Enter to close..."
  exit 1
fi

PORT=8003
URL="http://localhost:$PORT/"

# Opens the default web browser (Linux: xdg-open, macOS: open).
open_browser() {
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$URL" >/dev/null 2>&1 &
  elif command -v open >/dev/null 2>&1; then
    open "$URL" >/dev/null 2>&1 &
  else
    echo "Could not open a browser automatically."
  fi
}

# If something is already listening on the port, don't start a second server
# (that would crash with "Address already in use").
if (exec 3<>/dev/tcp/localhost/$PORT) 2>/dev/null; then
  exec 3>&- 3<&-
  echo "Python Tutor is already running at:  $URL"
  echo "Opening it in your browser..."
  open_browser
  echo
  echo "If that address does not work, another program may be using port $PORT."
  echo "To see what it is, run:   lsof -nP -iTCP:$PORT -sTCP:LISTEN"
  echo "To stop it, run:          kill \$(lsof -t -iTCP:$PORT -sTCP:LISTEN)"
  exit 0
fi

echo "Starting Python Tutor..."

# Wait (up to ~15s) until the server is accepting connections, then open the
# browser. Runs in the background so the server itself can stay in the
# foreground. Uses bash's built-in /dev/tcp - no extra tools needed.
(
  for _ in $(seq 1 30); do
    if (exec 3<>/dev/tcp/localhost/$PORT) 2>/dev/null; then
      exec 3>&- 3<&-
      open_browser
      break
    fi
    sleep 0.5
  done
) &

echo
echo "Python Tutor will be running at:  $URL"
echo "If a browser tab does not open, type that address into your browser."
echo "Keep this window open. Press Ctrl-C (or close it) to stop."
echo

# Replace this shell with the server, so the server IS this process. That way
# Ctrl-C and closing the window go straight to it and the port is always freed
# - no leftover background process can survive and hold port $PORT.
exec "$PY" bottle_server.py
