##########    Aliases    ##########

### Dotfiles
alias config='git --git-dir=$HOME/.cfg --work-tree=$HOME'
cfg_files=$(config ls-tree --name-only -r HEAD)

export CFG_FILES="$cfg_files"

# Define alias for nvim/vim (fallback to vim)
if command -v nvim > /dev/null; then
    alias vi='nvim'
else
    alias vi='vim'
fi

# Confirmation #
alias mv='mv -i'
alias cp='cp -i'
alias ln='ln -i'

# Disable 'rm'
alias rm='function _rm() { echo -e "\033[0;31mrm\033[0m is disabled, use \033[0;32mtrash\033[0m or \033[0;32mdel \033[0m\033[0;33m$1\033[0m"; }; _rm'
alias del='/bin/rm'

alias ls='lsd --color=auto --group-directories-first'
#alias ls="ls --color=auto --group-directories-first"

# ls variants
alias l='ls -FAh --group-directories-first'
alias la='ls -lAFh --group-directories-first'
alias lt='ls -lFAht --group-directories-first'
alias lr='ls -RFAh --group-directories-first'

# more ls variants
alias ldot='ls -ld .* --group-directories-first'
alias lS='ls -1FASsh --group-directories-first'
alias lart='ls -1Fcart --group-directories-first'
alias lrt='ls -1Fcrt --group-directories-first'

# ls with different alphabethical sorting
#unalias ll
#ll() { LC_COLLATE=C ls "$@" }

# suffix aliases
alias -g CP='| xclip -selection clipboard -rmlastnl'
alias -g LL="| less"
alias -g CA="| cat -A"
alias -g KE="2>&1"
alias -g NE="2>/dev/null"
alias -g NUL=">/dev/null 2>&1"

alias grep='grep --color=auto --exclude-dir={.git,.svn,.hg}'
alias egrep='egrep --color=auto --exclude-dir={.git,.svn,.hg}'
alias egrep='fgrep --color=auto --exclude-dir={.git,.svn,.hg}'

alias gdb='gdb -q'
alias rust-gdb='rust-gdb -q'

# List upto last 10 visited directories using "d" and quickly cd into any specific one
alias d="dirs -v | head -10"

# Using just a number from "0" to "9"
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

alias sudo='sudo ' # zsh: elligible for alias expansion/fix syntax highlight
alias sedit='sudoedit'
#alias se='sudoedit'
alias se='sudo -e'
alias :q='exit'
alias sc="systemctl"
alias jc="journalctl"
alias jck="journalctl -k" # Kernel
alias jce='sudo journalctl -b --priority 0..3' # error
alias journalctl-error='sudo journalctl -b --priority 0..3'
alias jcssh="sudo journalctl -u sshd"
alias tunnel='ssh -fNTL'
# tty aliases
if [[ "$TERM" == 'linux' ]]; then
    alias tmux='/usr/bin/tmux -L linux'
fi
alias logout="loginctl kill-user $(whoami)"

#alias suspend='systemctl suspend && betterlockscreen -l' # Suspend(sleep) and lock screen if using systemctl
alias suspend='systemctl suspend' # Suspend(sleep) and lock screen if using systemctl
alias hibernate='systemctl hibernate' # Hibernate
alias lock='DISPLAY=:0 xautolock -locknow' # Lock my workstation screen from my phone
alias oports="sudo lsof -i -P -n | grep -i 'listen'" # List open ports
alias keyname="xev | sed -n 's/[ ]*state.* \([^ ]*\)).*/\1/p'"
alias wget=wget --hsts-file="$XDG_CACHE_HOME/wget-hsts" # wget does not support environment variables
alias pp='getlast 2>&1 |&tee -a output.txt'
alias lg='la | grep'
alias pg='ps aux | grep'
alias py='python'
alias py3='python3'
alias sha256='shasum -a 256'
alias rgf='rg -F'
alias weather='curl wttr.in/durban'
alias wifi='nmcli dev wifi show-password'
alias ddg='w3m lite.duckduckgo.com'
alias rss='newsboat'
alias vpn='protonvpn'
alias yt-dl="yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4' --restrict-filename"

# Time aliases
alias utc='TZ=Africa/Johannesburg date'
alias ber='TZ=Europe/Berlin date'
alias nyc='TZ=America/New_York date'
alias sfo='TZ=America/Los_Angeles date'
alias utc='TZ=Etc/UTC date'

alias src='source ~/.zshrc'
alias p=proxy

alias cheat='~/.scripts/cheat.sh ~/documents/notes/cheatsheets'
alias crypto='curl -s rate.sx | head -n -2 | tail -n +10'
alias todo='glow "$HOME"/media/notes/_TODO.md'

alias android-studio='/opt/android-studio/bin/studio.sh' # android-studio
alias nomachine='/usr/NX/bin/nxplayer' # nomachine
alias spotify='LD_PRELOAD=/usr/lib/spotify-adblock.so /bin/spotify %U'
