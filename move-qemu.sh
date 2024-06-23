#!/bin/bash

#
#function move_qemu_window {
#    find_window_title() {
#        hyprctl clients | grep -q "QEMU (nixos) - noVNC — Mozilla Firefox"
#    }
#
#    # Function to move the window to workspace 3
#    move_window() {
#        local window_title="$1"
#        if [[ -n $window_title ]]; then
#            hyprctl dispatch movetoworkspace 3,title:"$window_title"
#            echo "Moved window to workspace 3."
#        else
#            echo "Failed to find window title."
#        fi
#    }
#
#    # Function to handle socket input
#    handle_socket() {
#        while read -r line; do
#            case "$line" in
#            *"QEMU (nixos) - noVNC — Mozilla Firefox"*)
#                echo "Socket message received: "$line
#                if find_window_title; then
#                    window_title="^QEMU \(.*\) - noVNC — Mozilla Firefox*"
#                    move_window ""$window_title
#                else
#                    echo "Failed to find window title."
#                fi
#                ;;
#            *)
#                echo "Ignoring socket message: "$line
#                ;;
#            esac
#        done
#    }
#
#    # Wait for the socket and handle messages
#    echo "Waiting for socket messages..."
#    socat - "UNIX-CONNECT:/tmp/hypr/"$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | handle_socket
#}
#
#move_qemu_window

function move_qemu_window {
    find_window_title() {
        hyprctl clients | grep -q "QEMU (nixos) - noVNC — Mozilla Firefox"
    }

    # Function to move the window to workspace 3
    move_window() {
        local window_title="$1"
        if [[ -n $window_title ]]; then
            hyprctl dispatch movetoworkspace 3,title:"$window_title"
            echo "Moved window to workspace 3."
        else
            echo "Failed to find window title."
        fi
    }

    # Wait for the window to appear
    echo "Waiting for window..."
    while true; do
        if find_window_title; then
            window_title="^QEMU \(.*\) - noVNC — Mozilla Firefox*"
            move_window "$window_title"
        fi
        sleep 1 # Check every second
    done
}

move_qemu_window
