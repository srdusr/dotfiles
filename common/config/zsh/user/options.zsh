# Recursion limits
FUNCNEST=999
#
DISABLE_MAGIC_FUNCTIONS=true
#
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

# Hide history of commands starting with a space
setopt histignorespace           # Do not save commands that start with a space in the history

setopt BANG_HIST EXTENDED_HISTORY INC_APPEND_HISTORY SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS HIST_IGNORE_SPACE HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS HIST_VERIFY HIST_BEEP

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

