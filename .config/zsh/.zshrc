
#  ███████╗███████╗██╗  ██╗██████╗  ██████╗
#  ╚══███╔╝██╔════╝██║  ██║██╔══██╗██╔════╝
#    ███╔╝ ███████╗███████║██████╔╝██║
#   ███╔╝  ╚════██║██╔══██║██╔══██╗██║
#  ███████╗███████║██║  ██║██║  ██║╚██████╗
#  ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝

export PATH=$HOME/bin:/usr/local/bin:/sbin:/usr/sbin:$PATH
#export PYTHONPATH=/usr/local/bin/python3
#if [[ ! $(tmux list-sessions) ]]; then
#  tmux
#fi

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Allow CTRL+D to exit zsh with partial command line (non empty line)
exit_zsh() { exit }
zle -N exit_zsh
bindkey '^D' exit_zsh

# Some other useful functionalities
setopt autocd		# Automatically cd into typed directory.
stty intr '^q'        # free Ctrl+C for copy use Ctrl+q instead
stty lnext '^-'        # free Ctrl+V for paste use ^- instead
stty stop undef		# Disable ctrl-s to freeze terminal.
stty start undef

export PATH="$HOME/.local/bin:$PATH"
export VIRTUAL_ENV_DISABLE_PROMPT=true
#unsetopt BEEP
# Enable various options
setopt interactive_comments beep extendedglob nomatch notify completeinword prompt_subst

##########    Prompt(s)    ##########

# Enable colors and change prompt:
autoload -U colors && colors	# Load colors
#autoload -U promptinit && promptinit
#prompt fade red
# Prompt with Vi insert-mode/normal-mode and blinking '$', note blinking '$' only works on some terminals.
terminfo_down_sc=$terminfo[cud1]$terminfo[cuu1]$terminfo[sc]$terminfo[cud1]

function insert-mode () { echo "-- INSERT --" }
function normal-mode () { echo "-- NORMAL --" }


git_branch_test_color() {
  local ref=$(git symbolic-ref --short HEAD 2> /dev/null)
  if [ -n "${ref}" ]; then
    if [ -n "$(git status --porcelain)" ]; then
      local gitstatuscolor='%F{196}'
    else
      local gitstatuscolor='%F{82}'
    fi
    echo "${gitstatuscolor}${ref}"
  else
    echo ""
  fi
}
#PROMPT='%9c$(git_branch_test_color)%F{none} %# '

#echo "${gitstatuscolor} (${ref})"

autoload -Uz add-zsh-hook vcs_info
zstyle ':vcs_info:*' stagedstr ' +%F{15}staged%f' 
zstyle ':vcs_info:*' unstagedstr ' -%F{15}unstaged%f' 
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' actionformats '%F{5}%F{2}%b%F{3}|%F{1}%a%F{5}%f '
zstyle ':vcs_info:*' formats \
  '%F{208} '$'\uE0A0'' %f$(git_branch_test_color)%f%F{76}%c%F{3}%u%f '
    #'%{-[%F{226}'$'\uE0A0''%f%{%F{76}%b%f%}]%} %F{76}%c%F{3}%u%f'
    #'%F{226}'$'\uE0A0''%f%{(%F{76}%b%f)%} %F{76}%c%F{3}%u%f'
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked
zstyle ':vcs_info:*' enable git 
+vi-git-untracked() {
  if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
  [[ $(git ls-files --other --directory --exclude-standard | sed q | wc -l | tr -d ' ') == 1 ]] ; then
  hook_com[unstaged]+='%F{196} !%f%F{15}untracked%f'
fi
}
#hook_com[unstaged]+=' %F{15}(%f%F{196}!%f%F{15})untracked%f'


#RPROMPT='%F{5}[%F{2}%n%F{5}] %F{3}%3~ ${vcs_info_msg_0_} %f%# '
#add-zsh-hook
function my_precmd () {
    vcs_info
    PS1="%{┌─[%F{145}%n%f] %F{39}%0~%f%} ${vcs_info_msg_0_}
    %{%{$terminfo_down_sc$(insert-mode)$terminfo[rc]%}%{└─%{["%{$(tput setaf 226)%}""%{$(tput blink)%}"%{$%}"%{$(tput sgr0)%}"%{%G]%}%}%}%}"
}

function set-prompt () {
    case ${KEYMAP} in
      (vicmd)      VI_MODE="$(normal-mode)" ;;
      (main|viins) VI_MODE="$(insert-mode)" ;;
      (*)          VI_MODE="$(insert-mode)" ;;
    esac
    PS1="%{┌─[%F{145}%n%f] %F{39}%0~%f%} ${vcs_info_msg_0_}
    %{%{$terminfo_down_sc$VI_MODE$terminfo[rc]%}%{└─%{["%{$(tput setaf 226)%}""%{$(tput blink)%}"%{$%}"%{$(tput sgr0)%}"%{%G]%}%}%}%}"
}
add-zsh-hook precmd my_precmd
RPROMPT='%(?..[%F{196}%?%f] )'
#RPROMPT="%K{172}${vcs_info_msg_0_}%k%(?..[%F{196}%?%f] )"

#autoload -Uz vcs_info
#zstyle ':vcs_info:*' stagedstr 'M' 
#zstyle ':vcs_info:*' unstagedstr 'M' 
#zstyle ':vcs_info:*' check-for-changes true
#zstyle ':vcs_info:*' actionformats '%{(%F{76}%b%F{3}|%F{1}%a%%f%}) '
#zstyle ':vcs_info:*' formats \
#    '%{(%F{76}%b%f)%} %F{76}%c%F{3}%u%f'
#zstyle ':vcs_info:git*+set-message:*' hooks git-untracked
#zstyle ':vcs_info:*' enable git 
#+vi-git-untracked() {
#  if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
#  [[ $(git ls-files --other --directory --exclude-standard | sed q | wc -l | tr -d ' ') == 1 ]] ; then
#  hook_com[unstaged]+='%F{1}??%f'
#fi
#}
#
#
##RPROMPT='%F{5}[%F{2}%n%F{5}] %F{3}%3~ ${vcs_info_msg_0_} %f%# '
#precmd () {
#    print -rP "
#"
#    #PS1="┌─[%F{48}%n%f]-[%F{154}%B%m%b%f]-[%F{202}%#%f%F{39}%0~%f]
#    PS1="%{┌─[%F{48}%n%f] %F{119}%#%f%F{119}%0~%f%}] ${vcs_info_msg_0_}
#    %{%{$terminfo_down_sc$(insert-mode)$terminfo[rc]%}%{└─%{["%{$(tput setaf 226)%}""%{$(tput blink)%}"%{$%}"%{$(tput sgr0)%}"%{%G]%}%}%}%}"
#} && { vcs_info } 
#
#function set-prompt () {
#    case ${KEYMAP} in
#      (vicmd)      VI_MODE="$(normal-mode)" ;;
#      (main|viins) VI_MODE="$(insert-mode)" ;;
#      (*)          VI_MODE="$(insert-mode)" ;;
#    esac
#    PS1="%{┌─[%F{48}%n%f] %F{119}%#%f%F{119}%0~%f%} ${vcs_info_msg_0_}
#    %{%{$terminfo_down_sc$VI_MODE$terminfo[rc]%}%{└─%{["%{$(tput setaf 226)%}""%{$(tput blink)%}"%{$%}"%{$(tput sgr0)%}"%{%G]%}%}%}%}"
#}
#PS1="%{┌─[%F{48}%n%f]-[%F{48}%B%m%b%f]-[%F{48}%#%f%F{48}%0~%f]%}
function zle-line-init zle-keymap-select {
    set-prompt
    zle reset-prompt
    case $KEYMAP in
        vicmd) echo -ne '\e[1 q';;      # block
        viins|main) echo -ne '\e[5 q';; # beam
    esac
}

preexec () { print -rn -- $terminfo[el]; echo -ne '\e[5 q' ; }

zle -N zle-line-init
zle -N zle-keymap-select

# Load version control information
#autoload -Uz vcs_info
#precmd() { vcs_info }

# Format the vcs_info_msg_0_ variable
#zstyle ':vcs_info:git:*' formats 'on branch %b'

# Set up the right-side prompt (with git branch name) and throw conditional error Code


## function to return current branch name while suppressing errors.
#function git_branch() {
#    branch=$(git symbolic-ref HEAD 2> /dev/null | awk 'BEGIN{FS="/"} {print $NF}')
#    if [[ $branch == "" ]]; then
#        :
#    else
#        echo ' (' $branch ') '
#    fi
#}

#setopt prompt_subst             # allow command substitution inside the prompt
#PROMPT='%~ $(git_branch) >'     # set the prompt value

#autoload -Uz add-zsh-hook vcs_info
#setopt prompt_subst
#add-zsh-hook precmd my_precmd
#
#zstyle ':vcs_info:git:*' formats '%b'
#
#function my_precmd {
#  local theUser='%B%F{39}%n%f%b'
#  local theHost='%B%F{white}@%m%f%b'
#  local git1="%F{220}~%f$(git_prompt_info)"
#  local rcAndArrow='%(?.%F{white}.%B%F{red}[%?])»%f%b'
#
#  vcs_info
#  local git2color='cyan'
#  [[ "${vcs_info_msg_0_}" == "master" ]] && git2color='196'
#  local git2="||%F{${git2color}}${vcs_info_msg_0_}%f||"
#
#  psvar[1]="${theUser}${theHost} ${git1} ${rcAndArrow} "
#  psvar[2]="${git2}"
#}
#
#PROMPT='${psvar[1]}'
#RPROMPT='${psvar[2]}'



##########    Auto-completion    ##########

#autoload -U promptinit && promptinit
autoload -Uz compinit && compinit

# Accept completion with <tab> or Ctrl+i and go to next/previous suggestions with Vi like keys: Ctrl+n/p
zmodload -i zsh/complist
accept-and-complete-next-history() {
    zle expand-or-complete-prefix
}

zle -N accept-and-complete-next-history
bindkey -M menuselect '^i' accept-and-complete-next-history
bindkey '^n' expand-or-complete
bindkey '^p' reverse-menu-complete
zstyle ':completion:*' menu select=1



##########    Vi mode    ##########

export KEYTIMEOUT=25
export EDITOR=$VISUAL
export VISUAL=nvim
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^[[3~'  delete-char
bindkey -M vicmd '^[[3~'  delete-char
bindkey -r '\e/'
bindkey -M viins 'jj' vi-cmd-mode
bindkey "^W" backward-kill-word
bindkey "^H" backward-delete-char      # Control-h also deletes the previous char
bindkey "^U" backward-kill-line

bindkey "^N" history-search-forward # or you can bind it to the down key "^[[B"
bindkey "^P" history-search-backward # or you can bind it to Up key "^[[A"
bindkey '^X' autosuggest-execute
bindkey '^Y' autosuggest-accept

# Edit line in vim with alt-e
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line
#bindkey '^[e' edit-command-line # alt + e

##########    Useful Commands/Alias    ##########

# Enter directory and list contents
cd() {
	if [ -n "$1" ]; then
		builtin cd "$@" && ls -pvA --color=auto --group-directories-first
	else
		builtin cd ~ && ls -pvA --color=auto --group-directories-first
	fi
}

# Back up a file. Usage "backupthis <filename>"
backupthis() {
	cp -riv $1 ${1}-$(date +%Y%m%d%H%M).backup;
}

# Let FZF use ripgrep by default
if type rg &> /dev/null; then
  export FZF_DEFAULT_COMMAND='rg --files'
  export FZF_DEFAULT_OPTS='-m --height 50% --border'
fi
# Setup fzf
# ---------
if [[ ! "$PATH" == */root/.local/share/nvim/plugged/fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/root/.local/share/nvim/plugged/fzf/bin"
fi

# Spawn a clone of current terminal 
putstate () {
    declare +x >~/environment.tmp
    declare -x >>~/environment.tmp
    echo cd "$PWD" >>~/environment.tmp
}

getstate () {
    . ~/environment.tmp
}

# cd using "up n" as a command up as many directories, example "up 3"
up() {
    # default parameter to 1 if non provided
    declare -i d=${@:-1}
    # ensure given parameter is non-negative. Print error and return if it is
    (( $d < 0 )) && (>&2 echo "up: Error: negative value provided") && return 1;
    # remove last d directories from pwd, append "/" in case result is empty
    cd "$(pwd | sed -E 's;(/[^/]*){0,'$d'}$;;')/";
}

# More history for cd and use "cd -TAB"
setopt AUTO_PUSHD                  # pushes the old directory onto the stack
zstyle ':completion:*:directory-stack' list-colors '=(#b) #([0-9]#)*( *)==95=38;5;12'

# List upto last 10 visited directories using "d" and quickly cd into any specific one
# using just a number from "0" to "9"
alias d="dirs -v | head -10" 
alias 0="cd +0"
alias 1="cd +1"
alias 2="cd +2"
alias 3="cd +3"
alias 4="cd +4"
alias 5="cd +5"
alias 6="cd +6"
alias 7="cd +7"
alias 8="cd +8"
alias 9="cd +9"

# Allow nnn filemanager to cd on quit
nnn() {
  declare -x +g NNN_TMPFILE=$(mktemp --tmpdir $0.XXXX)
  trap "rm -f $NNN_TMPFILE" EXIT
  =nnn $@
  [ -s $NNN_TMPFILE ] && source $NNN_TMPFILE
}

# Use lf to switch directories and bind it to ctrl-o
#lfcd () {
#	tmp="$(mktemp)"
#	lf -last-dir-path="$tmp" "$@"
#	if [ -f "$tmp" ]; then
#		dir="$(cat "$tmp")"
#		rm -f "$tmp" >/dev/null
#		[ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
#	fi
#}
#bindkey -s '^o' 'lfcd\n'
#bindkey -s '^a' 'bc -lq\n'
#bindkey -s '^f' 'cd "$(dirname "$(fzf)")"\n'

alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
alias vi='nvim'
alias nv='nvim'
alias trash="gio trash"
alias trash_restore='gio trash --restore "$(gio trash --list | fzf | cut -f 1)"'
alias ec='$EDITOR $HOME/.config/zsh/.zshrc'
alias sc="source $HOME/.zshrc"


##########    Source Plugins, should be last    ##########

# load zsh-vi-mode
#source /usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# Load zsh-syntax-highlighting
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

# Load fzf keybindings and completion
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh
source /usr/share/fzf-marks/fzf-marks.plugin.zsh 2>/dev/null

# Suggest aliases for commands
source /usr/share/zsh/plugins/zsh-you-should-use/you-should-use.plugin.zsh 2>/dev/null

# Load fish like auto suggestions
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
