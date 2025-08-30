#!/bin/bash

# Specify the path to the Rofi configuration file
config_file="$HOME/.config/rofi/styles/appmenu.rasi"

rofi -no-lazy-grab -show drun -display-drun "Applications " -drun-display-format "{name}" -sep -config "$config_file"
