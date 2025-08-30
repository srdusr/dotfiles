#!/bin/bash

# Created By: srdusr
# Created On: Mon 18 Sep 2023 18:37:21 CAT
# Project: Bspwm script to toggle visibility of initial window and bring focus back to it

# Get the ID of the currently focused desktop
current_desktop_id=$(bspc query -D -d focused --names)

# Get the ID of the first hidden window in the current desktop
hidden_window_id=$(bspc query -N -d "$current_desktop_id" -n .hidden | head -n 1)

# Check if there's a hidden window in the current desktop
if [[ -n "$hidden_window_id" ]]; then
    # There's a hidden window, so unhide it
    bspc node "$hidden_window_id" -g hidden=off
    # Bring focus back to the previously hidden window
    bspc node -f "$hidden_window_id"
else
    # There's no hidden window in the current desktop, hide the first available window
    first_window_id=$(bspc query -N -n focused.window)
    bspc node "$first_window_id" -g hidden=on
fi
