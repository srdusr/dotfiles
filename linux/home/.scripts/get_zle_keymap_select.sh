#!/bin/bash

# Get the value of the zle-keymap-select variable
value=$(print -v zle-keymap-select)

# Specify the file path to save the value
file_path="~/file.txt"

# Write the value to the file
echo "$value" > "$file_path"

# Optionally, you can also print the value to the console
echo "The value of zle-keymap-select is: $value"
