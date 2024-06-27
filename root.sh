#!/bin/bash

# Define the source base directory
BASE_DIR="$HOME/extras"

# Check if the script is running with superuser privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

# Function to backup existing files
backup_existing() {
  local dest=$1
  if [ -e "$dest" ]; then
    echo "Backing up $dest"
    mv "$dest" "$dest.bak"
  fi
}

# Function to copy directories, backup, and change permissions
copy_and_set_permissions() {
  local src=$1
  local dest=$2

  if [ -d "$src" ]; then
    echo "Processing directory $src"

    for file in "$src"/*; {
      dest_file="$dest/$(basename "$file")"

      backup_existing "$dest_file"

      echo "Copying $file to $dest"
      cp -rp "$file" "$dest"

      echo "Setting permissions for $dest_file"
      chown root:root "$dest_file"
      chmod 644 "$dest_file"
    }
  else
    echo "Source directory $src does not exist."
  fi
}

# Iterate over all directories in the extras directory
for dir in "$BASE_DIR"/*; do
  if [ -d "$dir" ]; then
    dest_dir="/${dir##*/}"
    copy_and_set_permissions "$dir" "$dest_dir"
  fi
done

echo "Files copied and permissions set successfully."
