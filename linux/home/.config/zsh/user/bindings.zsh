##########    Vi mode    ##########
bindkey -v
#bindkey -M viins '^?' backward-delete-char
#local WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'
backward-kill-dir () {
    local WORDCHARS=${WORDCHARS/\/}
    zle backward-kill-word
    zle -f kill
}
zle -N backward-kill-dir
bindkey '^[^?' backward-kill-dir
bindkey "^W" backward-kill-dir
bindkey -M viins '^[[3~'  delete-char
bindkey -M vicmd '^[[3~'  delete-char
bindkey -v '^?' backward-delete-char
bindkey -r '\e/'
bindkey -s jk '\e'
#bindkey "^W" backward-kill-word
bindkey "^H" backward-delete-char      # Control-h also deletes the previous char
bindkey "^U" backward-kill-line
bindkey "^[j" history-search-forward # or you can bind it to the down key "^[[B"
bindkey "^[k" history-search-backward # or you can bind it to Up key "^[[A"

# Define the 'autosuggest-execute' and 'autosuggest-accept' ZLE widgets
autoload -Uz autosuggest-execute autosuggest-accept
zle -N autosuggest-execute
zle -N autosuggest-accept
bindkey '^X' autosuggest-execute
bindkey '^Y' autosuggest-accept

# Edit line in vim with alt-e
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line
bindkey '^[e' edit-command-line # alt + e

# Allow CTRL+D to exit zsh with partial command line (non empty line)
exit_zsh() { exit }
zle -N exit_zsh
bindkey '^D' exit_zsh
