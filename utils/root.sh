#!/bin/bash

# Created By: srdusr
# Created On: Mon 19 Feb 2025 14:18:00 PM CAT
# Project: Backup and restore system files to/from home extras (system dotfiles) directory

# Dependencies: None
# NOTE: The backups will be stored in the ~/extras directory, preserving the original file structure. Run as sudo or be prompted for password
# Example usage:
#       To backup a specific file: root.sh --backup /some_directory/some_file.conf
#       To restore a specific file: root.sh --restore ~/extras/some_directory/some_file.conf
#       To restore all files: root.sh --restore
#

# Use $SUDO_USER to get the original user when run with sudo, or fall back to the current user if not
BASE_DIR="/home/${SUDO_USER:-$(whoami)}/extras"

if [ "$EUID" -eq 0 ] && [ "$SUDO_USER" = "" ]; then
    echo "You are running this script directly as root, not through sudo!"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Elevating to sudo..."
    exec sudo "$0" "$@" # Re-run the script with sudo
fi

# Create directories if they do not exist
create_directory() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    else
        echo "Directory already exists: $dir"
    fi
}

# Backup files
backup_to_extras() {
    local src=$1

    # Ensure the file or directory exists
    if [ -e "$src" ]; then
        # Strip the leading / from src to avoid double slashes
        local stripped_src="${src#/}"

        # Determine the destination path
        dest_dir="$BASE_DIR/$(dirname "$stripped_src")" # Get the directory part of the source
        dest_file="$BASE_DIR/$stripped_src"             # Get the full destination file path

        # Debug: Print paths
        echo "Source file: $src"
        echo "Destination directory: $dest_dir"
        echo "Destination file: $dest_file"

        # Create the necessary directories in extras if they don't exist
        create_directory "$dest_dir"

        # Backup the file to extras
        echo "Backing up $src to $dest_file"
        cp -p "$src" "$dest_file"

        # Set permission to user
        chown "$SUDO_USER:$SUDO_USER" "$dest_file"

        echo "Backup of $src completed."
    else
        echo "Error: The file or directory '$src' does not exist."
    fi
}

# Restore files
restore_from_extras() {
    local src=$1

    # Ensure the file or directory exists in extras
    if [ -e "$src" ]; then
        # Strip the leading / from src to avoid double slashes
        local stripped_src="${src#/}"

        # Determine the destination path
        dest_dir="/$(dirname "$stripped_src")" # Get the directory part of the source
        dest_file="/$stripped_src"             # Get the full destination file path

        # Debug: Print paths
        echo "Source file: $src"
        echo "Destination directory: $dest_dir"
        echo "Destination file: $dest_file"

        # Create the necessary directories in the system if they don't exist
        create_directory "$dest_dir"

        # Backup the file if it exists before restoring
        if [ -e "$dest_file" ]; then
            echo "File $dest_file exists, creating a backup..."
            mv "$dest_file" "$dest_file.bak"
            echo "Backup created at $dest_file.bak"
        fi

        # Restore the file from extras
        echo "Restoring $src to $dest_file"
        cp -p "$BASE_DIR/$stripped_src" "$dest_file"

        # Set permissions for the restored file
        chmod 644 "$dest_file"

        echo "Restore of $src completed."
    else
        echo "Error: The file or directory '$src' does not exist in extras."
    fi
}

# Restore all files from extras
restore_all_from_extras() {
    echo "Restoring all files and directories from extras..."

    # Loop over all files and directories in BASE_DIR and restore them
    find "$BASE_DIR" -type f | while read -r file; do
        restore_from_extras "$file"
    done

    echo "Restore completed."
}

# Backup system files based on user input
if [ "$1" == "--backup" ]; then
    if [ "$2" = "" ]; then
        echo "Error: Please specify the file or directory to backup."
        exit 1
    fi

    # Perform the backup
    echo "Backing up system files to extras..."
    backup_to_extras "$2"
    echo "Backup completed."

    # Restore system files based on user input
elif [ "$1" == "--restore" ]; then
    if [ "$2" = "" ]; then
        # If no specific file is provided, restore everything
        restore_all_from_extras
    else
        # Restore a specific file or directory
        echo "Restoring system files from extras..."
        restore_from_extras "$2"
        echo "Restore completed."
    fi

else
    echo "Invalid option. Use '--backup' to backup or '--restore' to restore."
fi
