#!/bin/bash

#if [ "$(tty)" = "/dev/tty1" -a -z "$(printenv HYPRLAND_INSTANCE_SIGNATURE)" ]; then
if [ "$DISPLAY" = "" ] && [ "$XDG_VTNR" -eq 1 ]; then
    exec ~/.scripts/session_manager.sh
fi

load_zsh_env() {
    if [ "$ZSH_VERSION" != "" ]; then
        if [ -f ~/.config/zsh/.zshenv ]; then
            . ~/.config/zsh/.zshenv
        fi
    fi
}

load_zsh_env
