#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Python Tutor - offline launcher (AddisCoder)
#
# HOW TO USE:
#   Open a terminal in this folder and run:   ./start.sh
#   (or double-click it and choose "Run in Terminal")
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

URL="http://localhost:8003/"

echo "Starting Python Tutor..."
"$PY" bottle_server.py &
SERVER_PID=$!

# Stop the server cleanly when this window is closed or Ctrl-C is pressed.
trap 'echo; echo "Stopping Python Tutor..."; kill "$SERVER_PID" 2>/dev/null; exit 0' INT TERM

# Wait (up to ~15s) until the server is actually accepting connections,
# then open the browser. Uses bash's built-in /dev/tcp - no extra tools needed.
for _ in $(seq 1 30); do
  if (exec 3<>/dev/tcp/localhost/8003) 2>/dev/null; then
    exec 3>&- 3<&-
    break
  fi
  sleep 0.5
done

# Open the default web browser (Linux: xdg-open, macOS: open).
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$URL" >/dev/null 2>&1 &
elif command -v open >/dev/null 2>&1; then
  open "$URL" &
else
  echo "Could not open a browser automatically."
fi

echo
echo "Python Tutor is running at:  $URL"
echo "If a browser tab did not open, type that address into your browser."
echo "Keep this window open. Press Ctrl-C (or close it) to stop."

# Keep the script alive so the server keeps running and Ctrl-C works.
wait "$SERVER_PID"
