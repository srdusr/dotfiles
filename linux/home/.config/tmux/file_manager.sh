#!/usr/bin/env bash
# tmux file opener with fallback file manager (no preview)

# Mark this pane as the file manager immediately
tmux select-pane -T "FILE_MANAGER"
# Also set the option as backup
tmux set-option -pq @file_manager 1

orig_pane="$1"
chooser_file="$HOME/.cache/tmux-fm-selected"
rm -f "$chooser_file"

# Function: pick available file manager
pick_fm() {
    if command -v lf >/dev/null 2>&1; then
        echo "lf"
    elif command -v nnn >/dev/null 2>&1; then
        echo "nnn"
    elif command -v ranger >/dev/null 2>&1; then
        echo "ranger"
    else
        echo ""
    fi
}

fm=$(pick_fm)
if [[ -z "$fm" ]]; then
    echo "No file manager found (lf, nnn, ranger)." >&2
    cleanup
    exit 1
fi

# Cleanup function to reset both title and option
cleanup() {
    tmux select-pane -T ""
    tmux set-option -puq @file_manager
    rm -f "$chooser_file"
}

# Set trap to cleanup on exit (including when user presses 'q')
trap cleanup EXIT INT TERM

# Launch the chosen file manager with no preview where possible
case "$fm" in
    nnn)
        # Disable preview completely and use picker mode
        # -A: disable dir auto-select, -e: open text files in editor
        # -o: open files with opener, -x: show only selection
        NNN_OPENER="tee \"$chooser_file\"" nnn -Axo
        ;;
    lf)
        # Disable preview and set selection path
        lf -command 'set preview false' -selection-path="$chooser_file"
        ;;
    ranger)
        # Disable all previews
        ranger --choosefile="$chooser_file" \
               --cmd='set preview_files false' \
               --cmd='set preview_directories false' \
               --cmd='set preview_images false'
        ;;
esac

# Exit if no file chosen (user pressed 'q' or cancelled)
if [[ ! -s "$chooser_file" ]]; then
    exit 0
fi

file="$(head -n 1 "$chooser_file")"
rm -f "$chooser_file"

# Restrict to current window panes and exclude the file manager pane
current_window=$(tmux display-message -p '#I')
mapfile -t panes < <(
    tmux list-panes -t "$current_window" -F '#S:#I.#P' |
    grep -v "^$(tmux display-message -p '#S:#I').$(tmux display-message -p '#P')$"
)

# Choose target pane
if [[ ${#panes[@]} -eq 0 ]]; then
    exit 1
elif [[ ${#panes[@]} -eq 1 ]]; then
    target="${panes[0]}"
else
    echo "Select target pane:"
    for i in "${!panes[@]}"; do
        letter=$(printf "\\$(printf '%03o' $((97 + i)))") # a, b, c...
        echo "$letter) ${panes[$i]}"
    done
    read -n 1 -p "Choice: " choice
    echo
    idx=$(( $(printf "%d" "'$choice") - 97 ))
    if [[ $idx -ge 0 && $idx -lt ${#panes[@]} ]]; then
        target="${panes[$idx]}"
    else
        exit 1
    fi
fi

# Decide if file is text or binary
if file --mime-type "$file" 2>/dev/null | grep -q 'text/'; then
    opener="${EDITOR:-$(command -v nvim || command -v vim || echo 'vi')}"
else
    opener="$(command -v xdg-open || command -v open || echo 'cat')"
fi

# Send open command to target pane
tmux send-keys -t "$target" "$opener \"$file\"" C-m
