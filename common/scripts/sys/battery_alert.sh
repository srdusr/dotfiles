#!/bin/sh

# Send a notification if the laptop battery is either low or is fully charged.

# Battery percentage at which to notify
WARNING_LEVEL=78
CRITICAL_LEVEL=5
BATTERY_DISCHARGING=$(acpi -b | grep "Battery 0" | grep -c "Discharging")
BATTERY_LEVEL=$(acpi -b | grep "Battery 0" | grep -P -o '[0-9]+(?=%)')

# Use files to store whether we've shown a notification or not (to prevent multiple notifications)
FULL_FILE=/tmp/batteryfull
EMPTY_FILE=/tmp/batteryempty
CRITICAL_FILE=/tmp/batterycritical

# Reset notifications if the computer is charging/discharging
if [ "$BATTERY_DISCHARGING" -eq 1 ]; then
    # Battery is discharging
    if [ -f "$FULL_FILE" ]; then
        command rm "$FULL_FILE"
    fi
    if [ "$BATTERY_LEVEL" -le "$WARNING_LEVEL" ] && [ ! -f "$EMPTY_FILE" ]; then
        notify-send "Low Battery" "${BATTERY_LEVEL}% of battery remaining." -u critical -i "battery-low-symbolic" -r 9991
        touch "$EMPTY_FILE"
    fi
    if [ "$BATTERY_LEVEL" -le "$CRITICAL_LEVEL" ] && [ ! -f "$CRITICAL_FILE" ]; then
        notify-send "Battery Critical" "The computer will shut down soon." -u critical -i "battery-caution-symbolic" -r 9991
        touch "$CRITICAL_FILE"
    fi
elif [ "$BATTERY_DISCHARGING" -eq 0 ]; then
    # Battery is charging
    if [ "$BATTERY_LEVEL" -gt 99 ] && [ ! -f "$FULL_FILE" ]; then
        notify-send "Battery Charged" "Battery is fully charged." -i "battery-full-symbolic" -r 9991
        touch "$FULL_FILE"
    fi
    # Reset empty/critical notifications when charging begins
    if [ -f "$EMPTY_FILE" ]; then
        command rm "$EMPTY_FILE"
    fi
    if [ -f "$CRITICAL_FILE" ]; then
        command rm "$CRITICAL_FILE"
    fi
fi
