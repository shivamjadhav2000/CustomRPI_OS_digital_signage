#!/bin/bash

# Set the display resolution (adjust this based on your setup)
xrandr --output HDMI-1 --mode 1920x1080

# Start X server if it's not already running
if [ -z "$DISPLAY" ]; then
    startx &
    sleep 5  # Give X server some time to start
    export DISPLAY=:0
fi

# Disable screen saver and power management
xset s off
xset -dpms
xset s noblank

# Start the Openbox window manager
openbox &

# Clear any previous temporary Chromium profile to avoid locking issues
rm -rf /home/cvadsign/temp_chrome_profile

# Launch Chromium in kiosk mode with a fresh user profile
chromium-browser --noerrdialogs --disable-infobars --kiosk --user-data-dir=/home/cvadsign/temp_chrome_profile 'https://cdn.signage.unt.edu/hostnames/$(hostname)/'