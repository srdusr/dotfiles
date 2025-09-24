#!/bin/bash

# ======================================
# Basic environment setup
# ======================================

export EDITOR="$(command -v nvim || command -v vim || echo nano)"

# Load zsh env if running zsh
if [ -n "$ZSH_VERSION" ] && [ -f "$HOME/.config/zsh/.zshenv" ]; then
    . "$HOME/.config/zsh/.zshenv"
fi

cd "$HOME" || exit 1

# ======================================
# Session launcher
# ======================================

# Detect graphical DE session
if [ -n "$DISPLAY" ]; then
    #echo "Graphical session detected ($XDG_SESSION_DESKTOP). Skipping auto TTY session launch."
    return
fi

# Only run on first virtual terminal
if [ -z "$XDG_VTNR" ] || [ "$XDG_VTNR" -ne 1 ]; then
    return
fi

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

# Start a session
start_session() {
    local s="$1"
    case "$s" in
        bspwm)
            export XDG_SESSION_TYPE="x11"
            exec startx /usr/bin/bspwm
            ;;
        Hyprland|sway)
            exec dbus-launch --sh-syntax --exit-with-session "$s"
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
    if start_session "$chosen_session"; then
        exit
    else
        echo "Saved session '$chosen_session' not found. Falling back..."
    fi
fi

# Try default sessions in priority
for wm in "${sessions[@]}"; do
    if command -v "$wm" >/dev/null 2>&1; then
        echo "Starting session: $wm"
        start_session "$wm"
        exit
    fi
done

# Fallback: Check for common display managers (GDM/LightDM/SDDM)
for dm in gdm lightdm sddm; do
    if command -v "$dm" >/dev/null 2>&1; then
        echo "Launching display manager: $dm"
        exec "$dm"
    fi
done

echo "No suitable window manager or display manager found."
exit 1
