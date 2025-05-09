#!/system/bin/sh
TAG="LedFlasherStart"
# Using /data/local/tmp is usually safe and accessible
PIDFILE="/data/local/tmp/led_flasher.pid"

# --- LED Path and Max Brightness Setup (Same as before) ---
LED_PATH="/sys/class/leds/charging/brightness"
if [ ! -f "$LED_PATH" ]; then log -p e -t $TAG "Error: LED path $LED_PATH not found"; exit 1; fi
MAX_BRIGHTNESS=$(cat "$(dirname "$LED_PATH")/max_brightness" 2>/dev/null)
if [ -z "$MAX_BRIGHTNESS" ] || [ "$MAX_BRIGHTNESS" -eq 0 ]; then MAX_BRIGHTNESS=255; fi
# --- End LED Setup ---

# Check if already running (prevents multiple loops)
if [ -f "$PIDFILE" ]; then
  OLDPID=$(cat "$PIDFILE")
  # Check if the process with that PID actually exists
  if kill -0 "$OLDPID" 2>/dev/null; then
    log -p i -t $TAG "Flasher already running (PID $OLDPID). Exiting."
    exit 0 # Exit cleanly, already running
  else
    log -p w -t $TAG "Stale PID file found ($OLDPID). Removing."
    rm -f "$PIDFILE" # Use -f to avoid error if file disappears
  fi
fi

log -p i -t $TAG "Starting background flash loop..."

# Define the function that will loop in the background
flash_loop() {
  # Set a trap: Commands here run when the script receives specific signals
  # This ensures the LED turns off when killed by the stop script (TERM signal)
  # or other signals like INT (Ctrl+C), HUP.
  trap 'echo 0 > "$LED_PATH" 2>/dev/null; log -p i -t LedFlasherLoop "Exiting loop (PID $$), ensuring LED OFF"; exit 0' EXIT TERM INT HUP

  log -p i -t LedFlasherLoop "Loop started (PID $$) for $LED_PATH"
  # Loop forever
  while true; do
    echo "$MAX_BRIGHTNESS" > "$LED_PATH"
    sleep 0.3 # ON duration (adjust as desired)
    echo 0 > "$LED_PATH"
    sleep 1.0 # OFF duration (adjust as desired)
  done
}

# Start the function in the background (&)
flash_loop &

# Capture the Process ID (PID) of the command just backgrounded ($!)
BG_PID=$!
log -p i -t $TAG "Background loop started with PID: $BG_PID"

# Store this PID in the file
echo "$BG_PID" > "$PIDFILE"
if [ $? -ne 0 ]; then
  log -p e -t $TAG "Failed to write PID $BG_PID to $PIDFILE!"
  # If we can't store the PID, we can't stop it later, so kill the background process
  kill "$BG_PID" 2>/dev/null
  exit 1
fi

log -p i -t $TAG "PID file created at $PIDFILE. Starter script exiting."
# This starter script finishes, leaving the background loop running
exit 0