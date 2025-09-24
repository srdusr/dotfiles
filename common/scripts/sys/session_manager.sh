#!/bin/sh

cd ~

# Default session to be executed
unset DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS

session=""

# Function to display and start the selected session
display() {
    # Default list of sessions in priority order
    default_sessions=("Hyprland" "bspwm" "sway")

    # Check conditions and set session command
    if [ "$DISPLAY" = "" ] && [ "$XDG_VTNR" -eq 1 ]; then
        if [ -f ~/.session ]; then
            session=$(cat ~/.session)
            rm ~/.session  # Remove the session file after reading
        fi

        if [ "$session" != "" ]; then
            case "$session" in
                bspwm )
                    export XDG_SESSION_TYPE="x11"
                    session="startx /usr/bin/bspwm"
                    ;;
                Hyprland | sway)
                    session="dbus-launch --sh-syntax --exit-with-session $session"
                    ;;
                *)
                    echo "Session $session is not supported."
                    session=""
                    ;;
            esac
        else
            # Iterate through default sessions to find a suitable one
            for wm in "${default_sessions[@]}"; do
                if command -v "$wm" >/dev/null 2>&1; then
                    case "$wm" in
                        bspwm )
                            export XDG_SESSION_TYPE="x11"
                            session="startx /usr/bin/$wm"
                            break
                            ;;
                        Hyprland | sway)
                            session="dbus-launch --sh-syntax --exit-with-session $wm >/dev/null 2>&1 && exit"
                            #show_animation.sh
                            clear
                            break
                            ;;
                    esac
                fi
            done
        fi

        # Execute the session command if session is set
        if [ "$session" != "" ]; then
            #echo "Starting session: $session"
            eval "$session"
        else
            echo "No suitable window manager found or conditions not met."
        fi
    fi
}

# Main function
main() {
    display
}

main "$@"
