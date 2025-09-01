# vim:ft=zsh ts=2 sw=2 sts=2
#=#=#=
# simle_is_power theme
# folked from agnoster's Theme - https://gist.github.com/3712874
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://github.com/Lokaltog/powerline-fonts).
#=#=
#==============================================================================
# Color setting                                                             {{{
#==============================================================================

setopt prompt_subst

bg_dir=240
bg_dark=237
fg_red=210

#===========================================================================}}}
# Segment drawing                                                           {{{
#==============================================================================
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
# SEGMENT_SEPARATOR=''
SEGMENT_SEPARATOR=''
# SEGMENT_SEPARATOR=''
# SEGMENT_SEPARATOR='▒'
# SEGMENT_SEPARATOR='▓▒░'

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
    local bg fg
    [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
    [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
    if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
        echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
    else
        echo -n "%{$bg%}%{$fg%} "
    fi
    CURRENT_BG=$1
    [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
    if [[ -n $CURRENT_BG ]]; then
        echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
    else
        echo -n "%{%k%}"
    fi
    echo -n "%{%f%}"
    CURRENT_BG=''
}

#===========================================================================}}}
# Prompt components                                                         {{{
#==============================================================================
# Each component will draw itself, and hide itself if no information needs to be shown
#------------------------------------------------------------------------------
# Init:                                                                     {{{
#------------------------------------------------------------------------------

prompt_init() {
    echo -n "%{%F{240}%K{240}%}"
}

#---------------------------------------------------------------------------}}}
# Status:                                                                   {{{
#------------------------------------------------------------------------------
# - was there an error
# - am I root
# - are there background jobs?
# - am I in ranger subshell?

prompt_status() {
    local symbols
    symbols=()
    [[ $RETVAL -ne 0 ]] && symbols+="%{%F{${fg_red}}%}✞"
    [[ $UID -eq 0 ]] && symbols+="%{%F{223}%}⚡"
    [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"
    [[ -n ${RANGER_LEVEL} ]] && symbols+="%{%F{153}%}®"

    [[ -n "$symbols" ]] && prompt_segment ${bg_dark} NONE "$symbols"
}

#---------------------------------------------------------------------------}}}
# Virtualenv: current working virtualenv                                    {{{
#------------------------------------------------------------------------------

prompt_virtualenv() {
    local virtualenv_path="$VIRTUAL_ENV"
    if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
        prompt_segment green black "(`basename $virtualenv_path`)"
    fi
}

#---------------------------------------------------------------------------}}}
# Dir: current working directory                                            {{{
#------------------------------------------------------------------------------

prompt_dir() {
    prompt_segment ${bg_dir} 231 '%~'
}

#---------------------------------------------------------------------------}}}
# Git: branch/detached head, dirty status                                   {{{
#------------------------------------------------------------------------------

prompt_git() {
    local ref dirty mode repo_path
    repo_path=$(git rev-parse --git-dir 2>/dev/null)

    if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
        # dirty=$(parse_git_dirty)
        ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➔ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
        # if [[ -n $dirty ]]; then
        # prompt_segment ${bg_dark} 223
        # else
        prompt_segment ${bg_dark} 153
        # fi

        if [[ -e "${repo_path}/BISECT_LOG" ]]; then
            mode=" <B>"
        elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
            mode=" >M<"
        elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
            mode=" >R>"
        fi

        autoload -Uz vcs_info

        zstyle ':vcs_info:*' enable git
        zstyle ':vcs_info:*' get-revision true
        zstyle ':vcs_info:*' check-for-changes true
        zstyle ':vcs_info:*' stagedstr '+'
        zstyle ':vcs_info:git:*' unstagedstr '*'
        zstyle ':vcs_info:*' formats ' %u%c'
        zstyle ':vcs_info:*' actionformats ' %u%c'
        vcs_info
        echo -n "${ref/refs\/heads\// }${vcs_info_msg_0_%% }${mode}"
    fi
}

#---------------------------------------------------------------------------}}}
# Hg: prompt                                                                {{{
#------------------------------------------------------------------------------

prompt_hg() {
    local rev status
    if $(hg id >/dev/null 2>&1); then
        if $(hg prompt >/dev/null 2>&1); then
            if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
                # if files are not added
                prompt_segment ${fg_red} ${bg_dark}
                st='±'
            elif [[ -n $(hg prompt "{status|modified}") ]]; then
                # if any modification
                prompt_segment 223 ${bg_dark}
                st='±'
            else
                # if working copy is clean
                prompt_segment 153 ${bg_dark}
            fi
            echo -n $(hg prompt "☿ {rev}@{branch}") $st
        else
            st=""
            rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
            branch=$(hg id -b 2>/dev/null)
            if `hg st | grep -q "^\?"`; then
                prompt_segment ${fg_red} ${bg_dark}
                st='±'
            elif `hg st | grep -q "^(M|A)"`; then
                prompt_segment 223 ${bg_dark}
                st='±'
            else
                prompt_segment 153 ${bg_dark}
            fi
            echo -n "☿ $rev@$branch" $st
        fi
    fi
}

#}}}========================================================================}}}
# Build main prompt                                                         {{{
#==============================================================================


function vi-mode-indicator() {
    local current_mode
    current_mode=$(cat ~/.vi-mode 2>/dev/null || echo "")

    if [[ ${KEYMAP} == vicmd || ${KEYMAP} == vi-cmd-mode ]]; then
        [[ "$current_mode" != "-- NORMAL --" ]] && echo "-- NORMAL --" >| ~/.vi-mode
    elif [[ ${KEYMAP} == main || ${KEYMAP} == viins || ${KEYMAP} == '' ]]; then
        [[ "$current_mode" != "-- INSERT --" ]] && echo "-- INSERT --" >| ~/.vi-mode
    fi
}

build_prompt() {
    RETVAL=$?
    vi-mode-indicator
    prompt_init
    prompt_virtualenv
    prompt_dir
    prompt_git
    prompt_hg
    prompt_status
    prompt_end
}

color_reset="%{$(tput sgr0)%}"
color_yellow="%{$(tput setaf 226)%}"
color_blink="%{$(tput blink)%}"
prompt_symbol="$"
dollar_sign="${color_yellow}${color_blink}${prompt_symbol}${color_reset}"
dollar="%(?:%F{2}${dollar_sign}:%F{1}${dollar_sign})"

v1="%{┌─[%}"
v2="%{]%}"
v3="└─["
v4="]"
user="%n"

PROMPT="${v1}${user}%f%b%k${v2}$(build_prompt)$reset_color
${v3}${dollar}${v4}${empty_line_bottom}$reset_color"
#PROMPT='%n@%m:%~%# '
#%{%F{240}%}\$ %{$reset_color%}'
#%{${dollar}%} %{$reset_color%}'
RPROMPT=''

PROMPT2='%{%F{30}%}↪%{$reset_color%} '
RPROMPT2='%{$fg_bold[green]%}%_%{$reset_color%}'

function update-mode-file() {
    local current_mode=$(cat ~/.vi-mode 2>/dev/null || echo "")
    local new_mode="$vi_mode"

    # Check if the mode is different before updating
    if [[ "$new_mode" != "$current_mode" ]]; then
        echo "$new_mode" >| ~/.vi-mode
    fi

    # Only call zle if ZLE is active
    if [[ -o zle ]]; then
        zle reset-prompt  # Force refresh
    fi

    # Ensure tmux client refresh only happens if tmux is running
    if command -v tmux &>/dev/null && [[ -n "$TMUX" ]]; then
        tmux refresh-client -S
    fi
}
function zle-line-init() {
    zle reset-prompt
    case "${KEYMAP}" in
        vicmd)
            echo -ne '\e[1 q'
            ;;
        main|viins|*)
            echo -ne '\e[5 q'
            ;;
    esac
}
function zle-keymap-select() {
    local current_keymap
    current_keymap="${KEYMAP}"

    update-mode-file
    zle reset-prompt

    case "$current_keymap" in
        vicmd)
            echo -ne '\e[1 q'
            ;;
        main|viins|*)
            echo -ne '\e[5 q'
            ;;
    esac
}

precmd () {
    print -rP
}

preexec () {
    print -rn -- $terminfo[el]
    echo -ne '\e[5 q'  # Reset cursor shape
}
zle -N zle-line-init
zle -N zle-keymap-select

#===========================================================================}}}
