# Source .profile if not already sourced
if [ -z "$PROFILE_SOURCED" ]; then
    [ -f "$HOME/.profile" ] && source "$HOME/.profile"
    export PROFILE_SOURCED=1
fi

#######################################
# XDG Base Directories
#######################################
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

export INPUTRC="$XDG_CONFIG_HOME/inputrc"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

#######################################
# PATH Setup
#######################################
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

#######################################
# Add ~/.scripts (excluding some dirs)
#######################################
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

#######################################
# Terminal
#######################################
export TERM="xterm-256color"
export COLORTERM="truecolor"

# Choose default terminal
for term in wezterm kitty alacritty xterm; do
    if command -v "$term" &>/dev/null; then
        export TERMINAL="$term"
        break
    fi
done

#######################################
# Default Programs
#######################################
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

#######################################
# Shell History
#######################################
export HISTFILE="$ZDOTDIR/.zhistory"
export HISTSIZE=1000000
export SAVEHIST=1000000
setopt BANG_HIST EXTENDED_HISTORY INC_APPEND_HISTORY SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS HIST_IGNORE_SPACE HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS HIST_VERIFY HIST_BEEP

#######################################
# Colors
#######################################
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd

# less colors
export LESS_TERMCAP_mb=$(tput bold; tput setaf 2) # green
export LESS_TERMCAP_md=$(tput bold; tput setaf 2) # green
export LESS_TERMCAP_so=$(tput bold; tput setaf 3) # yellow
export LESS_TERMCAP_se=$(tput rmso; tput sgr0)
export LESS_TERMCAP_us=$(tput smul; tput bold; tput setaf 1) # red
export LESS_TERMCAP_ue=$(tput sgr0)
export LESS_TERMCAP_me=$(tput sgr0)

#######################################
# Miscellaneous XDG-aware configs
#######################################
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export VSCODE_PORTABLE="$XDG_DATA_HOME/vscode"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export DISCORD_USER_DATA_DIR="$XDG_DATA_HOME"
export LYNX_CFG="$XDG_CONFIG_HOME/.lynxrc"

#######################################
# Languages / SDKs
#######################################

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

#######################################
# Android SDK
#######################################
if [ -d "/opt/android-sdk" ]; then
    export ANDROID_HOME="/opt/android-sdk"
    export ANDROID_SDK_ROOT="/opt/android-sdk"
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
    export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH"
    export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
fi

#######################################
# Misc
#######################################
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

# Zoxide
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

#######################################
# Cleanup PATH (remove duplicates)
#######################################
typeset -U PATH path
