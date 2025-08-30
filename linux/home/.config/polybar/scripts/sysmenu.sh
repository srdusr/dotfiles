#!/bin/bash

# Display a power menu to: shutdown, reboot,
# lock, logout, and suspend. This script can be
# executed by clicking on the polybar powermenu module
# or with a keyboard shortcut

# Options to be displayed
shutdown=" Shutdown"
reboot=" Reboot"
lock=" Lock"
logout=" Logout"
suspend=" Suspend"

uptime=$(uptime -p | sed -e 's/up //g')

# Options passed into variable
options="$shutdown\n$reboot\n$lock\n$logout\n$suspend"

# Specify the path to the Rofi configuration file
config_file="$HOME/.config/rofi/styles/powermenu.rasi"

# Show Rofi with the specified configuration file
chosen="$(echo -e "$options" | rofi -no-lazy-grab -sep -config "$config_file" -dmenu -p 'System ' "$uptime")"

case $chosen in
    $shutdown)
        shutdown now
        ;;
    $reboot)
        systemctl reboot
        ;;
    $lock)
        betterlockscreen --lock dimblur
        ;;
    $logout)
        bspc quit
        ;;
    $suspend)
        systemctl suspend
        ;;
esac
