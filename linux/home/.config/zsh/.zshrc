
#  ███████╗███████╗██╗  ██╗██████╗  ██████╗
#  ╚══███╔╝██╔════╝██║  ██║██╔══██╗██╔════╝
#    ███╔╝ ███████╗███████║██████╔╝██║
#   ███╔╝  ╚════██║██╔══██║██╔══██╗██║
#  ███████╗███████║██║  ██║██║  ██║╚██████╗
#  ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝

for zsh_source in "$HOME"/.config/zsh/user/*.zsh; do
    source $zsh_source
done

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

if [[ -n "$SSH_CLIENT" ]]; then
    export KEYTIMEOUT=10
else
    export KEYTIMEOUT=15
fi

# Tmux default session
if command -v tmux &> /dev/null && [ -n "$PS1" ] && [ -z "$DISPLAY" ] && [ -z "$TMUX" ]; then
    if ! tmux list-sessions | grep -q '^tmux:'; then
        tmux new -s tmux
    fi
fi

# Enable various options
setopt interactive_comments beep extendedglob nomatch notify completeinword prompt_subst

# Some other useful functionalities
setopt autocd # Automatically cd into typed directory.
setopt AUTO_PUSHD   # More history for cd and use "cd -TAB"
stty intr '^q' # free Ctrl+C for copy use Ctrl+q instead
stty lnext '^-' # free Ctrl+V for paste use ^- instead
stty stop undef # Disable ctrl-s to freeze terminal.
stty start undef
#COMPLETION_WAITING_DOTS="false"
#unsetopt BEEP

##########    Source Plugins, should be last    ##########
#source /usr/share/nvm/init-nvm.sh

# Load fzf keybindings and completion if fzf is installed
if command -v fzf > /dev/null 2>&1; then
    #FZF_BASE="/usr/share/fzf"
    FZF_BASE="/usr/local/bin/fzf/shell"
    source "${FZF_BASE}/key-bindings.zsh"
    source "${FZF_BASE}/completion.zsh"
else
    echo "fzf not found, please install it to use fzf keybindings and completion."
fi

# Suggest aliases for commands
source ~/.config/zsh/plugins/zsh-you-should-use/you-should-use.plugin.zsh

# Load zsh-syntax-highlighting
source ~/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Load fish like auto suggestions
source ~/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
source ~/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
