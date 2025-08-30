#!/bin/bash

# Set the bare dotfiles repo directory
dotfiles_dir="$HOME/.cfg"

# Set the home directory
home_dir="$HOME"

# Exclude the .cfg directory and any other files/directories you want to ignore
exclude_list=(".cfg")

# Change to the home directory
cd "$home_dir"

# Get a list of all dotfiles in the repository
files=$(find "$dotfiles_dir" -maxdepth 1 -type f -not -name ".*" -not -name "${exclude_list[*]}" -printf "%f\n")

# Link each file to its corresponding location in $HOME
for file in $files; do
  ln -sf "$dotfiles_dir/$file" "$home_dir/.$file"
done

# Get a list of all dot directories in the repository
dirs=$(find "$dotfiles_dir" -maxdepth 1 -type d -not -path "$dotfiles_dir" -not -name ".*" -not -name "${exclude_list[*]}" -printf "%f\n")

# Link each directory to its corresponding location in $HOME
for dir in $dirs; do
  ln -sf "$dotfiles_dir/$dir" "$home_dir/.$dir"
done

# Remove any symlinks that are no longer present in the repo
while IFS= read -r -d '' link; do
  if [[ ! -e "$link" ]]; then
    rm "$link"
  fi
done < <(find "$home_dir" -maxdepth 1 -type l -name ".*" -not -name ".cfg" -print0)

