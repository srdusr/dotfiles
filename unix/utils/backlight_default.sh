#!/bin/sh
set -e

backlight_sys_dir="/sys/class/backlight/intel_backlight"

read -r max_brightness < "${backlight_sys_dir}/max_brightness"
read -r curr_brightness < "${backlight_sys_dir}/brightness"

if ! groups | grep -q backlight; then
    echo "User is not in the backlight group"
    exit 1
fi

if [ "$#" -eq 0 ] ; then
    # set to half that of 'max_brightness'
    echo $((max_brightness / 2)) > "$backlight_sys_dir"/brightness
    exit 0
fi

case "$1" in
    up) increment="+ 10" ;;
    down) increment="- 10" ;;
    *) exit 1 ;;
esac

new_brightness=$(($curr_brightness $increment))

if $((new_brightness < 1)) || $((new_brightness > $max_brightness)); then
    exit 1
else
    echo "$new_brightness" > "$backlight_sys_dir"/brightness
fi
