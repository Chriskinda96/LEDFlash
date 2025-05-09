# LEDFlash
Flash the hidden LED light for notifications received on a Motorola device.

## Purpose

This setup utilizes a KernelSU module and the MacroDroid automation app to provide a persistent notification indicator using a device's built-in LED. When a notification is received while the screen is off, the designated LED will flash continuously until the device is unlocked.

This was configured and tested on a Motorola Edge 2023+ running Android 15, using the charging LED found at `/sys/class/leds/charging/brightness`.

## Requirements

* Android device rooted with **KernelSU**.
* Magisk may work but havent tested with it.
* **MacroDroid** app installed.
* Necessary permissions granted to MacroDroid:
    * Notification Access (Android Settings -> Special app access).
    * Root Access.
    * Battery Optimization set to **"Unrestricted"** (Android Settings -> Apps -> MacroDroid -> Battery).
    * Exemption from any **device-specific** background task killers or power-saving features.
* Knowledge of the correct `/sys/class/leds/.../brightness` path for the LED you wish to control on your specific device.

## KernelSU Module Components (`LEDFlash`)

This module provides the core scripts for controlling the LED.

* **`start_led.sh`**: The script executed to begin flashing.
    * Checks if a flashing process is already running (using a PID file) and exits if so.
    * Starts an infinite `while true` loop in the background (`&`) to toggle the LED brightness.
    * Includes a `trap` command to ensure the LED is turned off if the script receives a termination signal (e.g., from `kill`).
    * Records the Process ID (PID) of the background loop into `/data/local/tmp/led_flasher.pid`.
    * Exits, leaving the background loop running.
* **`stop_led.sh`**: The script executed to stop flashing.
    * Reads the PID from `/data/local/tmp/led_flasher.pid`.
    * Sends a termination signal (`kill $PID`) to the background loop process.
    * Removes the `/data/local/tmp/led_flasher.pid` file.
    * Includes a failsafe command to explicitly turn the LED off (`echo 0 > ...`).

## Installation

1.  **Verify/Edit Scripts:**
    * Ensure the `LED_PATH` variable inside *both* `start_led.sh` and `stop_led.sh` points to the correct `/sys/class/leds/.../brightness` file for your device. You can verify this by executing `su -c "echo > 255 /sys/class/leds/charging/brightness"` in Termux or using adb shell. If it turns on, you're good to go. Just execute `su -c "echo > 0 /sys/class/leds/charging/brightness"` to turn it off, then continue with installation.
    * Adjust `sleep` durations in the `while true` loop within `start_led.sh` to change the flash rate if desired.
    * Ensure the filenames (`start_led.sh`, `stop_led.sh`) are consistent everywhere (in the files themselves, in `customize.sh`, and later in MacroDroid).
2.  **Create Module ZIP:** Create a ZIP archive containing `module.prop`, `customize.sh`, `start_led.sh`, and `stop_led.sh` directly in the root of the archive (not inside a subfolder).
3.  **Install via KernelSU:** Open the KernelSU Manager app, go to the "Modules" tab, tap "Install", and select the ZIP file you created.
4.  **Reboot:** Reboot your device when prompted.

## MacroDroid Setup

You need two macros in MacroDroid:

**Macro 1: Start LED Flash**

* **Trigger:** `Notification` -> `Notification Received`
    * Configure which applications should trigger the flash (e.g., "Select Applications..." or "Any Application").
    * Consider enabling "Prevent Multiple Triggers" if appropriate for your use case.
* **Constraint:** `Device State` -> `Screen Off`
* **Actions:**
    1.  `Device Actions` -> `Wake Lock` -> Mode: `Acquire Wake Lock`, Type: `Partial Wake Lock`, Timeout: `10 Seconds` (Adjust if needed, should be short).
    2.  `Shell Script`
        * Enter the full path to your start script: `/data/adb/modules/LEDFlash/start_led.sh`
        * **Tick the box "Run as root"**.
    3.  `Device Actions` -> `Wake Lock` -> Mode: `Release Wake Lock` (Optional, good practice).
* **Save and Enable** the macro.

**Macro 2: Stop LED Flash**

* **Trigger:** `Device Events` -> `Device Unlocked`.
* Optional `Device Events` -> `Screen On`. This will stop the LED when you turn on the screen to check notifications. Only recommended if you don't use AOD or lift to wake, as it could cause it to stop flashing unintentionally, e.g. if the screen wakes in your pocket.
* **Constraint:** (None needed usually)
* **Actions:**
    1.  `Shell Script`
        * Enter the full path to your stop script: `/data/adb/modules/LEDFlash/stop_led.sh` (Use the same module ID as above).
        * **Tick the box "Run as root"**.
* **Save and Enable** the macro.

## Troubleshooting Notes

* **Permission Denied:** If scripts fail to run, ensure they have execute permissions. Either fix `customize.sh` (check filenames inside it) and reinstall the module, or manually set permissions via a root shell: `chmod 755 /data/adb/modules/MODULE_ID/start_led.sh /data/adb/modules/MODULE_ID/stop_led.sh`.
* **Not Triggering Screen Off:** Double-check MacroDroid's battery optimization settings (Android + device-specific), ensure the Wake Lock action is present in the "Start" macro, and review MacroDroid's System Log for errors.
* **Flashing Won't Stop / Always On:** A background process is likely stuck. Use a root shell to find the process (`ps -ef | grep '[s]h .*start_led'`) and kill it (`kill -9 PID`). Delete the PID file (`rm -f /data/local/tmp/led_flasher.pid`). Verify `stop_led.sh` content and permissions are correct. Check the "Stop" macro trigger/action.
* **Check Logs:** Use `logcat` with the script tags (`logcat -s LedFlasherStart LedFlasherLoop LedFlasherStop`) and check MacroDroid/KernelSU logs.u
