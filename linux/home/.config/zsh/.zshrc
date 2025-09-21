#  ███████╗███████╗██╗  ██╗██████╗  ██████╗
#  ╚══███╔╝██╔════╝██║  ██║██╔══██╗██╔════╝
#    ███╔╝ ███████╗███████║██████╔╝██║
#   ███╔╝  ╚════██║██╔══██║██╔══██╗██║
#  ███████╗███████║██║  ██║██║  ██║╚██████╗
#  ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝

# Profile zsh time
#zmodload zsh/zprof



# If not running interactively, don't do anything
#[[ $- != *i* ]] && return
# If not running interactively, and not being sourced, don’t do anything
[[ $- != *i* ]] && [[ "${BASH_SOURCE[0]:-${(%):-%N}}" == "$0" ]] && return

# Terminal key bindings
#stty intr '^q' # Free Ctrl+C for copy use Ctrl+Q instead for Interrupt
stty lnext '^-' # Free Ctrl+V for paste use Ctrl+- instead for Literal next
stty stop undef # Disable Ctrl+S to freeze terminal
stty start undef # Disable Ctrl+Q nfreeze terminal

# Set the current prompt file (e.g., prompt, or prompt_minimal)
ZSH_PROMPT="${ZSH_PROMPT:-prompt}"
#ZSH_PROMPT="${ZSH_PROMPT:-prompt_minimal}"
#ZSH_PROMPT="${ZSH_PROMPT:-prompt_new}"
#ZSH_PROMPT="${ZSH_PROMPT:-prompt_simple}"

# Source common Zsh files (excluding any that start with 'prompt')
ZSH_SOURCES=()

for zsh_source in "$HOME"/.config/zsh/user/*.zsh; do
    if [[ $(basename "$zsh_source") == prompt* && $(basename "$zsh_source" .zsh) != "$ZSH_PROMPT" ]]; then
        continue
    fi
    ZSH_SOURCES+=("$zsh_source")
done

# Faster SSH
if [[ -n "$SSH_CLIENT" ]]; then
    export KEYTIMEOUT=10
else
    export KEYTIMEOUT=15
fi

# Prevent non-login shell anomalies or toolchain misidentification in VS Code
#[[ "$TERM_PROGRAM" == "vscode" ]] && unset ARGV0
#[[ -n "$TERM_PROGRAM" && "$TERM_PROGRAM" == "vscode" ]] && unset ARGV0
if [[ "${TERM_PROGRAM:-}" == "vscode" ]]; then
  unset ARGV0
fi

# Tmux default session
#if [ "$TERM_PROGRAM" != "vscode" ] && command -v tmux &> /dev/null && [ -n "$PS1" ] && [ -n "$DISPLAY" ] && [ -z "$TMUX" ]; then
#    if ! tmux list-sessions | grep -q '^tmux:'; then
#        tmux new -s tmux
#    fi
#fi

# Enable various options for Zsh behavior
setopt interactive_comments      # Allow comments to appear in interactive mode
unsetopt BEEP                    # Disable the system beep (to prevent annoying beeps)
setopt extendedglob              # Enable extended globbing for complex pattern matching
setopt nomatch                   # Prevent errors when a glob pattern doesn't match any files
setopt notify                    # Notify when background jobs complete
setopt completeinword            # Allow tab completion within words
setopt prompt_subst              # Allow prompt variables to be substituted

# Enable automatic directory navigation
setopt autocd                    # Automatically change to a directory if the directory name is typed alone
setopt AUTO_PUSHD                # Save more directory history, and use "cd -" with tab completion

# Optional: Uncomment to disable waiting dots on completion
# COMPLETION_WAITING_DOTS="false"

# Hide history of commands starting with a space
setopt histignorespace           # Do not save commands that start with a space in the history

# Source ZSH files
for zsh_source in "${ZSH_SOURCES[@]}"; do
    source "$zsh_source"
done

##########    Source Plugins, should be last    ##########
#source /usr/share/nvm/init-nvm.sh

# Load fzf keybindings and completion if fzf is installed
if command -v fzf >/dev/null 2>&1; then
    FZF_BASE="/usr/local/bin/fzf/shell"
    [[ -f "${FZF_BASE}/key-bindings.zsh" ]] && source "${FZF_BASE}/key-bindings.zsh"
    [[ -f "${FZF_BASE}/completion.zsh" ]] && source "${FZF_BASE}/completion.zsh"
fi


# Source plugins
for plugin in \
  "$HOME/.config/zsh/plugins/zsh-you-should-use/you-should-use.plugin.zsh" \
  "$HOME/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "$HOME/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" \
  "$HOME/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
do
  [ -f "$plugin" ] && source "$plugin"
done

DISABLE_MAGIC_FUNCTIONS=true

# Zoxide (cd alternative)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# Profile zsh time
#zprof              # At the end of .zshrc
