#!/bin/sh

# fzf session name
FZF_SESSION_NAME="fzf"

# Print error messages
error() {
    echo "Error: $1" >&2
}

# Check if tmux is installed
if ! command -v tmux >/dev/null 2>&1; then
    error "tmux is not installed."
    exit 1
fi

# Function to handle file or directory opening
open_selected_item() {
    # Use fzf to select a file from the specified directory
    SELECTED_FILE=$(find ~ -type f | fzf --preview "bat --style=numbers --color=always --line-range=:500 {}" \
        --preview-window=up:60% --height=90% --layout=reverse --border=sharp --ansi)

    if [ "$SELECTED_FILE" != "" ]; then
        # Ask whether to open the file or its directory
        read -p "Open file (f) or directory (d)? " choice
        case "$choice" in
        f | F)
            # Open the selected file in nvim
            nvim "$SELECTED_FILE"
            ;;
        d | D)
            # Change to the directory containing the selected file
            cd "$(dirname "$SELECTED_FILE")"
            ;;
        *)
            echo "Invalid choice. Please enter 'f' for file or 'd' for directory."
            ;;
        esac
    else
        echo "No file selected."
    fi
}

# Check if the fzf session exists
if tmux has-session -t "$FZF_SESSION_NAME" 2>/dev/null; then
    # Get the current tmux session name
    CURRENT_SESSION=$(tmux display-message -p '#S')

    # If currently in the fzf session, detach; otherwise, attach to it
    if [ "$CURRENT_SESSION" = "$FZF_SESSION_NAME" ]; then
        tmux detach-client
    else
        tmux set -gF '@last_session_name' '#S' # Store the current session name
        tmux display-popup -E -x200% -y0 -w50% -h99% "tmux attach-session -t $FZF_SESSION_NAME"
    fi
else
    # If the fzf session doesn't exist, create it and run file selection logic in a popup
    tmux set -gF '@last_session_name' '#S' # Store the current session name
    tmux display-popup -E -w100% -h100% -y0 -x0 "tmux new-session -A -s fzf '$0 open_selected_item'"
fi
