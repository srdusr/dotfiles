#!/bin/zsh

##########    Prompt(s)    ##########

terminfo_down_sc=$terminfo[cud1]$terminfo[cuu1]$terminfo[sc]$terminfo[cud1]

autoload -Uz vcs_info
autoload -Uz add-zsh-hook
autoload -U colors && colors

precmd_vcs_info() { vcs_info }

precmd_functions+=( precmd_vcs_info )

setopt prompt_subst

git_branch_test_color() {
    local ref=$(git symbolic-ref --short HEAD 2> /dev/null)
    if [ -n "${ref}" ]; then
        if [ -n "$(git status --porcelain)" ]; then
            local gitstatuscolor='%F{green}'
        else
            local gitstatuscolor='%F{82}'
        fi
        echo "${gitstatuscolor}${ref}"
    else
        echo ""
    fi
}

zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr ' +%F{15}staged%f'
zstyle ':vcs_info:*' unstagedstr ' -%F{15}unstaged%f'
zstyle ':vcs_info:*' actionformats '%F{5}%F{2}%b%F{3}|%F{1}%a%F{5}%f '
zstyle ':vcs_info:*' formats '%F{208} '$'\uE0A0'' %f$(git_branch_test_color)%f%F{76}%c%F{3}%u%f '
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked
zstyle ':vcs_info:*' enable git

+vi-git-untracked() {
    if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
        git status --porcelain | grep '??' &> /dev/null ; then
        hook_com[unstaged]+='%F{196} !%f%F{15}untracked%f'
    fi
}

ssh_name() {
    if [[ -n $SSH_CONNECTION ]]; then
        local ssh_info
        ssh_info="ssh:%F{green}%n$nc%f"
        if [[ -n $SSH_CONNECTION ]]; then
            local ip_address
            ip_address=$(echo $SSH_CONNECTION | awk '{print $3}')
            ssh_info="$ssh_info@%F{green}$ip_address%f"
        fi
        echo " ${ssh_info}"
    fi
}

function job_name() {
    job_name=""
    job_length=0
    if [ "${COLUMNS}" -gt 69 ]; then
        job_length=$((${COLUMNS}-70))
        [ "${job_length}" -lt "0" ] && job_length=0
    fi

    if [ "${job_length}" -gt 0 ]; then
        local job_count=$(jobs | wc -l)
        if [ "${job_count}" -gt 0 ]; then
            local title_jobs="jobs:"
            job_name="${title_jobs}"
            job_name+="%F{green}$(jobs | grep + | tr -s " " | cut -d " " -f 4- | cut -b 1-${job_length} | sed "s/\(.*\)/\1/")%f"
        fi
    fi

    echo "${job_name}"
}

function job_count() {
    local job_count
    job_count=$(jobs -s | grep -c "suspended")
    if [ "${job_count}" -gt 0 ]; then
        echo "(${job_count})"
    fi
}

current_jobs=' $(job_name)$(job_count)'
user="%n"
at="%F{15}at%{$reset_color%}"
machine="%F{4}%m%{$reset_color%}"
relative_home="%F{4}%~%{$reset_color%}"
carriage_return=""$'\n'""
empty_line_bottom="%r"
chevron_right=""
color_reset="%{$(tput sgr0)%}"
color_yellow="%{$(tput setaf 226)%}"
color_blink="%{$(tput blink)%}"
prompt_symbol="$"
dollar_sign="${color_yellow}${color_blink}${prompt_symbol}${color_reset}"
dollar="%(?:%F{2}${dollar_sign}:%F{1}${dollar_sign})"
space=" "
cmd_prompt="%(?:%F{2}${chevron_right} :%F{1}${chevron_right} )"
git_info="\$vcs_info_msg_0_"
v1="%{┌─[%}"
v2="%{]%}"
v3="└─["
v4="]"

function insert-mode () { echo "-- INSERT --" }
function normal-mode () { echo "-- NORMAL --" }

vi-mode-indicator () {
    if [[ ${KEYMAP} == vicmd || ${KEYMAP} == vi-cmd-mode ]]; then
        echo -ne '\e[1 q'
        vi_mode=$(normal-mode)
    elif [[ ${KEYMAP} == main || ${KEYMAP} == viins || ${KEYMAP} == '' ]]; then
        echo -ne '\e[5 q'
        vi_mode=$(insert-mode)
    fi
}

function set-prompt () {
    vi-mode-indicator
    mode="%F{145}%{$terminfo_down_sc$vi_mode$terminfo[rc]%f%}"
    #PS1="${relative_home}${vcs_info_msg_0_}${current_jobs} ${carriage_return}${mode}${dollar}${space}"
    PS1="${v1}${user}${v2}${space}${relative_home}${vcs_info_msg_0_}${current_jobs}$(ssh_name) ${carriage_return}${mode}${v3}${dollar}${v4}${empty_line_bottom}"
    #RPROMPT="$(ssh_name)"
}

precmd () {
    print -rP
    vcs_info
    set-prompt
}

function update-mode-file() {
    set-prompt
    local current_mode=$(cat ~/.vi-mode)
    local new_mode="$vi_mode"
    if [[ "$new_mode" != "$current_mode" ]]; then
        echo "$new_mode" >| ~/.vi-mode
    fi
    if command -v tmux &>/dev/null && [[ -n "$TMUX" ]]; then
        tmux refresh-client -S
    fi
}

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
    update-mode-file
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

preexec () { print -rn -- $terminfo[el]; echo -ne '\e[5 q' ; }

zle -N zle-line-init
zle -N zle-keymap-select

TRAPWINCH() {
    update-mode-file
}

set-prompt
