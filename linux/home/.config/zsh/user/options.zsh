## Let FZF use ripgrep by default
#if type rg &> /dev/null; then
#    export FZF_DEFAULT_COMMAND='rg --files'
#    export FZF_DEFAULT_OPTS='-m --height 50% --border'
#fi


# Allow nnn filemanager to cd on quit
nnn() {
    declare -x +g NNN_TMPFILE=$(mktemp --tmpdir $0.XXXX)
    trap "command rm -f $NNN_TMPFILE" EXIT
    =nnn $@
    [ -s $NNN_TMPFILE ] && source $NNN_TMPFILE
}

FUNCNEST=999

# NVM
#nvm() {
#    local green_color
#    green_color=$(tput setaf 2)
#    local reset_color
#    reset_color=$(tput sgr0)
#    echo -e "${green_color}nvm${reset_color} $@"
#}
if [ -s "$NVM_DIR/nvm.sh" ]; then
    nvm_cmds=(nvm node npm yarn)
    for cmd in "${nvm_cmds[@]}"; do
        alias "$cmd"="unalias ${nvm_cmds[*]} && unset nvm_cmds && . $NVM_DIR/nvm.sh && $cmd"
    done
fi

# Kubernetes
# kubernetes aliases
if command -v kubectl > /dev/null; then
    replaceNS() { kubectl config view --minify --flatten --context=$(kubectl config current-context) | yq ".contexts[0].context.namespace=\"$1\"" ; }
    alias kks='KUBECONFIG=<(replaceNS "kube-system") kubectl'
    alias kam='KUBECONFIG=<(replaceNS "authzed-monitoring") kubectl'
    alias kas='KUBECONFIG=<(replaceNS "authzed-system") kubectl'
    alias kar='KUBECONFIG=<(replaceNS "authzed-region") kubectl'
    alias kt='KUBECONFIG=<(replaceNS "tenant") kubectl'

    if command -v kubectl-krew > /dev/null; then
        path=($XDG_CONFIG_HOME/krew/bin $path)
    fi

    rmfinalizers() {
        kubectl get deployment "$1" -o json | jq '.metadata.finalizers = null' | kubectl apply -f -
    }
fi


castero() {
    if [[ -f ~/.local/share/venv/bin/activate ]]; then
        . ~/.local/share/venv/bin/activate
    fi
    command castero "$@"
}

# --- Detect terminal control characters and behavior ---

# Set these to true/false to run on every new tmux/terms
: ${CHECK_ON_TMUX_CHANGES:=false}
: ${CHECK_ON_NEW_INSTANCES:=false}

# Fast terminal fingerprinting for optimizing prompt rendering
function initialize_terminal_fingerprint() {
    # --- Fast terminal fingerprint ---
    TERM_BASIC="$TERM-$COLORTERM"
    TERM_TMUX=""
    [[ "$CHECK_ON_TMUX_CHANGES" == "true" && -n "$TMUX" ]] && TERM_TMUX="-tmux$TMUX_PANE"
    TERM_INSTANCE=""
    [[ "$CHECK_ON_NEW_INSTANCES" == "true" ]] && TERM_INSTANCE="-$$"
    # Combine fingerprint parts only if they're non-empty (faster than function call)
    CURRENT_TERM_FINGERPRINT="${TERM_BASIC}${TERM_TMUX}${TERM_INSTANCE}"
    # Only run detection if terminal has changed (single comparison)
    if [[ "$CURRENT_TERM_FINGERPRINT" != "$LAST_TERM_FINGERPRINT" ]]; then
        export LAST_TERM_FINGERPRINT="$CURRENT_TERM_FINGERPRINT"
        # Fast reset
        export CTRL_C_SIGINT=false
        export CTRL_V_PASTE=false
        # Fast SIGINT check (single command, no pipes)
        INTR_CHAR=$(stty -a 2>/dev/null | sed -n 's/.*intr = \([^;]*\);.*/\1/p' | tr -d ' ')
        [[ "$INTR_CHAR" == "^C" ]] && export CTRL_C_SIGINT=true
        # Check if Ctrl+V is bound to lnext terminal function
        LNEXT_CHAR=$(stty -a 2>/dev/null | sed -n 's/.*lnext = \([^;]*\);.*/\1/p' | tr -d ' ')
        # If lnext is NOT ^V, then Ctrl+V might work as paste
        if [[ "$LNEXT_CHAR" != "^V" ]]; then
            # Check if clipboard tools exist
            if [[ -n "$WAYLAND_DISPLAY" && -x "$(command -v wl-paste)" ]]; then
                export CTRL_V_PASTE=true
            elif [[ -n "$DISPLAY" && -x "$(command -v xclip)" ]]; then
                export CTRL_V_PASTE=true
            fi
        fi
        # Print status only if debug is enabled
        [[ -n "$DEBUG_TERM_DETECT" ]] && echo "Terminal: CTRL_C_SIGINT=$CTRL_C_SIGINT CTRL_V_PASTE=$CTRL_V_PASTE"
    fi
}

# Initialize terminal fingerprint on startup
initialize_terminal_fingerprint

# Register Bun completion
fpath=("$HOME/.bun" $fpath)
