# shellcheck shell=bash
#
#██████╗  █████╗ ███████╗██╗  ██╗██████╗  ██████╗
#██╔══██╗██╔══██╗██╔════╝██║  ██║██╔══██╗██╔════╝
#██████╔╝███████║███████╗███████║██████╔╝██║
#██╔══██╗██╔══██║╚════██║██╔══██║██╔══██╗██║
#██████╔╝██║  ██║███████║██║  ██║██║  ██║╚██████╗
#╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝
#
# ~/.bashrc
#

if [[ $- != *i* ]]; then
    . ~/.profile
    return
fi

# Get the current active terminal
term="$(cat /proc/"$PPID"/comm)"

# Set a default prompt
p='\[\033[01;37m\]┌─[\[\033[01;32m\]srdusr\[\033[01;37m\]]-[\[\033[01;36m\]archlinux\[\033[01;37m\]]-[\[\033[01;33m\]\W\]\[\033[00;37m\]\[\033
\[\033[01;37m\]└─[\[\033[05;33m\]$\[\033[00;37m\]\[\033[01;37m\]]\[\033[00;37m\] '

# Set transparency and prompt while using st
if [[ $term = "st" ]]; then
    transset-df "0.65" --id "$WINDOWID" >/dev/null

    #                        [Your_Name]-----|                                |=======|------[Your_Distro]
    #                 [Color]--------|       |                   [Color]------|       |
    #          [Style]------------|  |       |             [Style]---------|  |       |
    #                             V  V       V                             V  V       V
    p='\[\033[01;37m\]┌─[\[\033[01;32m\]srdusr\[\033[01;37m\]]-[\[\033[01;36m\]archlinux\[\033[01;37m\]]-[\[\033[01;33m\]\W\[\033[00;37m\]\[\033[01;37m\]]
\[\033[01;37m\]└─[\[\033[05;33m\]$\[\033[00;37m\]\[\033[01;37m\]]\[\033[00;37m\] '
#                         A  A   A
#              [Style]----|  |   |-------- [Your_Choice]
#         [Color]------------|

fi

# If not running interactively, dont do anything
[[ $- != *i* ]] && return

# My alias commands
alias ls='ls --color=auto -1'
alias shred='shred -uzvn3'
alias wallset='feh --bg-fill'

PS1=$p

bind -m vi-command 'Control-l: clear-screen'
bind -m vi-insert 'Control-l: clear-screen'

export EDITOR="nvim"
# pfetch

#export NVM_DIR="$HOME/.local/share/nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH="/home/srdusr/.local/bin:$PATH"
