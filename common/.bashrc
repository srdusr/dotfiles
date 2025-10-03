# shellcheck shell=bash
#
#██████╗  █████╗ ███████╗██╗  ██╗██████╗  ██████╗
#██╔══██╗██╔══██╗██╔════╝██║  ██║██╔══██╗██╔════╝
#██████╔╝███████║███████╗███████║██████╔╝██║
#██╔══██╗██╔══██║╚════██║██╔══██║██╔══██╗██║
#██████╔╝██║  ██║███████║██║  ██║██║  ██║╚██████╗
#╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝
#
# ~/.bashrc
#

if [[ $- != *i* ]]; then
  . ~/.profile
  return
fi

# If not running interactively, dont do anything
[[ $- != *i* ]] && return

# Get the current active terminal
term="$(cat /proc/"$PPID"/comm)"

##########    Prompt    ##########

# ------------------------
# Prompt Colors & Variables
# ------------------------
RESET="\[\033[0m\]"
BOLD="\[\033[1m\]"
BLINK="\[\033[5m\]"

FG_USER="\[\033[38;5;82m\]"      # bright green
FG_HOST="\[\033[38;5;45m\]"      # cyan/blue
FG_DIR="\[\033[38;5;214m\]"      # orange
FG_PROMPT="\[\033[38;5;220m\]"   # yellow
FG_BORDER="\[\033[37m\]"         # light gray

USER_NAME="${USER}"
HOST_NAME="$(hostname -s)"
DISTRO="$(. /etc/os-release && echo $ID)" 2>/dev/null || DISTRO="$HOST_NAME"

# ------------------------
# Git bare-dotfiles environment
# ------------------------
set_git_env_vars() {
    [[ -d "$HOME/.cfg" ]] || return
    git --git-dir="$HOME/.cfg" rev-parse --is-bare-repository &>/dev/null || return

    # Only set env vars if not inside another Git repo
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        export GIT_DIR="$HOME/.cfg"
        export GIT_WORK_TREE="$HOME"
    else
        unset GIT_DIR
        unset GIT_WORK_TREE
    fi
}

# Update git env on directory change
if [ -n "$BASH_VERSION" ]; then
    PROMPT_COMMAND="set_git_env_vars; $PROMPT_COMMAND"
fi
set_git_env_vars

# ------------------------
# Git branch info
# ------------------------
git_branch() {
    # Only inside a git repo
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local branch
        branch=$(git symbolic-ref --short HEAD 2>/dev/null)
        # Check for uncommitted changes
        local status=""
        if [[ -n $(git status --porcelain) ]]; then
            status="*"
        fi
        echo "(${branch}${status})"
    fi
}

# ------------------------
# Prompt with git info
# ------------------------
PS1_FUNC() {
    local git_info
    git_info=$(git_branch)
    # Blank line before prompt
    echo

    PS1="${FG_BORDER}${BOLD}┌─[${FG_USER}${USER_NAME}${FG_BORDER}]"
    PS1+=" ${FG_HOST}${DISTRO}${FG_BORDER}"
    PS1+=" ${FG_DIR}\W${FG_BORDER}"
    # Git info right after path
    [[ -n "$git_info" ]] && PS1+=" ${FG_PROMPT}${git_info}${FG_BORDER}"
    PS1+="\n${FG_BORDER}└──[${FG_PROMPT}${BLINK}\$${RESET}${FG_BORDER}]${RESET}"
    export PS1
}

# Make PS1 dynamic each time
PROMPT_COMMAND="PS1_FUNC; $PROMPT_COMMAND"

# ------------------------
# Optional: git subtree helper
# ------------------------
gsp() {
    local GIT_SUBTREE_FILE="$PWD/.gitsubtrees"
    [[ -f "$GIT_SUBTREE_FILE" ]] || { echo "No .gitsubtrees file."; return; }

    while IFS= read -r LINE; do
        [[ $LINE =~ ^# ]] && continue
        IFS=';' read -r PREFIX REMOTE BRANCH <<< "$LINE"
        echo "Pulling subtree $PREFIX from $REMOTE $BRANCH..."
        git subtree pull --prefix="$PREFIX" "$REMOTE" "$BRANCH"
    done < "$GIT_SUBTREE_FILE"
}

##########    Bindings    ##########

bind -m vi-command 'Control-l: clear-screen'
bind -m vi-insert 'Control-l: clear-screen'


##########    Env/exports    ##########

export PROMPT_COMMAND="resize &>/dev/null ; $PROMPT_COMMAND"

# XDG Base Directories
#--------------------------------------
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

export INPUTRC="$XDG_CONFIG_HOME/inputrc"

# PATH Setup
#--------------------------------------
# Base user paths
export PATH="$HOME/.bin:$HOME/.local/bin:$HOME/.scripts:/usr/local/bin:/sbin:/usr/sbin:$PATH"

# Termux (Android)
if [ -d "/data/data/com.termux/files/usr/local/bin" ]; then
    export PATH="/data/data/com.termux/files/usr/local/bin:$PATH"
fi

# cmake
if [ -x "/usr/bin/cmake" ]; then
    export PATH="/usr/bin/cmake:$PATH"
fi

# Chrome
if [ -d "/opt/google/chrome" ]; then
    export PATH="$PATH:/opt/google/chrome"
fi

# Homebrew (macOS / Linux)
if [ -d "/opt/homebrew/bin" ]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

# Nix profile
if [ -d "$HOME/.nix-profile/bin" ]; then
    export PATH="$HOME/.nix-profile/bin:$PATH"
fi

# Add ~/.scripts (excluding some dirs)
#--------------------------------------
EXCLUDE_DIRS=(".git" "assets" "test")
if [ -d "$HOME/.scripts" ]; then
    while IFS= read -r -d '' dir; do
        rel_path="${dir#$HOME/.scripts/}"
        skip=false
        for exclude in "${EXCLUDE_DIRS[@]}"; do
            [[ "$rel_path" == "$exclude"* ]] && skip=true && break
        done
        [ "$skip" = false ] && PATH="$dir:$PATH"
    done < <(find "$HOME/.scripts" -type d -print0)
fi

# Terminal
#--------------------------------------
export TERM="xterm-256color"
export COLORTERM="truecolor"

# Choose default terminal
for term in wezterm kitty alacritty xterm; do
    if command -v "$term" &>/dev/null; then
        export TERMINAL="$term"
        break
    fi
done

# Default Programs
#--------------------------------------
export EDITOR="$(command -v nvim || command -v vim || echo nano)"
export TEXEDIT="$EDITOR"
export FCEDIT="$EDITOR"
export VISUAL="$EDITOR"
export GIT_EDITOR="$EDITOR"

export READER="zathura"
export BROWSER="firefox"
export OPENER="xdg-open"
export VIDEO="mpv"
export IMAGE="phototonic"

# Man pager
if command -v nvim &>/dev/null; then
    export MANPAGER="sh -c 'col -b | nvim -c \"set ft=man ts=8 nomod nolist nonu noma\" -c \"autocmd VimEnter * call feedkeys(\\\"\\<CR>q\\\")\" -'"
else
    export MANPAGER="bat"
fi
export MANROFFOPT="-c"
export PAGER="less"

# Shell History
#--------------------------------------
export HISTSIZE=1000000
export SAVEHIST=1000000

# Colors
#--------------------------------------
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd

# less colors
export LESS_TERMCAP_mb=$(tput bold; tput setaf 2) # green
export LESS_TERMCAP_md=$(tput bold; tput setaf 2) # green
export LESS_TERMCAP_so=$(tput bold; tput setaf 3) # yellow
export LESS_TERMCAP_se=$(tput rmso; tput sgr0)
export LESS_TERMCAP_us=$(tput smul; tput bold; tput setaf 1) # red
export LESS_TERMCAP_ue=$(tput sgr0)
export LESS_TERMCAP_me=$(tput sgr0)

# Miscellaneous XDG-aware configs
#--------------------------------------
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export VSCODE_PORTABLE="$XDG_DATA_HOME/vscode"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export DISCORD_USER_DATA_DIR="$XDG_DATA_HOME"
export LYNX_CFG="$XDG_CONFIG_HOME/.lynxrc"

# Languages / SDKs
#--------------------------------------
# Rust
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export PATH="$CARGO_HOME/bin:$RUSTUP_HOME/bin:$PATH"
command -v rustc &>/dev/null && export RUST_BACKTRACE=1

# Dotnet
export DOTNET_HOME="$XDG_DATA_HOME/dotnet"
export DOTNET_CLI_HOME="$XDG_CONFIG_HOME/dotnet"
export PATH="$DOTNET_HOME/tools:$PATH"
export DOTNET_ROOT="/opt/dotnet"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# Java
export JAVA_HOME="/usr/lib/jvm/java-20-openjdk"
export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java"

# Dart / Flutter
if [ -d "/opt/flutter/bin" ]; then
    export PATH="/opt/flutter/bin:/usr/lib/dart/bin:$PATH"
fi

# Go
export GOPATH="$XDG_DATA_HOME/go"

# Node / NVM
export NVM_DIR="$XDG_CONFIG_HOME/nvm"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

[[ -d "$XDG_DATA_HOME/node/bin" ]] && PATH="$XDG_DATA_HOME/node/bin:$PATH"
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Ruby
export GEM_HOME="$XDG_DATA_HOME/ruby/gems"
export GEM_PATH="$GEM_HOME"
export GEM_SPEC_CACHE="$XDG_DATA_HOME/ruby/specs"

# Python
if command -v virtualenvwrapper.sh >/dev/null 2>&1; then
    export WORKON_HOME="$HOME/.virtualenvs"
    export VIRTUALENVWRAPPER_PYTHON="$(command -v python3)"
    export VIRTUALENVWRAPPER_VIRTUALENV="$(command -v virtualenv)"
    source "$(command -v virtualenvwrapper.sh)"
fi
export VIRTUAL_ENV_DISABLE_PROMPT=false
export JUPYTER_CONFIG_DIR="$XDG_CONFIG_HOME/jupyter"
export IPYTHONDIR="$XDG_CONFIG_HOME/jupyter"

[[ "$(uname)" == "Darwin" ]] && export PYTHON_CONFIGURE_OPTS="--enable-framework"
[[ "$(uname)" == "Linux" ]] && export PYTHON_CONFIGURE_OPTS="--enable-shared"

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# PHP
export PATH="$HOME/.config/composer/vendor/bin:$PATH"

# Lua
if [ -d "/usr/local/luarocks/bin" ]; then
    export PATH="$PATH:/usr/local/luarocks/bin"
fi

# Android SDK
#--------------------------------------
if [ -d "/opt/android-sdk" ]; then
    export ANDROID_HOME="/opt/android-sdk"
    export ANDROID_SDK_ROOT="/opt/android-sdk"
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
    export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH"
    export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
fi

# Misc
#--------------------------------------
export NVIM_TUI_ENABLE_TRUE_COLOR=1
export GPG_TTY="$(tty)"
export XDG_MENU_PREFIX="gnome-"
export DEVELOPMENT_DIRECTORY="$HOME/code"
export PKG_CONFIG_PATH="/usr/local/lib64/pkgconfig:$PKG_CONFIG_PATH"

# FZF + rg
if command -v rg &>/dev/null; then
    export FZF_DEFAULT_COMMAND="rg --files --hidden --glob '!{node_modules/*,.git/*}'"
    export FZF_DEFAULT_OPTS='-m --height 50% --border'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

##########    Aliases    ##########

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

# suffix aliases | commented out invalid bash syntax
#alias -g CP='| xclip -selection clipboard -rmlastnl'
#alias -g LL="| less exit 2>1 /dev/null"
#alias -g CA="| cat -A"
#alias -g KE="2>&1"
#alias -g NE="2>/dev/null"
#alias -g NUL=">/dev/null 2>&1"

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
alias batt='upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "state|to full|percentage"'
alias emerge-fetch='sudo tail -f /var/log/emerge-fetch.log'
alias spotify="env LD_PRELOAD=/usr/local/lib/spotify-adblock.so spotify %U"

alias proofread='firejail --private --private-tmp --net=none --seccomp --caps.drop=all zathura'

# NVM
if [ -s "$NVM_DIR/nvm.sh" ]; then
    nvm_cmds=(nvm node npm yarn)
    for cmd in "${nvm_cmds[@]}"; do
        alias "$cmd"="unalias ${nvm_cmds[*]} && unset nvm_cmds && . $NVM_DIR/nvm.sh && $cmd"
    done
fi

# Kubernetes
if command -v kubectl > /dev/null; then
    replaceNS() { kubectl config view --minify --flatten --context=$(kubectl config current-context) | yq ".contexts[0].context.namespace=\"$1\"" ; }
    alias kks='KUBECONFIG=<(replaceNS "kube-system") kubectl'
    alias kam='KUBECONFIG=<(replaceNS "authzed-monitoring") kubectl'
    alias kas='KUBECONFIG=<(replaceNS "authzed-system") kubectl'
    alias kar='KUBECONFIG=<(replaceNS "authzed-region") kubectl'
    alias kt='KUBECONFIG=<(replaceNS "tenant") kubectl'

    if command -v kubectl-krew > /dev/null; then
        path=($XDG_CONFIG_HOME/krew/bin $path)
    fi

    rmfinalizers() {
        kubectl get deployment "$1" -o json | jq '.metadata.finalizers = null' | kubectl apply -f -
    }
fi

# Castero
castero() {
    if [[ -f ~/.local/share/venv/bin/activate ]]; then
        . ~/.local/share/venv/bin/activate
    fi
    command castero "$@"
}

# Zoxide (cd alternative)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi


##########    Functions    ##########

# Dotfiles Management System
if [[ -d "$HOME/.cfg" && -d "$HOME/.cfg/refs" ]]; then
    # Core git wrapper - .cfg is bare repo, work-tree points to .cfg itself
    _config() {
        git --git-dir="$HOME/.cfg" --work-tree="$HOME/.cfg" "$@"
    }

    # Detect OS
    case "$(uname -s)" in
        Linux)   CFG_OS="linux" ;;
        Darwin)  CFG_OS="macos" ;;
        MINGW*|MSYS*|CYGWIN*) CFG_OS="windows" ;;
        *)       CFG_OS="other" ;;
    esac

    _repo_path() {
        local f="$1"

        # Normalize absolute or relative
        if [[ "$f" == "$HOME/"* ]]; then
            f="${f#$HOME/}"
        elif [[ "$f" == "./"* ]]; then
            f="${f#./}"
        fi

        # Already tracked? Use that
        local dirs=("common/" "$CFG_OS/home/" "$CFG_OS/Users/")
        for d in "${dirs[@]}"; do
            local match="$(_config ls-files --full-name | grep -F "/$f" | grep -F "$d" || true)"
            if [[ -n "$match" ]]; then
                echo "$match"
                return
            fi
        done

        # Already a special repo path
        case "$f" in
            common/*|"$CFG_OS/home/"*|"$CFG_OS/Users/"*|profile/*|README.md)
                echo "$f"
                return
                ;;
        esac

        # Map everything else dynamically
        case "$f" in
            *)
                case "$CFG_OS" in
                    linux)   echo "linux/home/$f" ;;
                    macos)   echo "macos/Users/$f" ;;
                    windows) echo "windows/Users/$f" ;;
                    *)       echo "$CFG_OS/home/$f" ;;
                esac
                ;;
        esac
    }

    _sys_path() {
        local repo_path="$1"

        # System HOME
        local sys_home
        case "$CFG_OS" in
            linux|macos) sys_home="$HOME" ;;
            windows)     sys_home="$USERPROFILE" ;;
        esac

        # Repo HOME roots
        local repo_home
        case "$CFG_OS" in
            linux)   repo_home="linux/home" ;;
            macos)   repo_home="macos/Users" ;;
            windows) repo_home="windows/Users" ;;
        esac

        case "$repo_path" in
            # Common files → $HOME/… but normalize well-known dirs
            common/*)
                local rel="${repo_path#common/}"

                case "$rel" in
                    # XDG config
                    .config/*|config/*)
                        local sub="${rel#*.config/}"
                        sub="${sub#config/}"
                        echo "${XDG_CONFIG_HOME:-$sys_home/.config}/$sub"
                        ;;

                    # XDG data (assets, wallpapers, icons, fonts…)
                    assets/*|.local/share/*)
                        local sub="${rel#assets/}"
                        sub="${sub#.local/share/}"
                        echo "${XDG_DATA_HOME:-$sys_home/.local/share}/$sub"
                        ;;

                    # XDG cache (if you ever store cached scripts/config)
                    .cache/*)
                        local sub="${rel#.cache/}"
                        echo "${XDG_CACHE_HOME:-$sys_home/.cache}/$sub"
                        ;;

                    # Scripts
                    .scripts/*|scripts/*)
                        local sub="${rel#*.scripts/}"
                        sub="${sub#scripts/}"
                        echo "$sys_home/.scripts/$sub"
                        ;;

                    # Default: dump directly under $HOME
                    *)
                        echo "$sys_home/$rel"
                        ;;
                esac
                ;;

            # Profile files → $HOME/…
            profile/*)
                local rel="${repo_path#profile/}"
                echo "$sys_home/$rel"
                ;;

            # OS-specific home paths → $HOME or $USERPROFILE
            "$repo_home"/*)
                local rel="${repo_path#$repo_home/}"
                echo "$sys_home/$rel"
                ;;

            # OS-specific system paths outside home/Users → absolute
            "$CFG_OS/"*)
                local rel="${repo_path#$CFG_OS/}"
                echo "/$rel"
                ;;

            # Fallback: treat as repo-only
            *)
                echo "$HOME/.cfg/$repo_path"
                ;;
        esac
    }

    # Prompts for sudo if needed and runs the command
    _sudo_prompt() {
        if [[ $EUID -eq 0 ]]; then
            "$@"
        else
            if command -v sudo >/dev/null; then
                sudo "$@"
            elif command -v doas >/dev/null; then
                doas "$@"
            elif command -v pkexec >/dev/null; then
                pkexec "$@"
            else
                echo "Error: No privilege escalation tool found."
                return 1
            fi
        fi
    }

    # Main config command
    config() {
        local cmd="$1"; shift

        case "$cmd" in
            add)
                local file_path
                local git_opts=()
                local files=()
                local target_dir=""

                # Parse optional --target flag before files
                while [[ $# -gt 0 ]]; do
                    case "$1" in
                        --target|-t)
                            target_dir="$2"
                            shift 2
                            ;;
                        -*)  # any other git flags
                            git_opts+=("$1")
                            shift
                            ;;
                        *)  # files
                            files+=("$1")
                            shift
                            ;;
                    esac
                done

                for file_path in "${files[@]}"; do
                    # Store original for rel_path calculation
                    local original_path="$file_path"

                    # Make path absolute first
                    if [[ "$file_path" != /* && "$file_path" != "$HOME/"* ]]; then
                        file_path="$(pwd)/$file_path"
                    fi

                    # Check if file exists
                    if [[ ! -e "$file_path" ]]; then
                        echo "Error: File not found: $file_path"
                        continue
                    fi

                    # Calculate relative path from original input
                    local rel_path
                    if [[ "$original_path" == "$HOME/"* ]]; then
                        rel_path="${original_path#$HOME/}"
                    elif [[ "$original_path" == "./"* ]]; then
                        rel_path="${original_path#./}"
                    else
                        rel_path="$original_path"
                    fi

                    # Check if file is already tracked
                    local existing_path="$(_config ls-files --full-name | grep -Fx "$(_repo_path "$file_path")" || true)"
                    local repo_path
                    if [[ -n "$existing_path" ]]; then
                        repo_path="$existing_path"
                    elif [[ -n "$target_dir" ]]; then
                        repo_path="$target_dir/$rel_path"
                    else
                        repo_path="$(_repo_path "$file_path")"
                    fi

                    # Copy file into bare repo
                    local full_repo_path="$HOME/.cfg/$repo_path"
                    mkdir -p "$(dirname "$full_repo_path")"
                    cp -a "$file_path" "$full_repo_path"

                    # Add to git
                    _config add "${git_opts[@]}" "$repo_path"

                    echo "Added: $file_path -> $repo_path"
                done
                ;;

            rm)
                local rm_opts=""
                local file_path_list=()
                local target_dir=""

                # Parse options
                while [[ $# -gt 0 ]]; do
                    case "$1" in
                        --target|-t)
                            target_dir="$2"
                            shift 2
                            ;;
                        -*)
                            rm_opts+=" $1"
                            shift
                            ;;
                        *)
                            file_path_list+=("$1")
                            shift
                            ;;
                    esac
                done

                for file_path in "${file_path_list[@]}"; do
                    local repo_path
                    # Check if already a repo path (exists in git index) - exact match
                    if _config ls-files --full-name | grep -qFx "$file_path"; then
                        repo_path="$file_path"
                    elif [[ -n "$target_dir" ]]; then
                        # Use target directory if specified
                        local rel_path
                        if [[ "$file_path" == "$HOME/"* ]]; then
                            rel_path="${file_path#$HOME/}"
                        else
                            rel_path="${file_path#./}"
                        fi
                        repo_path="$target_dir/$rel_path"
                    else
                        repo_path="$(_repo_path "$file_path")"
                    fi

                    if [[ "$rm_opts" == *"-r"* ]]; then
                        _config rm --cached -r "$repo_path"
                    else
                        _config rm --cached "$repo_path"
                    fi

                    # Compute system path for actual file removal
                    local sys_file="$(_sys_path "$repo_path")"
                    if [[ -e "$sys_file" ]]; then
                        eval "rm $rm_opts \"$sys_file\""
                    fi
                    echo "Removed: $repo_path"
                done
                ;;

            sync)
                local direction="${1:-to-repo}"; shift
                _config ls-files | while read -r repo_file; do
                    local sys_file="$(_sys_path "$repo_file")"
                    local full_repo_path="$HOME/.cfg/$repo_file"

                    if [[ "$direction" == "to-repo" ]]; then
                        if [[ -e "$sys_file" && -n "$(diff "$full_repo_path" "$sys_file" 2>/dev/null || echo "diff")" ]]; then
                            cp -a "$sys_file" "$full_repo_path"
                            echo "Synced to repo: $sys_file"
                        fi
                    elif [[ "$direction" == "from-repo" ]]; then
                        if [[ -e "$full_repo_path" && -n "$(diff "$full_repo_path" "$sys_file" 2>/dev/null || echo "diff")" ]]; then
                            local dest_dir="$(dirname "$sys_file")"
                            if [[ "$sys_file" == /* && "$sys_file" != "$HOME/"* ]]; then
                                _sudo_prompt mkdir -p "$dest_dir"
                                _sudo_prompt cp -a "$full_repo_path" "$sys_file"
                            else
                                mkdir -p "$dest_dir"
                                cp -a "$full_repo_path" "$sys_file"
                            fi
                            echo "Synced from repo: $sys_file"
                        fi
                    fi
                done
                ;;

            status)
                local modified_files=()
                local missing_files=()

                # Colors like git
                local RED="\033[31m"
                local GREEN="\033[32m"
                local YELLOW="\033[33m"
                local BLUE="\033[34m"
                local BOLD="\033[1m"
                local RESET="\033[0m"

                while read -r repo_file; do
                    local sys_file="$(_sys_path "$repo_file")"
                    local full_repo_path="$HOME/.cfg/$repo_file"

                    if [[ ! -e "$full_repo_path" ]]; then
                        missing_files+=("$repo_file")
                    elif [[ -e "$sys_file" ]]; then
                        if ! diff -q "$full_repo_path" "$sys_file" >/dev/null 2>&1; then
                            modified_files+=("$repo_file")
                        fi
                    fi
                done < <(_config ls-files)

                # Report missing files
                if [[ ${#missing_files[@]} -gt 0 ]]; then
                    echo -e "${BOLD}${RED}=== Missing Files (consider removing from git) ===${RESET}"
                    for repo_file in "${missing_files[@]}"; do
                        echo -e " ${RED}deleted:${RESET}   $(_sys_path "$repo_file") -> $repo_file"
                    done
                    echo
                fi

                # Report modified files
                if [[ ${#modified_files[@]} -gt 0 ]]; then
                    echo -e "${BOLD}${YELLOW}=== Modified Files (different from system) ===${RESET}"
                    for repo_file in "${modified_files[@]}"; do
                        echo -e " ${YELLOW}modified:${RESET}  $(_sys_path "$repo_file") -> $repo_file"
                    done
                    echo
                fi

                # Finally, show underlying git status (with colors)
                _config -c color.status=always status
                ;;

            deploy|checkout)
                echo "Deploying dotfiles from .cfg..."
                _config ls-files | while read -r repo_file; do
                    local full_repo_path="$HOME/.cfg/$repo_file"
                    local sys_file="$(_sys_path "$repo_file")"

                    # Only continue if the source exists
                    if [[ -e "$full_repo_path" && -n "$sys_file" ]]; then
                        local dest_dir
                        dest_dir="$(dirname "$sys_file")"

                        # Create destination if needed
                        if [[ "$sys_file" == /* && "$sys_file" != "$HOME/"* ]]; then
                            _sudo_prompt mkdir -p "$dest_dir"
                            _sudo_prompt cp -a "$full_repo_path" "$sys_file"
                        else
                            mkdir -p "$dest_dir"
                            cp -a "$full_repo_path" "$sys_file"
                        fi

                        echo "Deployed: $repo_file -> $sys_file"
                    fi
                done
                ;;

            backup)
                local timestamp=$(date +%Y%m%d%H%M%S)
                local backup_dir="$HOME/.dotfiles_backup/$timestamp"
                echo "Backing up existing dotfiles to $backup_dir..."

                _config ls-files | while read -r repo_file; do
                    local sys_file="$(_sys_path "$repo_file")"
                    if [[ -e "$sys_file" ]]; then
                        local dest_dir_full="$backup_dir/$(dirname "$repo_file")"
                        mkdir -p "$dest_dir_full"
                        cp -a "$sys_file" "$backup_dir/$repo_file"
                    fi
                done
                echo "Backup complete. To restore, copy files from $backup_dir to their original locations."
                ;;

            *)
                _config "$cmd" "$@"
                ;;
        esac
    }
fi

# Make SUDO_ASKPASS agnostic: pick the first available askpass binary.
# You can predefine SUDO_ASKPASS env var to force a particular path.
: "${SUDO_ASKPASS:=""}"

# list of common askpass binaries (order: preferred -> fallback)
_askpass_candidates=(
  "$SUDO_ASKPASS"                   # user-specified (if absolute path)
  "/usr/lib/ssh/x11-ssh-askpass"
  "/usr/libexec/openssh/ssh-askpass"
  "/usr/lib/ssh/ssh-askpass"
  "/usr/bin/ssh-askpass"
  "/usr/bin/ssh-askpass-gtk"
  "/usr/bin/ssh-askpass-gnome"
  "/usr/bin/ssh-askpass-qt"
  "/usr/bin/ksshaskpass"
  "/usr/bin/zenity"                 # use zenity --entry as wrapper (see below)
  "/usr/bin/mate-ssh-askpass"
  "/usr/bin/xdg-open"               # last-resort GUI helper (not ideal)
)

find_askpass() {
  for p in "${_askpass_candidates[@]}"; do
    [ -z "$p" ] && continue
    # if user gave a path in SUDO_ASKPASS we accept it only if it's executable
    if [ -n "$SUDO_ASKPASS" ] && [ "$p" = "$SUDO_ASKPASS" ]; then
      [ -x "$p" ] && { printf '%s\n' "$p"; return 0; }
      continue
    fi

    # if candidate is an absolute path, test directly
    if [ "${p#/}" != "$p" ]; then
      [ -x "$p" ] && { printf '%s\n' "$p"; return 0; }
      continue
    fi

    # otherwise try to resolve via PATH
    if command -v "$p" >/dev/null 2>&1; then
      # For zenity, we will use a small wrapper (see below)
      printf '%s\n' "$(command -v "$p")"
      return 0
    fi
  done

  return 1
}

# If zenity is chosen, use a thin wrapper script so sudo -A can call it like an askpass binary.
# This wrapper will be created in $XDG_RUNTIME_DIR or /tmp (non-persistent).
create_zenity_wrapper() {
  local wrapper
  wrapper="${XDG_RUNTIME_DIR:-/tmp}/.sudo_askpass_zenity.sh"
  cat >"$wrapper" <<'EOF'
#!/bin/sh
# simple zenity askpass wrapper for sudo
# prints password to stdout so sudo -A works
zenity --entry --title="Authentication" --text="Elevated privileges are required" --hide-text 2>/dev/null || exit 1
EOF
  chmod 700 "$wrapper"
  printf '%s\n' "$wrapper"
}

# Set askpass
if [ -z "$SUDO_ASKPASS" ]; then
  candidate="$(find_askpass || true)"
  if [ -n "$candidate" ]; then
    if command -v zenity >/dev/null 2>&1 && [ "$(command -v zenity)" = "$candidate" ]; then
      # create the wrapper and export it
      wrapper="$(create_zenity_wrapper)"
      export SUDO_ASKPASS="$wrapper"
    else
      export SUDO_ASKPASS="$candidate"
    fi
  else
    # optional: leave unset or set to empty to avoid mistakes
    unset SUDO_ASKPASS
  fi
fi
# debug: (uncomment to print what was chosen)
# printf 'SUDO_ASKPASS -> %s\n' "${SUDO_ASKPASS:-<none>}"


# Git
# No arguments: `git status`
# With arguments: acts like `git`
g() {
    if [ $# -gt 0 ]; then
        git "$@"           # Pass arguments to git
    else
        git status         # Default to `git status`
    fi
}

# Optional: enable bash completion for `g` like git
if type complete &>/dev/null; then
    complete -o default -o nospace -F _git g
fi

ga() { g add "$@"; }
gaw() { g add -A && g diff --cached -w | g apply --cached -R; }
grm() { g rm "$@"; }
gb() { g branch "$@"; }
gbl() { g branch -l "$@"; }
gbD() { g branch -D "$@"; }
gbu() { g branch -u "$@"; }
ge() { g clone "$@"; }
gc() { g commit "$@"; }
gcm() { g commit -m "$@"; }
gca() { g commit -a "$@"; }
gcaa() { g commit -a --amend "$@"; }
gcam() { g commit -a -m "$@"; }
gce() { g commit -e "$@"; }
gcfu() { g commit --fixup "$@"; }
gco() { g checkout "$@"; }
gcob() { g checkout -b "$@"; }
gcoB() { g checkout -B "$@"; }
gcp() { g cherry-pick "$@"; }
gcpc() { g cherry-pick --continue "$@"; }
gd() { g diff "$@"; }
gds() { g diff --staged "$@"; }
gdc() { g diff --cached "$@"; }
gl() { g lg "$@"; }  # Assuming you have `lg` configured as alias/log format
glg() { g log --graph --decorate --all "$@"; }
gls() {
    query="$1"
    shift
    glog --pickaxe-regex "-S$query" "$@"
}
gu() { g pull "$@"; }
gp() { g push "$@"; }
gpom() { g push origin main "$@"; }
gr() { g remote "$@"; }
gra() { g rebase --abort "$@"; }
grb() { g rebase --committer-date-is-author-date "$@"; }
grbom() { grb --onto master "$@"; }
grbasi() { g rebase --autosquash --interactive "$@"; }
grc() { g rebase --continue "$@"; }
grs() { g restore --staged "$@"; }
grv() { g remote -v "$@"; }
grh() { g reset --hard "$@"; }
grH() { g reset HEAD "$@"; }
gs() { g status -sb "$@"; }
gsd() { g stash drop "$@"; }
gsl() { g stash list --date=relative "$@"; }
gsp() { g stash pop "$@"; }
gss() { g stash show "$@"; }
gst() { g status "$@"; }
gsu() { g standup "$@"; } # Custom command
gforgotrecursive() { g submodule update --init --recursive --remote "$@"; }
gfp() { g commit --amend --no-edit && g push --force-with-lease "$@"; }

# Enter directory and list contents
function cd-clear-ls() {
    if [ -n "$1" ]; then
        builtin cd "$@" 2>/dev/null || { echo "cd: no such file or directory: $1"; return 1; }
    else
        builtin cd ~ || return 1
    fi

    echo -e "\033[H\033[J"  # Clear screen but keep scroll buffer

    if [ "$PWD" != "$HOME" ] && git rev-parse --is-inside-work-tree &>/dev/null; then
        ls -a
    else
        ls
    fi
}
