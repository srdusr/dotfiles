#!/bin/bash

# display a power menu to: shutdown, reboot,
# lock, logout, and suspend. This script can be
# executed by clicking on the polybar powermenu module
# or with a keyboard shortcut


# options to be displayed
shutdown=" Shutdown"
reboot=" Reboot"
lock=" Lock"
logout=" Logout"
suspend=" Suspend"

uptime=$(uptime -p | sed -e 's/up //g')

# options passed into variable
options="$shutdown\n$reboot\n$lock\n$logout\n$suspend"

chosen="$(echo -e "$options" | rofi -no-lazy-grab -sep -lines 5 -hide-scrollbar true -border 0 -padding 0 -height 2px -width 15 -xoffset -8 -yoffset 28 -location 3 -columns 1 -dmenu -p 'System ' "$uptime")"

case $chosen in
$shutdown)
  systemctl poweroff
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

