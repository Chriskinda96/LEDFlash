#!/system/bin/sh
TAG="LedFlasherStop"
PIDFILE="/data/local/tmp/led_flasher.pid" # Must match the path in flash_led.sh

log -p i -t $TAG "Stop script executing..."

if [ -f "$PIDFILE" ]; then
  PID=$(cat "$PIDFILE")
  # Check if the PID file contained a valid number
  if [ -n "$PID" ] && [ "$PID" -gt 0 ] 2>/dev/null; then
      log -p i -t $TAG "Found PID $PID in $PIDFILE. Attempting to stop..."
      # Check if the process actually exists before trying to kill
      if kill -0 "$PID" 2>/dev/null; then
         # Send TERM signal (signal 15), caught by the trap in flash_loop
         kill "$PID"
         if [ $? -eq 0 ]; then
           log -p i -t $TAG "TERM signal sent to PID $PID."
           # Optional: Wait briefly to allow graceful exit before removing PID file
           sleep 0.5
         else
           log -p e -t $TAG "Failed to send signal to PID $PID. Forcing kill?"
           # kill -9 "$PID" # Force kill if TERM fails (use with caution)
         fi
      else
        log -p w -t $TAG "Process with PID $PID not found (stale PID file?)."
      fi
  else
      log -p w -t $TAG "PID file $PIDFILE contained invalid PID: '$PID'"
  fi
  # Remove the PID file whether process was found or not
  rm -f "$PIDFILE"
else
  log -p i -t $TAG "PID file $PIDFILE not found. Nothing to stop."
fi

# Extra safety: Ensure LED is off (runs even if PID file didn't exist)
# Check existence (-e) rather than regular file (-f) for /sys nodes
LED_PATH="/sys/class/leds/charging/brightness"
if [ -e "$LED_PATH" ]; then
   log -p i -t $TAG "Ensuring LED is off manually."
   echo 0 > "$LED_PATH" 2>/dev/null
fi

log -p i -t $TAG "Stop script finished."
exit 0