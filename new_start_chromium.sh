#!/bin/bash

# Set the display resolution
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

# Check for a custom URL
if [ -f /home/cvadsign/custom_url.conf ]; then
    SIGNAGE_URL=$(cat /home/cvadsign/custom_url.conf)
else
    SIGNAGE_URL="https://cdn.signage.unt.edu/hostnames/$(hostname)/"
fi

# Launch Chromium in kiosk mode with autoplay disabled
chromium-browser --noerrdialogs --disable-infobars --kiosk \
    --user-data-dir=/home/cvadsign/temp_chrome_profile \
    --autoplay-policy=no-user-gesture-required "$SIGNAGE_URL"
