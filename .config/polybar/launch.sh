#!/usr/bin/env sh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch bar
polybar top &
#polybar bottom &
#polybar left &
#polybar top_external &

#sleep 5 && xdo raise -N "polybar-bottom_LVDS-1" &
if [[ $(xrandr -q | grep 'HDMI-1 connected') ]]: then
    polybar top_external &
fi
