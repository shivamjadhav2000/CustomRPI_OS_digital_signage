#!/bin/bash

# Function to print the IP address
print_ip_address() {
    ip_address=$(hostname -I | awk '{print $1}')
    echo "Current IP address: $ip_address"
}

# Check if this is the first boot by checking for a marker file
if [ ! -f ~/.host_renamed ]; then
    confirmed="no"
    while [ "$confirmed" != "yes" ]; do
        # Print the current IP address
        print_ip_address

        echo "This is the first boot. Please enter the new hostname: "
        read new_hostname

        # Confirm the hostname change
        echo "You entered '$new_hostname'. Is this correct? (yes/no)"
        read confirmed
    done

    # Rename the hostname
    sudo hostnamectl set-hostname "$new_hostname"

    # Mark the hostname as changed
    touch ~/.host_renamed

    echo "Hostname changed to $new_hostname. The system will reboot now."
    sudo reboot
fi