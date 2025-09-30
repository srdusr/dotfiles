#!/bin/bash
# ======================================
# Session launcher
# ======================================

start_session() {
    # Clean environment
    unset DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS

    # Priority-ordered list of sessions (WM/DE)
    sessions=(
        "Hyprland"
        "bspwm"
        "sway"
        "gnome-session"
        "startplasma-x11"
        "startxfce4"
        "openbox"
        "i3"
    )

    # Handle saved session
    if [ -f "$HOME/.session" ]; then
        chosen_session=$(<"$HOME/.session")
        rm -f "$HOME/.session"
    fi

    launch_session() {
        local s="$1"
        case "$s" in
            bspwm)
                export XDG_SESSION_TYPE="x11"
                exec startx /usr/bin/bspwm
                ;;
            Hyprland|sway)
                exec dbus-launch --sh-syntax --exit-with-session "$s" >/dev/null 2>&1
                ;;
            gnome-session|startplasma-x11|startxfce4|openbox|i3)
                exec "$s"
                ;;
            *)
                return 1
                ;;
        esac
    }

    # Try saved session first
    if [ -n "$chosen_session" ]; then
        if launch_session "$chosen_session"; then
            exit
        else
            echo "Saved session '$chosen_session' not found. Falling back..."
        fi
    fi

    # Try default sessions in priority
    for wm in "${sessions[@]}"; do
        if command -v "$wm" >/dev/null 2>&1; then
            echo "Starting session: $wm"
            launch_session "$wm"
            exit
        fi
    done

    # Fallback: Check for common display managers
    for dm in gdm lightdm sddm; do
        if command -v "$dm" >/dev/null 2>&1; then
            echo "Launching display manager: $dm"
            exec "$dm"
        fi
    done

    echo "No suitable window manager or display manager found."
    exit 1
}

# -------------------------
# Only run session loader when:
# - No DISPLAY (not inside an existing GUI)
# - On first VT (tty1)
# -------------------------
if [ -z "$DISPLAY" ] && [ -n "$XDG_VTNR" ] && [ "$XDG_VTNR" -eq 1 ]; then
    start_session
fi
