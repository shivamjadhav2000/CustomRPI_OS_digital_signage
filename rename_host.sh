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
