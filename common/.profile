#!/bin/bash

export EDITOR="$(command -v nvim || command -v vim || echo nano)"

#if [ "$(tty)" = "/dev/tty1" -a -z "$(printenv HYPRLAND_INSTANCE_SIGNATURE)" ]; then
if [ "$DISPLAY" = "" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec ~/.scripts/env/linux/autorun/session_manager.sh
fi

load_zsh_env() {
  if [ "$ZSH_VERSION" != "" ]; then
    if [ -f ~/.config/zsh/.zshenv ]; then
      . ~/.config/zsh/.zshenv
    fi
  fi
}

load_zsh_env
