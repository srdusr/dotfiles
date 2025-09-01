##########    Aliases    ##########

### Dotfiles
#if [[ -d "$HOME/.cfg" && -d "$HOME/.cfg/refs" ]]; then
#    # normal bare repo alias
#    #alias _config='git --git-dir=$HOME/.cfg --work-tree=$HOME'
#
#    _config() {
#        git --git-dir="$HOME/.cfg" --work-tree="$HOME" "$@"
#    }
#
#    config() {
#        if [ "$1" = "add" ]; then
#            shift
#            for f in "$@"; do
#                case "$(uname -s)" in
#                    Linux)
#                        _config add -- "linux/home/$f"
#                        ;;
#                    Darwin)
#                        _config add -- "macos/home/$f"
#                        ;;
#                    MINGW*|MSYS*|CYGWIN*)
#                        _config add -- "windows/Documents/$f"
#                        ;;
#                    *)
#                        _config add -- "$f"
#                        ;;
#                esac
#            done
#        else
#            _config "$@"
#        fi
#    }
#
#    cfg_files=$(_config ls-tree --name-only -r HEAD 2>/dev/null)
#    export CFG_FILES="$cfg_files"
#fi

## Only run if bare repo exists
#if [[ -d "$HOME/.cfg" && -d "$HOME/.cfg/refs" ]]; then
#
#    # raw bare-repo command
#    _config() {
#        git --git-dir="$HOME/.cfg" --work-tree="$HOME" "$@"
#    }
#
#    # helper to map paths to OS-specific directories
#
#    _os_path() {
#        local f="$1"
#        # if user already gave a path with prefix, just return it unchanged
#        case "$f" in
#            linux/*|macos/*|windows/*|common/*|profile/*)
#                echo "$f"
#                return
#                ;;
#        esac
#
#        # otherwise map according to OS
#        case "$(uname -s)" in
#            Linux)   echo "linux/home/$f" ;;
#            Darwin)  echo "macos/home/$f" ;;
#            MINGW*|MSYS*|CYGWIN*) echo "windows/Documents/$f" ;;
#            *)       echo "$f" ;;
#        esac
#    }
#
#    # wrapper
#    config() {
#        if [ "$1" = "add" ]; then
#            shift
#            for f in "$@"; do
#                case "$(uname -s)" in
#                    Linux)
#                        case "$f" in
#                            /*)  # absolute path
#                                rel="${f#$HOME/}"    # strip leading /home/username/
#                                if [[ "$rel" = "$f" ]]; then
#                                    # wasn't under $HOME, just strip /
#                                    rel="${f#/}"
#                                    _config add -- "linux/$rel"
#                                else
#                                    _config add -- "linux/home/$rel"
#                                fi
#                                ;;
#                            *)
#                                _config add -- "linux/home/$f"
#                                ;;
#                        esac
#                        ;;
#                    Darwin)
#                        case "$f" in
#                            /*)
#                                rel="${f#/}"
#                                _config add -- "macos/$rel"
#                                ;;
#                            *)
#                                _config add -- "macos/home/$f"
#                                ;;
#                        esac
#                        ;;
#                    MINGW*|MSYS*|CYGWIN*)
#                        case "$f" in
#                            /*)
#                                rel="${f#/}"
#                                _config add -- "windows/$rel"
#                                ;;
#                            *)
#                                _config add -- "windows/Documents/$f"
#                                ;;
#                        esac
#                        ;;
#                    *)
#                        _config add -- "$f"
#                        ;;
#                esac
#            done
#        else
#            _config "$@"
#        fi
#    }
#
#    # export tracked files if needed
#    cfg_files=$(_config ls-tree --name-only -r HEAD 2>/dev/null)
#    export CFG_FILES="$cfg_files"
#fi

# Define alias for nvim/vim (fallback to vim)
if command -v nvim > /dev/null; then
    alias vi='nvim'
else
    alias vi='vim'
fi

#alias vv='$(history -p !vim)'
alias vv="vim -c 'norm! ^O'"

# Confirmation #
alias mv='mv -i'
alias cp='cp -i'
alias ln='ln -i'

# Disable 'rm'
#alias rm='function _rm() { echo -e "\033[0;31mrm\033[0m is disabled, use \033[0;32mtrash\033[0m or \033[0;32mdel \033[0m\033[0;33m$1\033[0m"; }; _rm'
#alias del='/bin/rm'

# Use lsd for ls if available
if command -v lsd >/dev/null 2>&1; then
    alias ls='lsd --color=auto --group-directories-first'
fi
#alias ls='lsd --all --color=auto --group-directories-first'
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
alias -g LL="| less exit 2>1 /dev/null"
alias -g CA="| cat -A"
alias -g KE="2>&1"
alias -g NE="2>/dev/null"
alias -g NUL=">/dev/null 2>&1"

alias grep='grep --color=auto --exclude-dir={.git,.svn,.hg}'
alias egrep='egrep --color=auto --exclude-dir={.git,.svn,.hg}'
alias egrep='fgrep --color=auto --exclude-dir={.git,.svn,.hg}'

#alias hist="grep '$1' $HISTFILE"
alias hist="history | grep $1"


alias gdb='gdb -q'
alias rust-gdb='rust-gdb -q'

alias cd="cd-clear-ls"
alias clear='newline_clear'

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
alias :q='exit 2>1 /dev/null'
alias disk-destroyer='$(command -v dd)'
alias dd='echo "Warning use command: disk-destroyer"'
alias sc="systemctl"
alias jc="journalctl"
alias jck="journalctl -k" # Kernel
alias jce='sudo journalctl -b --priority 0..3' # error
alias journalctl-error='sudo journalctl -b --priority 0..3'
alias jcssh="sudo journalctl -u sshd"
alias tunnel='ssh -fNTL'
# tty aliases
#if [[ "$TERM" == 'linux' ]]; then
#    alias tmux='/usr/bin/tmux -L linux'
#fi
#alias logout="loginctl kill-user $(whoami)"

logout() {
    local wm
    wm="$(windowManagerName)"
    if [[ -n "$wm" ]]; then
        echo "Logging out by killing window manager: $wm"
        pkill "$wm"
    else
        echo "No window manager detected!" >&2
    fi
}
alias lg="logout"

#alias suspend='systemctl suspend && betterlockscreen -l' # Suspend(sleep) and lock screen if using systemctl
#alias suspend='systemctl suspend' # Suspend(sleep) and lock screen if using systemctl
alias suspend='loginctl suspend' # Suspend(sleep) and lock screen if using systemctl
#alias shutdown='loginctl poweroff' # Suspend(sleep) and lock screen if using systemctl
#alias shutdown='sudo /sbin/shutdown -h'
#alias poweroff='loginctl poweroff'
#alias reboot='loginctl reboot'
alias reboot='sudo reboot'
#alias hibernate='systemctl hibernate' # Hibernate
alias lock='DISPLAY=:0 xautolock -locknow' # Lock my workstation screen from my phone
alias oports="sudo lsof -i -P -n | grep -i 'listen'" # List open ports
alias keyname="xev | sed -n 's/[ ]*state.* \([^ ]*\)).*/\1/p'"
alias wget=wget --hsts-file="$XDG_CACHE_HOME/wget-hsts" # wget does not support environment variables
alias open="xdg-open"
alias pp='getlast 2>&1 |&tee -a output.txt'
#alias lg='la | grep'
alias pg='ps aux | grep'
alias py='python'
alias py3='python3'
alias activate='source ~/.local/share/venv/bin/activate'
alias sha256='shasum -a 256'
alias rgf='rg -F'
alias weather='curl wttr.in/durban'
alias diary='nvim "$HOME/documents/main/inbox/diary/$(date +'%Y-%m-%d').md"'
alias wifi='nmcli dev wifi show-password'
alias ddg='w3m lite.duckduckgo.com'
alias rss='newsboat'
alias vpn='protonvpn'
alias yt-dl="yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4' --restrict-filename"
#alias com.obsproject.Studio="obs"
#alias obs="com.obsproject.Studio"
#alias obs-stuido="obs"

# Time aliases
alias utc='TZ=Africa/Johannesburg date'
alias ber='TZ=Europe/Berlin date'
alias nyc='TZ=America/New_York date'
alias sfo='TZ=America/Los_Angeles date'
alias utc='TZ=Etc/UTC date'

alias src='source $ZDOTDIR/.zshrc'
alias p=proxy

alias cheat='~/.scripts/cheat.sh ~/documents/notes/cheatsheets'
alias crypto='curl -s rate.sx | head -n -2 | tail -n +10'
#alias todo='glow "$HOME"/documents/main/notes/TODO.md'

alias todo='$EDITOR "$(find "$HOME"/documents/main -type f -iname "todo.md" | head -n 1)"'
alias android-studio='/opt/android-studio/bin/studio.sh' # android-studio
alias nomachine='/usr/NX/bin/nxplayer' # nomachine
alias firefox="firefox-bin"
alias discord="vesktop-bin"
alias fetch="fastfetch"
#alias land="env GDK_BACKEND=wayland $HOME/.local/bin/land"
#alias land="env env WAYLAND_DISPLAY=wayland-1 $HOME/.local/bin/land"
alias bat='upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "state|to full|percentage"'
alias emerge-fetch='sudo tail -f /var/log/emerge-fetch.log'
#alias spotify="env LD_PRELOAD=/usr/lib64/spotify-adblock.so spotify %U"
#Exec=env LD_PRELOAD=/usr/lib64/spotify-adblock.so spotify %U
alias spotify="env LD_PRELOAD=/usr/local/lib/spotify-adblock.so spotify %U"
#alias spotify='LD_PRELOAD=/usr/lib/spotify-adblock.so /bin/spotify %U'

alias proofread='firejail --private --private-tmp --net=none --seccomp --caps.drop=all zathura'

