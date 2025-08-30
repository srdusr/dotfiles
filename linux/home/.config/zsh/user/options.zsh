
# Let FZF use ripgrep by default
if type rg &> /dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files'
    export FZF_DEFAULT_OPTS='-m --height 50% --border'
fi


# Allow nnn filemanager to cd on quit
nnn() {
    declare -x +g NNN_TMPFILE=$(mktemp --tmpdir $0.XXXX)
    trap "rm -f $NNN_TMPFILE" EXIT
    =nnn $@
    [ -s $NNN_TMPFILE ] && source $NNN_TMPFILE
}


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
