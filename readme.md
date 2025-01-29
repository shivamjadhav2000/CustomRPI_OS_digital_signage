
# Raspberry Pi Signage Setup

This README provides the steps to set up a Raspberry Pi for a signage application, which includes auto-login, hostname setup, and configuring the system to run Chromium in kiosk mode. It also covers setting a custom URL for signage content.

## Steps

### 1. Update the system
```bash
sudo apt update
sudo apt-get update
```

### 2. Enable auto-login for `cvadsign` user
Create the necessary directory for the `getty` service:
```bash
sudo mkdir /etc/systemd/system/getty@tty1.service.d/
```

Create and edit the auto-login configuration file:
```bash
sudo nano /etc/systemd/system/getty@tty1.service.d/autologin.conf
```

Paste the following content:
```ini
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin cvadsign --noclear %I $TERM
```

Reload the systemd configuration and reboot:
```bash
sudo systemctl daemon-reload
sudo reboot
```

### 3. Configure the hostname change script

Create the `rename_host.sh` script:
```bash
nano ~/.rename_host.sh
```

Paste the following content in `rename_host.sh`:
```bash
#!/bin/bash

# Get the local device's IP address (assuming eth0 or wlan0)
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Check if an IP address is obtained
if [ -z "$IP_ADDRESS" ]; then
    echo "No IP address found for this device."
    exit 1
fi

# Perform Reverse DNS Lookup using 'getent hosts'
FQDN=$(getent hosts "$IP_ADDRESS" | awk '{print $2}')

# Function to update hostname and hosts file
set_hostname() {
    local new_hostname=$1
    echo "Setting hostname to: $new_hostname"

    # Apply the new hostname
    sudo hostnamectl set-hostname "$new_hostname"

    # Update /etc/hosts
    sudo sed -i "s/^127.0.1.1.*/127.0.1.1 $new_hostname.cvad.unt.edu $new_hostname/" /etc/hosts

    # Create a marker file so we skip this check next time
    touch ~/.host_renamed

    echo "Hostname set to $new_hostname. Rebooting now..."
    sudo reboot
}

# Function to prompt user when FQDN is not found
handle_missing_fqdn() {
    echo "Error: This device is not registered with an FQDN."
    echo "Do you want to:"
    echo "1) Reboot"
    echo "2) Shutdown"
    echo "3) Provide a custom URL (full path included)"
    read -p "Enter your choice (1/2/3): " choice

    case $choice in
        1) sudo reboot ;;
        2) sudo shutdown -h now ;;
        3) /home/cvadsign/assign_custom_url.sh ;;
        *) echo "Invalid option. Exiting." ;;
    esac
}

# Check if the hostname has already been assigned
if [ ! -f ~/.host_renamed ]; then
    if [[ -n "$FQDN" && "$FQDN" == *".cvad.unt.edu" ]]; then
        HOSTNAME_PART=$(echo "$FQDN" | cut -d'.' -f1)
        set_hostname "$HOSTNAME_PART"
    else
        handle_missing_fqdn
    fi
fi

```

Make the script executable:
```bash
chmod +x ~/.rename_host.sh
```

### 4. Update `.bash_profile`

Edit the `.bash_profile` file:
```bash
nano ~/.bash_profile
```

Add the following lines to run the `rename_host.sh` script on login:
```bash
~/.rename_host.sh
if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
    startx  
fi
```

### 5. Install and configure Chromium in Kiosk Mode

Create the `start_chromium.sh` script:
```bash
nano ~/.start_chromium.sh
```

Paste the following content in `start_chromium.sh`:
```bash
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


```

Make the script executable:
```bash
chmod +x ~/.start_chromium.sh
```

### 6. Install necessary packages
Install the necessary packages for X server and Chromium:
```bash
sudo apt update
sudo apt install --no-install-recommends xserver-xorg x11-xserver-utils xinit openbox chromium-browser
```

Reboot the system:
```bash
reboot
```

### 7. Configure X server settings
Create the `99-fbdev.conf` file:
```bash
sudo nano /etc/X11/xorg.conf.d/99-fbdev.conf
```

Paste the following content:
```bash
Section "Device"
    Identifier "FBDEV"
    Driver "fbdev"
EndSection
```

Install X server legacy support:
```bash
sudo apt install xserver-xorg-legacy
```

Reboot the system:
```bash
sudo reboot
```

### 8. Create the custom URL assignment script
Create the `assign_custom_url.sh` script:
```bash
nano ~/.assign_custom_url.sh
```

Paste the following content:
```bash
#!/bin/bash

CONFIG_FILE="/home/cvadsign/custom_url.conf"

echo "Enter the full URL you want to use instead of the default signage server:"
read custom_url

if [[ -n "$custom_url" ]]; then
    echo "$custom_url" > "$CONFIG_FILE"
    echo "Custom URL set to $custom_url"
else
    echo "Invalid URL. No changes made."
fi

```

Make the script executable:
```bash
chmod +x ~/.assign_custom_url.sh
```

### 9. Set the URL in `~/.xinitrc`
Edit `~/.xinitrc` to run the `start_chromium.sh` script:
```bash
nano ~/.xinitrc
```

Add the following line:
```bash
exec ~/.start_chromium.sh
```

### 10. Add user to necessary groups
Add the user to the `tty` and `video` groups:
```bash
sudo usermod -aG tty,video cvadsign
```

### 11. Additional Configuration

Update the system and add the backports repository:
```bash
sudo apt update -y
. /etc/os-release
echo "deb http://deb.debian.org/debian ${VERSION_CODENAME}-backports main" | sudo tee /etc/apt/sources.list.d/backports.list
sudo apt update
sudo apt install -t ${VERSION_CODENAME}-backports cockpit
```

### 12. Final Reboot
Reboot the system one final time:
```bash
sudo reboot
```
