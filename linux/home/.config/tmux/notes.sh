#!/usr/bin/env bash

# Notes/TODO management & quick search engine via tmux

NOTES_DIR="$HOME/documents/main"
TODO_FILE="$NOTES_DIR/inbox/tasks/TODO.md"
EDITOR="nvim"
NOTE_SESSION_NAME="note"
BROWSER_PREFERENCES=("firefox" "chromium" "google-chrome" "brave-browser" "chrome")
SEARCH_URL="https://www.google.com/search?q="

# simple error printing
error() {
    echo "Error: $1" >&2
}

# add a TODO entry with timestamp
add_todo() {
    local todo_text="$1"
    [ -z "$todo_text" ] && return 1

    [ ! -f "$TODO_FILE" ] && echo -e "# TODO List\n" > "$TODO_FILE"

    echo "- [ ] $todo_text ($(date '+%Y-%m-%d %H:%M'))" >> "$TODO_FILE"
    tmux display-message "Added TODO: $todo_text"
}

# open a web search
search_web() {
    local query="$1"
    [ -z "$query" ] && return 1

    local encoded_query=$(printf '%s' "$query" | sed 's/ /+/g' | sed 's/[^a-zA-Z0-9+._-]//g')
    local search_url="${SEARCH_URL}${encoded_query}"

    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$search_url" >/dev/null 2>&1 &
    else
        for browser in "${BROWSER_PREFERENCES[@]}"; do
            command -v "$browser" >/dev/null 2>&1 && $browser "$search_url" >/dev/null 2>&1 & break
        done
    fi

    tmux display-message "Opening search for: $query"
}

# display the notes menu (in-editor or popup)
open_menu() {
    tmux set -gF '@last_session_name' '#S'

    if tmux has-session -t "$NOTE_SESSION_NAME" 2>/dev/null && tmux list-panes -t "$NOTE_SESSION_NAME" -F "#{pane_current_command}" | grep -q "^nvim$"; then
        # menu for active nvim session
        tmux display-menu -T "#[align=center] Notes (nvim-mode)" \
            "New note" n "command-prompt -p 'Enter note title:' 'send-keys -t $NOTE_SESSION_NAME \":e $NOTES_DIR/%%.md\" Enter'" \
            "Open note" o "send-keys -t $NOTE_SESSION_NAME \":cd $NOTES_DIR | FzfLua files\" Enter" \
            "TODO List" t "send-keys -t $NOTE_SESSION_NAME \":e $TODO_FILE\" Enter" \
            "Add Quick TODO" T "command-prompt -p 'Enter TODO:' 'run-shell \"$0 --add-todo %%\"'" \
            "Grep/find patterns" g "send-keys -t $NOTE_SESSION_NAME \":cd $NOTES_DIR | FzfLua live_grep\" Enter" \
            "Web Search" s "command-prompt -p 'Search query:' 'run-shell \"$0 --search %%\"'" \
            "Quit (q)" q ""
    else
        # popup menu outside of nvim
        tmux display-menu -T "#[align=center] Notes (popup-mode)" \
            "New note" n "command-prompt -p 'Enter note title:' \"display-popup -w 100% -h 100% -E 'tmux new-session -A -s $NOTE_SESSION_NAME \\\"$EDITOR $NOTES_DIR/%%.md\\\"'\"" \
            "Open note" o "display-popup -w 100% -h 100% -E \"tmux new-session -A -s $NOTE_SESSION_NAME 'fzf --preview \\\"bat --style=numbers --color=always --line-range=:500 {}\\\" --preview-window=up:60% --height=90% --layout=reverse --border=sharp --ansi < <(find $NOTES_DIR -type f -name \\\"*.md\\\") | xargs -r $EDITOR'\"" \
            "TODO List" t "display-popup -w 100% -h 100% -E \"tmux new-session -A -s $NOTE_SESSION_NAME \\\"$EDITOR $TODO_FILE\\\"\"" \
            "Add Quick TODO" T "command-prompt -p 'Enter TODO:' 'run-shell \"$0 --add-todo %%\"'" \
            "Grep/find patterns" g "display-popup -w 100% -h 100% -E \"tmux new-session -A -s $NOTE_SESSION_NAME 'rg --color=always --line-number --no-heading --smart-case . $NOTES_DIR | fzf --delimiter=: --preview \\\"bat --style=numbers --color=always --line-range=:500 {1}\\\" --preview-window=up:60% --height=90% --layout=reverse --border=sharp --ansi | cut -d ':' -f 1 | xargs -r $EDITOR'\"" \
            "Web Search" s "command-prompt -p 'Search query:' 'run-shell \"$0 --search %%\"'" \
            "Quit (q)" q ""
    fi
}

# make sure tmux is installed
command -v tmux >/dev/null 2>&1 || { error "tmux is not installed."; exit 1; }

# handle CLI arguments
if [ "$1" = "--add-todo" ]; then
    shift
    add_todo "$*"
    exit 0
fi

if [ "$1" = "--search" ]; then
    shift
    search_web "$*"
    exit 0
fi

if [ "$1" = "--new" ]; then
    if tmux has-session -t "$NOTE_SESSION_NAME" 2>/dev/null; then
        # reuse existing session
        tmux display-popup -w 100% -h 100% -E "
            FILE=\$(find $NOTES_DIR -type f -name '*.md' \
                | fzf --preview 'bat --style=numbers --color=always --line-range=:500 {}' \
                      --preview-window=up:60% --height=90% --layout=reverse --border=sharp --ansi)
            [ -n \"\$FILE\" ] && tmux send-keys -t $NOTE_SESSION_NAME \":e \$FILE\" Enter
        "
    else
        open_menu
    fi
    exit 0
fi

# default behavior: toggle or open menu
if [ -z "$1" ]; then
    if tmux has-session -t "$NOTE_SESSION_NAME" 2>/dev/null; then
        CURRENT_SESSION=$(tmux display-message -p '#S')
        [ "$CURRENT_SESSION" = "$NOTE_SESSION_NAME" ] && tmux detach-client || tmux display-popup -E -x200% -y0 -w50% -h99% "tmux attach-session -t $NOTE_SESSION_NAME"
    else
        open_menu
    fi
fi
