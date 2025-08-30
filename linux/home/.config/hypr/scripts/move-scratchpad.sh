#!/bin/bash

# Number of pixels to move down
pixels_to_move=10

# Get the PID of each scratchpad window and move it down
for pid in "$(hyprctl -j clients | jq -r '.[] | select(.class == "scratchpad") | .pid')"; do
    hyprctl dispatch movewindowpixel 0 "$pixels_to_move",pid:"$pid"
done
