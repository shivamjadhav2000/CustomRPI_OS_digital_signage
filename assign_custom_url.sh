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
