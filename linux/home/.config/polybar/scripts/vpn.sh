#!/bin/sh

# Set a default message
default_message=" vpn"

# Check if Protonvpn service is running
if pgrep -x "openvpn" >/dev/null; then
    # If Protonvpn service is running, get the country
    country=$(protonvpn s | grep Country)
    # Extract the connection ID
    connection=$(pgrep -a openvpn$ | head -n 1 | awk '{print $NF }' | cut -d '.' -f 1)
    # Output vpn status with the country if connected
    echo " vpn" #"$country"
else
    # If Protonvpn service is not running, output default message
    echo "$default_message"
fi

#
#proton_status=$(protonvpn s)
#current_status=$(protonvpn s | wc -l)
#current_server=$(protonvpn s | awk '/Server:/ {print "VPN "$2}')
#
#if [ "$current_status" -gt 2 ]; then
#    echo "$current_server"
#else
#    echo "%{F#bf616a}NO VPN"
#fi
