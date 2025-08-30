#!/usr/bin/env sh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 1; done


# Launch bar
#polybar main-0 &
polybar main-1 &
polybar main-2 &
polybar main-3 &
polybar main-4 &
polybar main-5 &

# Define bars per monitors
#declare -A ARRANGEMENTS=(["$mainmonitor"]="main-0" ["$secondmonitor"]="main-0")
declare -A ARRANGEMENTS=(["$mainmonitor"]="main-1,main-2,main-3,main-4,main-5" ["$secondmonitor"]="main-1,main-2,main-3,main-4,main-5")

# Each key
for MONITOR in "${!ARRANGEMENTS[@]}"; do
    # split at `,` into array
    while IFS=',' read -ra BARLIST; do
        # for each bar (seperated by `,`) at current key
        for BAR in "${BARLIST[@]}"; do
            MONITOR="$MONITOR" polybar --reload "$BAR" &
        done
    done <<< "${ARRANGEMENTS[$MONITOR]}"
done
