#!/bin/sh
#
#░█▀▀░▀█▀░█▀█░█▀▄░▀█▀░█░█
#░▀▀█░░█░░█▀█░█▀▄░░█░░▄▀▄
#░▀▀▀░░▀░░▀░▀░▀░▀░░▀░░▀░▀
#

# xinitrc.d
if [ -d /etc/X11/xinit/xinitrc.d ]; then
    for f in /etc/X11/xinit/xinitrc.d/*; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

# Keyboard layout
setxkbmap -model pc105 -layout us -variant qwerty

# xinitrc runs automatically when you run startx.

# There are some small but important commands that need to be run when we start
# the graphical environment. There is a link to this file in ~/.xprofile
# because that file is run automatically if someone uses a display manager
# (login screen) and so they are needed there. To prevent doubling up commands,
# I source them here with the line below.

# Profile
[[ -f /etc/profile ]] && source /etc/profile

if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/X11/.xprofile" ]; then
    . "${XDG_CONFIG_HOME:-$HOME/.config}/X11/.xprofile"
else
    . "$HOME/.xprofile"
fi
