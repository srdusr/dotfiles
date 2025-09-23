#!/bin/zsh

##########    Prompt(s)    ##########

# Autoload necessary functions for vcs_info and coloring
autoload -Uz vcs_info
autoload -Uz add-zsh-hook
autoload -U colors && colors

# Enable prompt substitution
setopt prompt_subst

# Display git branch status and color
precmd_vcs_info() { vcs_info }

# Add vcs_info to precmd functions
precmd_functions+=( precmd_vcs_info )

# Manipulates cursor position: moves down by 2 lines, saves position, and restores cursor after an operation.
terminfo_down_sc=$terminfo[cud1]$terminfo[cuu1]$terminfo[sc]$terminfo[cud1]

# Track last executed command for exit code display
typeset -g _last_executed_command=""
typeset -g _cmd_start_time=0
typeset -g _cmd_end_time=0
typeset -g _cmd_duration=0
typeset -g _spinner_idx=0
typeset -ga _spinner_frames=('⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷')
typeset -g _cmd_is_running=0
typeset -g _show_spinner=0
typeset -g _SPINNER_DELAY=5  # Only show spinner after 5 seconds
typeset -g _FINISHED_DELAY=10  # Only show finished message after 10 seconds

# Register the ZLE widget for spinner updates - do this early
zle -N update_spinner

# Cache git information to avoid repeated expensive operations
typeset -g _git_cached_info=""
typeset -g _git_cache_timestamp=0
typeset -g _git_cache_lifetime=2  # seconds before cache expires

# Calculate how much space is available for the prompt components
function available_space() {
    local width=${COLUMNS:-80}
    echo $width
}

# Check if we need to abbreviate git info
function need_to_abbreviate_git() {
    local available=$(available_space)
    local vi_mode_len=13  # Length of "-- INSERT --"
    local prompt_base_len=20  # Base prompt elements length
    local path_len=${#${PWD/#$HOME/\~}}
    local git_full_len=0

    # Try to estimate git info length if available
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
        git_full_len=${#branch}

        # Add length for status indicators
        if [[ -n "$(git status --porcelain)" ]]; then
            # Rough estimate for status text
            git_full_len=$((git_full_len + 20))
        fi
    fi

    # Calculate total space needed
    local total_needed=$((vi_mode_len + prompt_base_len + path_len + git_full_len))

    # Determine if we need to abbreviate
    if [[ $total_needed -gt $available ]]; then
        return 0  # Need to abbreviate
    else
        return 1  # Don't need to abbreviate
    fi
}

# Custom git branch coloring based on status
git_branch_test_color() {
    local now=$(date +%s)
    local cache_age=$((now - _git_cache_timestamp))

    # Use cached value if available and not expired
    if [[ -n "$_git_cached_info" && $cache_age -lt $_git_cache_lifetime ]]; then
        echo "$_git_cached_info"
        return
    fi

    local ref=$(git symbolic-ref --short HEAD 2> /dev/null)
    if [ -n "${ref}" ]; then
        if [ -n "$(git status --porcelain)" ]; then
            local gitstatuscolor='%F{green}'
        else
            local gitstatuscolor='%F{82}'
        fi
        _git_cached_info="${gitstatuscolor}${ref}"
        _git_cache_timestamp=$now
        echo "$_git_cached_info"
    else
        _git_cached_info=""
        _git_cache_timestamp=$now
        echo ""
    fi
}

# Git branch with dynamic abbreviation
git_branch_dynamic() {
    local now=$(date +%s)
    local cache_age=$((now - _git_cache_timestamp))

    # Only query git if cache is expired
    if [[ $cache_age -ge $_git_cache_lifetime ]]; then
        local ref=$(git symbolic-ref --short HEAD 2> /dev/null)
        if [ -n "${ref}" ]; then
            if need_to_abbreviate_git; then
                # Abbreviated version for small terminals
                case "${ref}" in
                    "main") _git_cached_info="m" ;;
                    "master") _git_cached_info="m" ;;
                    "development") _git_cached_info="d" ;;
                    "develop") _git_cached_info="d" ;;
                    "feature/"*) _git_cached_info="f/${ref#feature/}" | cut -c 1-4 ;;
                    "release/"*) _git_cached_info="r/${ref#release/}" | cut -c 1-4 ;;
                    "hotfix/"*) _git_cached_info="h/${ref#hotfix/}" | cut -c 1-4 ;;
                    *) _git_cached_info="${ref}" | cut -c 1-5 ;; # Truncate to first 5 chars for other branches
                esac
            else
                # Full branch name when there's room
                _git_cached_info="${ref}"
            fi
            _git_cache_timestamp=$now
            echo "$_git_cached_info"
        else
            _git_cached_info=""
            _git_cache_timestamp=$now
            echo ""
        fi
    else
        echo "$_git_cached_info"
    fi
}

# VCS info styles (e.g., git)
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' enable git

# Dynamically configure vcs_info formats based on available space
function configure_vcs_styles() {
    if need_to_abbreviate_git; then
        # Abbreviated versions
        zstyle ':vcs_info:*' stagedstr ' +%F{15}s%f'
        zstyle ':vcs_info:*' unstagedstr ' -%F{15}u%f'
    else
        # Full versions
        zstyle ':vcs_info:*' stagedstr ' +%F{15}staged%f'
        zstyle ':vcs_info:*' unstagedstr ' -%F{15}unstaged%f'
    fi

    zstyle ':vcs_info:*' actionformats '%F{5}%F{2}%b%F{3}|%F{1}%a%F{5}%f '
    zstyle ':vcs_info:*' formats '%F{208} '$'\uE0A0'' %f$(git_branch_test_color)%f%F{76}%c%F{3}%u%f '
    zstyle ':vcs_info:git*+set-message:*' hooks git-untracked git-dynamic
}

# Show "untracked" status in git - with conditional abbreviation
+vi-git-untracked() {
    if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
        git status --porcelain | grep '??' &> /dev/null ; then

        if need_to_abbreviate_git; then
            hook_com[unstaged]+='%F{196} !%f%F{15}u%f'
        else
            hook_com[unstaged]+='%F{196} !%f%F{15}untracked%f'
        fi
    fi
}

# Dynamic git branch hook
+vi-git-dynamic() {
    hook_com[branch]=$(git_branch_dynamic)
}

# SSH info with conditional abbreviation
ssh_name() {
    if [[ -n $SSH_CONNECTION ]]; then
        local ssh_info

        if need_to_abbreviate_git; then
            # Abbreviated SSH info
            ssh_info="ssh:%F{green}%n$nc%f"
        else
            ssh_info="ssh:%F{green}%n$nc%f"
            if [[ -n $SSH_CONNECTION ]]; then
                local ip_address
                ip_address=$(echo $SSH_CONNECTION | awk '{print $3}')
                ssh_info="$ssh_info@%F{green}$ip_address%f"
            fi
        fi
        echo " ${ssh_info}"
    fi
}

# Job names (for job control) with conditional abbreviation
function job_name() {
    job_name=""
    job_length=0
    local available=$(available_space)

    # Only show jobs if we have reasonable space
    if [ "${available}" -gt 60 ]; then
        local job_count=$(jobs | wc -l)
        if [ "${job_count}" -gt 0 ]; then
            if need_to_abbreviate_git; then
                job_name+="%F{green}j:${job_count}%f"
            else
                local title_jobs="jobs:"
                job_name="${title_jobs}"
                job_length=$((${available}-70))
                [ "${job_length}" -lt "0" ] && job_length=0

                if [ "${job_length}" -gt 0 ]; then
                    job_name+="%F{green}$(jobs | grep + | tr -s " " | cut -d " " -f 4- | cut -b 1-${job_length} | sed "s/\(.*\)/\1/")%f"
                else
                    job_name+="%F{green}${job_count}%f"
                fi
            fi
        fi
    fi

    echo "${job_name}"
}

# Check if we should show the spinner based on elapsed time
function should_show_spinner() {
    if [[ $_cmd_is_running -eq 1 ]]; then
        local current_time=$(date +%s)
        local elapsed=$((current_time - _cmd_start_time))

        # Show spinner only after delay threshold
        if [[ $elapsed -ge $_SPINNER_DELAY ]]; then
            _show_spinner=1
            return 0  # Yes, show spinner
        fi
    fi

    _show_spinner=0
    return 1  # No, don't show spinner
}

# Update spinner animation - simplified version
function update_spinner() {
    # This function is now just a ZLE widget placeholder
    # The actual spinner updates happen in the TRAPALRM handler
    :
}

# Start spinner timer when command runs longer than threshold
function start_spinner_timer() {
    _spinner_idx=0
    _cmd_is_running=1
    _show_spinner=0  # Start with spinner hidden until delay passes

    # Set up the TRAPALRM for periodic updates - CRITICAL FIX
    TMOUT=0.5  # Update spinner every 0.5 seconds

    # Define TRAPALRM function - this is key to the spinner working
    TRAPALRM() {
        if [[ $_cmd_is_running -eq 1 ]]; then
            local current_time=$(date +%s)
            local elapsed=$((current_time - _cmd_start_time))

            # Show spinner only after delay threshold
            if [[ $elapsed -ge $_SPINNER_DELAY ]]; then
                _show_spinner=1
                _spinner_idx=$(( (_spinner_idx + 1) % ${#_spinner_frames[@]} ))

                # Force prompt refresh - critical for updating the spinner
                if [[ -o zle ]]; then
                    zle reset-prompt 2>/dev/null || true
                    zle -R
                fi
            fi
        fi
    }
}

# Stop spinner when command finishes
function stop_spinner_timer() {
    _cmd_is_running=0
    _show_spinner=0

    # Disable the alarm trap and timer
    TRAPALRM() { : }
    TMOUT=0

    # Force prompt refresh to clear spinner
    if [[ -o zle ]]; then
        zle reset-prompt 2>/dev/null || true
        zle -R
    fi
}

# Format time in a human-readable way
function format_time() {
    local seconds=$1
    local result=""

    # Format time as hours:minutes:seconds for long durations
    if [[ $seconds -ge 3600 ]]; then
        local hours=$((seconds / 3600))
        local minutes=$(( (seconds % 3600) / 60 ))
        local secs=$((seconds % 60))
        result="${hours}h${minutes}m${secs}s"
    elif [[ $seconds -ge 60 ]]; then
        local minutes=$((seconds / 60))
        local secs=$((seconds % 60))
        result="${minutes}m${secs}s"
    else
        result="${seconds}s"
    fi

    echo "$result"
}

# Error code display for RPROMPT with spinner - fixed version
function exit_code_info() {
    local exit_code=$?

    # If a command is running and we should show spinner
    if [[ $_cmd_is_running -eq 1 && $_show_spinner -eq 1 ]]; then
        local spinner=${_spinner_frames[$_spinner_idx]}
        local current_time=$(date +%s)
        local elapsed=$((current_time - _cmd_start_time))
        echo "%F{yellow}${spinner} ${elapsed}s%f"
        return
    fi

    # Don't show error code when line editor is active (user is typing)
    if [[ -o zle ]]; then
        echo ""
        return
    fi

    # Show command finished message for completed commands that took longer than threshold
    if [[ -n "$_last_executed_command" && $_cmd_duration -ge $_FINISHED_DELAY ]]; then
        local duration_formatted=$(format_time $_cmd_duration)

        # Show error code along with finished message if there was an error
        if [[ $exit_code -ne 0 ]]; then
            # Show TSTP (148) as a suspension indicator instead of error
            if [[ $exit_code -eq 148 ]]; then
                echo "%F{cyan}finished ${duration_formatted}%f %F{yellow}⏸ TSTP%f"
                return
            fi

            local signal_name=""
            # Check if it's a signal
            if [[ $exit_code -gt 128 && $exit_code -le 165 ]]; then
                local signal_num=$((exit_code - 128))
                signal_name=$(kill -l $signal_num 2>/dev/null)
                if [[ -n "$signal_name" ]]; then
                    signal_name=" ($signal_name)"
                fi
            fi

            # Return formatted error code with finished message
            echo "%F{cyan}finished ${duration_formatted}%f %F{red}✘ $exit_code$signal_name%f"
        else
            echo "%F{cyan}finished ${duration_formatted}%f %F{green}✓%f"
        fi
        return
    fi

    # Don't show anything for exit code 0 (success) if this is first command
    if [[ -z "$_last_executed_command" && $exit_code -eq 0 ]]; then
        echo ""
        return
    fi

    # Show TSTP (148) as a suspension indicator instead of error
    if [[ $exit_code -eq 148 ]]; then
        echo "%F{yellow}⏸ TSTP%f"
        return
    fi

    if [[ $exit_code -ne 0 ]]; then
        local signal_name=""

        # Check if it's a signal
        if [[ $exit_code -gt 128 && $exit_code -le 165 ]]; then
            local signal_num=$((exit_code - 128))
            signal_name=$(kill -l $signal_num 2>/dev/null)
            if [[ -n "$signal_name" ]]; then
                signal_name=" ($signal_name)"
            fi
        fi

        # Return formatted error code
        echo "%F{red}✘ $exit_code$signal_name%f"
    else
        echo "%F{green}✓%f"  # Success indicator
    fi
}

abbreviated_path() {
    local full_path="${PWD/#$HOME/~}"  # Replace $HOME with ~
    local available=$(available_space)

    # If path is root
    if [[ "$full_path" == "/" ]]; then
        echo "%F{4}/%f"
        return
    fi

    # If path is just ~
    if [[ "$full_path" == "~" ]]; then
        echo "%F{4}~%f"
        return
    fi

    # If extremely small terminal, show nothing to avoid breaking prompt
    if (( available < 20 )); then
        echo ""
        return
    fi

    # For very narrow terminals, just show the current dir
    if (( available < 30 )); then
        echo "%F{4}%1~%f"
        return
    fi

    # For moderately narrow terminals, show last two components
    if (( available < 40 )); then
        echo "%F{4}%2~%f"
        return
    fi

    # For wide terminals, show full path
    if (( available > 70 )); then
        echo "%F{4}${full_path}%f"
        return
    fi

    # Otherwise, show abbreviated path (e.g. ~/d/p/n)
    local parts=("${(s:/:)full_path}")
    local result=""
    local last_index=${#parts[@]}

    for i in {1..$((last_index - 1))}; do
        [[ -n ${parts[i]} ]] && result+="/${parts[i]:0:1}"
    done

    result+="/${parts[last_index]}"
    echo "%F{4}${result}%f"
}


# Prompt variables
user="%n"
at="%F{15}at%{$reset_color%}"
machine="%F{4}%m%{$reset_color%}"
relative_home="%F{4}%~%{$reset_color%}"
carriage_return=""$'\n'""
empty_line_bottom=""
chevron_right=""
color_reset="%{$(tput sgr0)%}"
color_yellow="%{$(tput setaf 226)%}"
color_blink="%{$(tput blink)%}"
prompt_symbol="$"
dollar_sign="${color_yellow}${color_blink}${prompt_symbol}${color_reset}"
dollar="%(?:%F{2}${dollar_sign}:%F{1}${dollar_sign})"
space=" "
#thin_space=$'\u2009'
thin_space=$'\u202F'
cmd_prompt="%(?:%F{2}${chevron_right} :%F{1}${chevron_right} )"
git_info="\$vcs_info_msg_0_"
v1="%{┌─[%}"
v2="%{]%}"
v3="└──["
v4="]"
newline=$'\n'

# Indicate INSERT mode for vi - NEVER truncate this
function insert-mode () {
    echo "-- INSERT --"
}

# Indicate NORMAL mode for vi - NEVER truncate this
function normal-mode () {
    echo "-- NORMAL --"
}

# Vi mode indicator
vi-mode-indicator () {
    if [[ ${KEYMAP} == vicmd || ${KEYMAP} == vi-cmd-mode ]]; then
        echo -ne '\e[1 q'
        vi_mode=$(normal-mode)
    elif [[ ${KEYMAP} == main || ${KEYMAP} == viins || ${KEYMAP} == '' ]]; then
        echo -ne '\e[5 q'
        vi_mode=$(insert-mode)
    fi
}

# Prompt function to ensure the prompt stays on one line, even in narrow terminals
function set-prompt() {
    vi-mode-indicator
    configure_vcs_styles  # Dynamically set vcs styles based on available space
    vcs_info  # Refresh vcs info with new styles

    local available=$(available_space)
    if (( available < 14 )); then
        # Extremely narrow terminal — use minimal prompt
        PS1="${carriage_return}${dollar}${space}${empty_line_bottom}"
        RPROMPT='$(exit_code_info)'

    else
        # Path display - always show something for path, but adapt based on space
        local path_display="$(abbreviated_path)"

        # Git info - omit entirely if not enough space
        local gitinfo=""
        if [[ $available -gt 40 ]]; then
            gitinfo="${vcs_info_msg_0_}"
        fi

        # Jobs info
        local jobs=" $(job_name)"

        # SSH info
        local sshinfo="$(ssh_name)"

        # Vi mode is priority 1 - ALWAYS show it
        mode="%F{145}%{$terminfo_down_sc$vi_mode$terminfo[rc]%f%}"

        # Right prompt for error codes or spinner
        RPROMPT='$(exit_code_info)'

        PS1="${newline}${v1}${user}${v2} ${path_display}${gitinfo}${jobs}${sshinfo}${carriage_return}${mode}${v3}${dollar}${v4}${empty_line_bottom}"
    fi
}

# Pre-command hook to set prompt
my_precmd() {
    # Calculate command duration if a command was run
    if [[ -n "$_last_executed_command" && $_cmd_start_time -gt 0 ]]; then
        _cmd_end_time=$(date +%s)
        _cmd_duration=$((_cmd_end_time - _cmd_start_time))
    else
        _cmd_duration=0
    fi

    stop_spinner_timer  # Make sure spinner is stopped
    vcs_info
    set-prompt
    vi-mode-indicator
}

add-zsh-hook precmd my_precmd

# Update mode file based on current mode
update-mode-file() {
    set-prompt
    local current_mode=$(cat ~/.vi-mode 2>/dev/null || echo "")
    local new_mode="$vi_mode"

    if [[ "$new_mode" != "$current_mode" ]]; then
        echo "$new_mode" >| ~/.vi-mode
    fi

    # Ensure we're in an interactive shell and ZLE is active
    if [[ -o zle ]] && zle -l &>/dev/null; then
        zle reset-prompt 2>/dev/null || true
    else
        # If ZLE is not active, fallback and print the prompt manually
        set-prompt
        print -Pn "$PS1"
    fi

    # Refresh tmux client if tmux is running
    if command -v tmux &>/dev/null && [[ -n "$TMUX" ]]; then
        tmux refresh-client -S
    fi
}

# Check if nvim is running and update mode
function check-nvim-running() {
    if pgrep -x "nvim" > /dev/null; then
        vi_mode=""
        update-mode-file
        if command -v tmux &>/dev/null && [[ -n "$TMUX" ]]; then
            tmux refresh-client -S
        fi
    else
        if [[ ${KEYMAP} == vicmd || ${KEYMAP} == vi-cmd-mode ]]; then
            vi_mode=$(normal-mode)
        elif [[ ${KEYMAP} == main || ${KEYMAP} == viins || ${KEYMAP} == '' ]]; then
            vi_mode=$(insert-mode)
        fi
        update-mode-file
        if command -v tmux &>/dev/null && [[ -n "$TMUX" ]]; then
            tmux refresh-client -S
        fi
    fi
}

# ZLE line initialization hook
function zle-line-init() {
    zle reset-prompt
    vi-mode-indicator
    case "${KEYMAP}" in
        vicmd)
            echo -ne '\e[1 q'
            ;;
        main|viins|*)
            echo -ne '\e[5 q'
            ;;
    esac
}

# ZLE keymap select hook
function zle-keymap-select() {
    update-mode-file
    zle reset-prompt
    zle -R
    vi-mode-indicator
    case "${KEYMAP}" in
        vicmd)
            echo -ne '\e[1 q'
            ;;
        main|viins|*)
            echo -ne '\e[5 q'
            ;;
    esac
}

# Safer version of zle reset-prompt
function safe_reset_prompt() {
    # Only reset if ZLE is active
    if [[ -o zle ]] && zle -l &>/dev/null; then
        zle reset-prompt 2>/dev/null || true
    fi
}

# Preexec hook for command execution - NO BACKGROUND JOBS VERSION
function preexec() {
    # Store the command being executed
    _last_executed_command=$1
    _cmd_start_time=$(date +%s)
    _cmd_is_running=1
    _show_spinner=0  # Reset spinner flag

    # Start the spinner timer immediately
    start_spinner_timer

    print -rn -- $terminfo[el]
    echo -ne '\e[5 q'
    vi-mode-indicator
}

# Terminal resizing: resets the prompt if ZLE is active, updates the mode file.
TRAPWINCH() {
    if [[ -o zle ]] && zle -l &>/dev/null; then
        zle -R
        zle reset-prompt 2>/dev/null || true
    fi
    update-mode-file 2>/dev/null
}

# Register ZLE hooks
zle -N zle-line-init
zle -N zle-keymap-select
zle -N update_spinner

# Register hooks
add-zsh-hook preexec preexec
add-zsh-hook precmd my_precmd

set-prompt
