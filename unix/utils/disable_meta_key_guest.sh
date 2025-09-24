ain "$@"
#!/usr/bin/env bash

# Function to find the QEMU monitor socket dynamically and extract the VM name
get_socket_path() {
    local socket_dir="$HOME/machines/vm" # Directory where your sockets are stored
    local socket_file=$(find "$socket_dir" -type s -name "*-monitor.socket" | head -n 1)

    echo "[DEBUG] Found socket file: $socket_file" # Debugging line to check the socket file

    if [[ -z "$socket_file" ]]; then
        echo "Error: No QEMU monitor socket found in $socket_dir." >&2
        exit 1
    fi

    # Extract the VM name from the socket file name
    local vm_name=$(basename "$socket_file" -monitor.socket)
    echo "[DEBUG] VM name detected: $vm_name" # Debugging line to check VM name

    echo "$socket_file" # Return the full socket path
    echo "$vm_name"     # Return the VM name
}

# Function to check if sendkeys.awk is in the user's PATH or fall back to specific directories
find_sendkeys_awk() {
    # Check if sendkeys.awk is in the user's PATH
    if command -v sendkeys.awk &>/dev/null; then
        echo "$(command -v sendkeys.awk)"
        return 0
    fi

    # Otherwise, check in specific fallback directories
    local possible_paths=(
        "$HOME/.scripts/env/linux/utils/sendkeys.awk"
        "$HOME/.scripts/sendkeys.awk"
    )

    for path in "${possible_paths[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done

    echo "sendkeys.awk not found in the user's PATH or known directories." >&2
    exit 1
}

send_guest_command() {
    local cmd="$1"
    local socket="$2"
    echo "$cmd" | awk -f "$SENDKEYS_AWK" | socat - UNIX-CONNECT:"$socket"
}

main() {
    # Get the QEMU socket and VM name dynamically
    SOCKET=$(get_socket_path)
    VM_NAME=$(basename "$SOCKET" -monitor.socket)

    # Debugging output to verify the socket and VM name
    echo "[DEBUG] Using socket: $SOCKET"
    echo "[DEBUG] VM name: $VM_NAME"

    # If no socket file is found, exit
    if [[ ! -S "$SOCKET" ]]; then
        echo "Error: QEMU monitor socket for $VM_NAME does not exist or is not available."
        exit 1
    fi

    # Try to find the sendkeys.awk file
    SENDKEYS_AWK=$(find_sendkeys_awk)

    echo "[*] Attempting Caps Lock to Super remapping on all known platforms..."

    # === X11 ===
    send_guest_command "setxkbmap -option caps:super" "$SOCKET"
    send_guest_command "xmodmap -e 'remove Mod4 = Super_L Super_R'" "$SOCKET"
    send_guest_command "xmodmap -e 'keycode 133 = NoSymbol'" "$SOCKET"
    send_guest_command "xmodmap -e 'keycode 134 = NoSymbol'" "$SOCKET"

    # === Wayland (note: this just gives a reminder) ===
    send_guest_command "gsettings set org.gnome.desktop.input-sources xkb-options \"['caps:super']\"" "$SOCKET"
    send_guest_command "echo 'Wayland? Try remapping via wlroots/wlr-keyboard'" "$SOCKET"

    # === Windows (registry scancode map) ===
    send_guest_command "powershell -Command \"Set-ItemProperty -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Keyboard Layout' -Name 'Scancode Map' -Value ([byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x00,0x3A,0x00,0x5B,0x00,0x00,0x00))\"" "$SOCKET"

    # === macOS (hidutil remap) ===
    send_guest_command "hidutil property --set '{\"UserKeyMapping\":[{\"HIDKeyboardModifierMappingSrc\":0x700000039,\"HIDKeyboardModifierMappingDst\":0x7000000E3}]}'" "$SOCKET"

    echo "[*] Done sending remapping commands to guest."
}

main "$@"
