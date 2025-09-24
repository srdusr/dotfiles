#!/bin/bash

# Host-side script to keep QEMU guest display awake without triggering anything
# and handle Windows key logic (disable it in the guest, map Caps Lock to Windows key).

MONITOR_SOCKET_DIR="$HOME/machines/vm"
QEMU_CLASS="qemu-system-x86_64"
SEND_CMD_MONITOR="sendkey f15"
SEND_CMD_XDO="key --clearmodifiers F15"
DISABLE_WINDOWS_KEY_CMD="sendkey meta_l NoSymbol" # Using ctrl_l as a placeholder
CAPS_LOCK_CMD="sendkey meta_l"                    # Remapped Caps Lock to Super_L (Windows key)

## Function to disable the Windows key and remap Caps Lock to Super_L
#disable_windows_key_and_remap_caps_lock() {
#    shopt -s nullglob
#    sockets=("$MONITOR_SOCKET_DIR"/*.socket)
#    shopt -u nullglob
#
#    for socket in "${sockets[@]}"; do
#        # Get VM name from socket file
#        VM_NAME=$(basename "$socket" .socket)
#        VM_NAME=${VM_NAME%-serial}
#
#        # Send QMP command to disable Windows key (Super_L key press/remap)
#        qmp_command='{"execute": "device_key_press", "arguments": {"dev": "virtio-keyboard-pci", "key": "capslock"}}'
#        echo "$qmp_command" | socat - "UNIX-CONNECT:$socket" >/dev/null
#
#        # Send QMP command to remap Caps Lock to Super_L (Windows key)
#        qmp_command='{"execute": "guest-execute", "arguments": {"path": "/usr/bin/xmodmap", "arg": ["-e", "keycode 66 = Super_L"]}}'
#        echo "$qmp_command" | socat - "UNIX-CONNECT:$socket" >/dev/null
#
#        # Optional: Disable Super_L key (Windows key)
#        qmp_command='{"execute": "guest-execute", "arguments": {"path": "/usr/bin/xmodmap", "arg": ["-e", "keycode 133 = NoSymbol"]}}'
#        echo "$qmp_command" | socat - "UNIX-CONNECT:$socket" >/dev/null
#    done
#}

# Function to keep the guest display awake by sending F15 key press
keep_guest_display_awake() {
    shopt -s nullglob
    sockets=("$MONITOR_SOCKET_DIR"/*.socket)
    shopt -u nullglob

    if [ ${#sockets[@]} -eq 0 ]; then
        sleep 30
        return
    fi

    focused_qemu=false

    if command -v xdotool >/dev/null 2>&1; then
        active_win_id=$(xdotool getwindowfocus 2>/dev/null)
        if [ "$active_win_id" != "" ]; then
            active_class=$(xdotool getwindowclassname "$active_win_id" 2>/dev/null)
            if [[ "$active_class" == "$QEMU_CLASS" ]]; then
                focused_qemu=true
            fi
        fi
    fi

    if "$focused_qemu"; then
        # QEMU is focused → send F15 via xdotool
        #xdotool "$SEND_CMD_XDO"
        echo ""

    else
        # QEMU is not focused → send F15 via monitor
        for socket in "${sockets[@]}"; do
            echo "$SEND_CMD_MONITOR" | socat - "UNIX-CONNECT:$socket"
        done
    fi
}

# Main loop
while true; do
    # Handle Windows key remapping and Caps Lock disablement
    #disable_windows_key_and_remap_caps_lock

    # Keep the guest display awake
    keep_guest_display_awake

    # Sleep before next cycle
    sleep 30
done
