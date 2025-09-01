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

bindkey '^[[D' backward-char   # Left arrow
bindkey '^[[C' forward-char    # Right arrow
bindkey '^[D' backward-char   # Left arrow
bindkey '^[C' forward-char    # Right arrow
bindkey '[C' forward-word
bindkey '[D' backward-word
bindkey -M viins '^[[D' backward-char   # Left arrow
bindkey -M viins '^[[C' forward-char    # Right arrow

bindkey -M vicmd '^[[D' backward-char   # Left arrow
bindkey -M vicmd '^[[C' forward-char    # Right arrow

# Define the 'autosuggest-execute' and 'autosuggest-accept' ZLE widgets
autoload -Uz autosuggest-execute autosuggest-accept
zle -N autosuggest-execute
zle -N autosuggest-accept
bindkey '^X' autosuggest-execute
bindkey '^Y' autosuggest-accept
bindkey '\M-l' accept-and-complete-next-history

# Edit line in vim with alt-e
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line
bindkey '^[e' edit-command-line # alt + e

# Allow CTRL+D to exit zsh with partial command line (non empty line)
exit_zsh() { exit }
zle -N exit_zsh
bindkey '^D' exit_zsh

# Copy/Paste
# Safe clipboard copy
smart_copy() {
    local text="${LBUFFER}${RBUFFER}"

    # Prefer Wayland, fallback to X11, then others
    if command -v wl-copy >/dev/null 2>&1 && [[ "$WAYLAND_DISPLAY" || "$XDG_SESSION_TYPE" == "wayland" ]]; then
        echo -n "$text" | wl-copy --foreground --type text/plain 2>/dev/null || true
    elif command -v xclip >/dev/null 2>&1 && [[ "$DISPLAY" || "$XDG_SESSION_TYPE" == "x11" || "$XDG_SESSION_TYPE" == "x11-xwayland" ]]; then
        echo -n "$text" | xclip -selection clipboard 2>/dev/null || true
    elif [[ "$(uname -s)" == "Darwin" ]] && command -v pbcopy >/dev/null 2>&1; then
        echo -n "$text" | pbcopy 2>/dev/null || true
    elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        echo -n "$text" | clip.exe 2>/dev/null || true
    else
        echo "smart_copy: No supported clipboard utility found." >&2
    fi
}

# Safe clipboard paste
smart_paste() {
    local clip=""
    if command -v wl-paste >/dev/null 2>&1 && [[ "$WAYLAND_DISPLAY" || "$XDG_SESSION_TYPE" == "wayland" ]]; then
        clip=$(wl-paste --no-newline 2>/dev/null)
    elif command -v xclip >/dev/null 2>&1 && [[ "$DISPLAY" || "$XDG_SESSION_TYPE" == "x11" || "$XDG_SESSION_TYPE" == "x11-xwayland" ]]; then
        clip=$(xclip -selection clipboard -o 2>/dev/null)
    elif [[ "$(uname -s)" == "Darwin" ]] && command -v pbpaste >/dev/null 2>&1; then
        clip=$(pbpaste 2>/dev/null)
    elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        clip=$(powershell.exe -Command 'Get-Clipboard -Raw' 2>/dev/null | tr -d '\r')
    else
        echo "smart_paste: No supported clipboard utility found." >&2
    fi

    LBUFFER+="$clip"
    zle reset-prompt
}

# Register widgets
zle -N smart_copy
zle -N smart_paste

# Bind keys (optional: choose your preferred)
bindkey '^V' smart_paste
bindkey -M viins '^V' smart_paste
bindkey -M vicmd '^V' smart_paste
bindkey -M vicmd 'p' smart_paste

bindkey '^Y' smart_copy
bindkey -M viins '^Y' smart_copy
bindkey -M vicmd '^Y' smart_copy
bindkey -M vicmd 'y' smart_copy

# In vi mode, map Alt-H and Alt-L
#bindkey -M viins "^[u" go_up   # Alt-H to go up
#bindkey -M viins "^[o" go_into  # Alt-L to go into a directory


# Newline and clear
function newline_clear() {
    printf "\n"
    command clear
}

zle -N newline_clear

no_tmux_clear() {
    zle clear-screen
}
zle -N no_tmux_clear

# Newline before clear
if [[ -n "$TMUX" ]]; then
    # Bind Ctrl-L to send newline and clear screen
    bindkey '^L' newline_clear
else
    bindkey '^L' no_tmux_clear
fi

# use ctrl-z to toggle in and out of bg
function toggle_fg_bg() {
    if [[ $#BUFFER -eq 0 ]]; then
        BUFFER="fg"
        zle accept-line
    else
        BUFFER=""
        zle clear-screen
    fi
}
zle -N toggle_fg_bg
bindkey '^Z' toggle_fg_bg




## Custom key bindings to control history behavior
#bindkey -M vicmd '^[[C' vi-forward-char      # Right arrow in normal mode - just move cursor
#bindkey -M vicmd '^[[D' vi-backward-char     # Left arrow in normal mode - just move cursor
#bindkey -M vicmd '^A' beginning-of-line      # Ctrl-A - go to beginning of line
#bindkey -M vicmd '^E' end-of-line            # Ctrl-E - go to end of line

# Disable automatic suggestion accept on right arrow in normal mode

## Additional vi-mode key bindings to prevent unwanted history completion
## Disable automatic history completion in normal mode
#bindkey -M vicmd '^[[C' vi-forward-char      # Right arrow - just move right, don't complete
#bindkey -M vicmd '^[[D' vi-backward-char     # Left arrow - just move left
