#!/usr/bin/bash

# This script uses upower to get all the battery informations
# https://upower.freedesktop.org/docs/Device.html

# Check if the system is not a laptop (by checking for the absence of a lid directory)
if [ ! -d "/proc/acpi/button/lid" ]; then
    # If not a laptop, show system uptime
    ICON="󰚥"
    COLOR=""
    UPTIME=$(uptime -p | sed 's/up //')                                       # Get system uptime
    SHORT_UPTIME=$(echo "$UPTIME" | awk -F " " '{print $1$2}' | sed 's/,$//') # Shortened uptime
    STRING="$COLOR$ICON Up: $SHORT_UPTIME"
    #STRING="$COLOR$ICON Uptime: $UPTIME"
    echo "$STRING"
    exit 0
else
    # Check if battery information is available
    if upower -e | grep -q '/battery'; then
        BATTERY_DEVICES=$(upower -e | grep '/battery' | grep -v 'DisplayDevice')

        if [ "$BATTERY_DEVICES" != "" ]; then
            CHARGE=$(upower -i "$BATTERY_DEVICES" | awk '/percentage/ {print $2}' | sed 's/%//')
            BAT_STATE=$(upower -i "$BATTERY_DEVICES" | awk '/state/ {print $2}')

            # Laptop is on battery, will show info about charging/discharging
            if [[ $BAT_STATE == *'discharging'* ]]; then
                ICON="󰂑"
                COLOR=""
                STRING="$COLOR$ICON Battery: $CHARGE%"
                echo "$STRING"
                exit 0
            fi
        fi
    else
        # If no battery information is available
        if [[ "$(upower -d | grep 'percentage' | awk '{print $2}')" == "0%" && "$(upower -d | grep 'on-battery' | awk '{print $2}')" == "no" ]]; then
            ICON="󱟩 "
            COLOR=""
            STRING="$COLOR$ICON No Bat"
            echo "$STRING"
            exit 0
        fi
    fi
fi

# Charging
if [[ $BAT_STATE == *'discharging'* ]]; then
    if [ "$CHARGE" -eq 0 ]; then
        ICON="󰂎"
        COLOR="%{F#fc8894}"
    elif [ "$CHARGE" -gt 0 ] && [ "$CHARGE" -le 10 ]; then
        ICON="󰁺"
        COLOR="%{F#fc8894}"
    elif [ "$CHARGE" -gt 10 ] && [ "$CHARGE" -le 20 ]; then
        ICON="󰁻"
        COLOR="%{F#fc8894}"
        #notify-send -u critical "Battery Warning" "20% charge remaining!"
    elif [ "$CHARGE" -gt 20 ] && [ "$CHARGE" -le 30 ]; then
        ICON="󰁼"
        COLOR="%{F#e3e3e3}"
    elif [ "$CHARGE" -gt 30 ] && [ "$CHARGE" -le 40 ]; then
        ICON="󰁾"
        COLOR="%{F#e3e3e3}"
    elif [ "$CHARGE" -gt 40 ] && [ "$CHARGE" -le 50 ]; then
        ICON="󰁿"
        COLOR="%{F#e3e3e3}"
    elif [ "$CHARGE" -gt 50 ] && [ "$CHARGE" -le 60 ]; then
        ICON="󰁿"
        COLOR="%{F#e3e3e3}"
    elif [ "$CHARGE" -gt 60 ] && [ "$CHARGE" -le 70 ]; then
        ICON="󰂀"
        COLOR="%{F#e3e3e3}"
    elif [ "$CHARGE" -gt 70 ] && [ "$CHARGE" -le 80 ]; then
        ICON="󰂁"
        COLOR="%{F#8be09c}"
    elif [ "$CHARGE" -gt 80 ] && [ "$CHARGE" -le 90 ]; then
        ICON="󰂂"
        COLOR="%{F#8be09c}"
    elif [ "$CHARGE" -gt 90 ]; then
        ICON="󰁹"
        COLOR="%{F#8be09c}"
    fi
    # Discharging
elif [[ $BAT_STATE == *'charging'* ]]; then
    if [ "$CHARGE" -eq 0 ]; then
        ICON="󰢟"
        COLOR="%{F#fc8894}"
    elif [ "$CHARGE" -gt 0 ] && [ "$CHARGE" -le 10 ]; then
        ICON="󰢜"
        COLOR="%{F#fc8894}"
    elif [ "$CHARGE" -gt 10 ] && [ "$CHARGE" -le 20 ]; then
        ICON="󰂆"
        COLOR="%{F#fc8894}"
    elif [ "$CHARGE" -gt 20 ] && [ "$CHARGE" -le 30 ]; then
        ICON="󰂇"
        COLOR="%{F#e3e3e3}"
    elif [ "$CHARGE" -gt 30 ] && [ "$CHARGE" -le 40 ]; then
        ICON="󰂈"
        COLOR="%{F#e3e3e3}"
    elif [ "$CHARGE" -gt 40 ] && [ "$CHARGE" -le 50 ]; then
        ICON="󰢝"
        COLOR="%{F#e3e3e3}"
    elif [ "$CHARGE" -gt 50 ] && [ "$CHARGE" -le 60 ]; then
        ICON="󰂉"
        COLOR="%{F#e3e3e3}"
    elif [ "$CHARGE" -gt 60 ] && [ "$CHARGE" -le 70 ]; then
        ICON="󰢞"
        COLOR="%{F#e3e3e3}"
    elif [ "$CHARGE" -gt 70 ] && [ "$CHARGE" -le 80 ]; then
        ICON="󰂊"
        COLOR="%{F#8be09c}"
    elif [ "$CHARGE" -gt 80 ] && [ "$CHARGE" -le 90 ]; then
        ICON="󰂋"
        COLOR="%{F#8be09c}"
    elif [ "$CHARGE" -gt 90 ]; then
        ICON="󰂅"
        COLOR="%{F#8be09c}"
    fi
elif [[ $BAT_STATE == *'fully-charged'* ]]; then
    ICON="󰂄"
    COLOR="%{F#8be09c}"
    #notify-send -u low "Battery Info" "Your battery is fully charged"
elif [[ $BAT_STATE == *'unknown'* ]]; then
    ICON="󰂑"
fi

STRING="$COLOR$ICON $CHARGE%"

# Final formatted output.
echo "$STRING"
