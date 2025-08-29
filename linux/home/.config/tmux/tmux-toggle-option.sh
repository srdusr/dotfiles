#!/usr/bin/bash

#USAGE="USAGE: $0 OPTION_NAME ON_STATE OFF_STATE"

#OPTION_NAME=$1
#ON_STATE=$2
#OFF_STATE=$3
#
#if [[ "$#" != 3 ]]; then
#  echo $USAGE
#  exit 1
#fi
#
#if [[ `tmux show-option -w | grep "$OPTION_NAME $ON_STATE"` ]]; then
#  OPTION_VALUE=$OFF_STATE
#else
#  OPTION_VALUE=$ON_STATE
#fi
#
#tmux display-message "monitor activity: $OPTION_NAME $OPTION_VALUE"
#tmux set-option -w $OPTION_NAME $OPTION_VALUE > /dev/null

if [ $(tmux show-option -A status-left) != 'status-left* "#[fg=#50fa7b,bg=default] #[bg=#50fa7b,fg=black]❐ #S #[fg=#50fa7b,bg=default]"' ]; then
  tmux set -g status-left "#[fg=#50fa7b,bg=default] #[bg=#50fa7b,fg=black]❐ #S #[fg=#50fa7b,bg=default] ";
else
  tmux set -g status-left "#[fg=#50fa7b,bg=default]#[bg=#50fa7b,fg=black] ❐ #S #( ~/.config/tmux/left-status.sh ) #[fg=#50fa7b,bg=default]" && tmux set -g status-right "#[fg=#50fa7b,bg=default] #{?client_prefix,#[reverse] Prefix #[noreverse] ,}#[bg=default,fg=#50fa7b]#[bg=#50fa7b,fg=black] #( ~/.config/tmux/right-status.sh ) %d-%b-%y | %H:%M #[bg=default,fg=#50fa7b]";
fi
