#!/system/bin/sh

# $MODPATH is the path where your module is installed, e.g., /data/adb/modules/led-flasher-helper
ui_print "- Setting permissions for start_led.sh"
set_perm "$MODPATH/start_led.sh" 0 0 0755 # Sets owner:group to root:root and permissions to rwxr-xr-x
ui_print "- Setting permissions for stop_led.sh"
set_perm "$MODPATH/stop_led.sh" 0 0 0755 # Sets owner:group to root:root and permissions to rwxr-xr-x