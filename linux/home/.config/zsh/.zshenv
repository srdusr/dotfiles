# Load local/system wide binaries and scripts
export PATH=$HOME/.bin:$HOME/.local/bin:$HOME/.scripts:$HOME/.scripts/test:/usr/local/bin:/sbin:/usr/sbin:$PATH
export PATH="/data/data/com.termux/files/usr/local/bin:$PATH"

if [ -d "$HOME/.scripts" ]; then
    for d in "$HOME/.scripts"/*; do
        [ -d "$d" ] && PATH="$PATH:$d"
    done
fi

#export PATH

export TERM=xterm-256color
# Skip the not really helpful global compinit
skip_global_compinit=1

#export WINEARCH=win64 #<or win32>
#export WINEPREFIX=~/.wine
#export PATH=$PATH:/usr/bin/wine
#winetricks vcrun2019
### Conditionally set WM(window manager)
#available_wms=("bspwm" "mutter" "i3")
#for wm in "${available_wms[@]}"; do
#    if command -v "$wm" &> /dev/null; then
#        export WM="$wm"
#        break
#    fi
#done

## Set a flag to indicate if the display server type is found
#display_server_found=0
#
## Conditionally set Display server
#available_displays=("wayland" "x11")
#for display in "${available_displays[@]}"; do
#    if [ "$WAYLAND_DISPLAY" = "$display" ]; then
#        export XDG_SESSION_TYPE="$display"
#        display_server_found=1
#        break
#    fi
#done
#
## Check if XDG_SESSION_TYPE is "x11" and set X11-specific variables
#if [ "$display_server_found" -eq 1 ] && [ "$XDG_SESSION_TYPE" == "x11" ]; then
#    # X11-specific variables
#    export XINITRC="$HOME/.config/X11/.xinitrc"
#    export XSERVERRC="$XDG_CONFIG_HOME/X11/xserverrc"
#    export USERXSESSION="$XDG_CONFIG_HOME/X11/xsession"
#    export USERXSESSIONRC="$XDG_CONFIG_HOME/X11/xsessionrc"
#    export ALTUSERXSESSION="$XDG_CONFIG_HOME/X11/Xsession"
#    export ERRFILE="$XDG_CONFIG_HOME/X11/xsession-errors"
#    export ICEAUTHORITY="$XDG_CACHE_HOME/.ICEauthority"
#fi

# Conditionally set default term
available_terms=("wezterm" "alacritty" "xterm")
for term in "${available_terms[@]}"; do
    if command -v "$term" &> /dev/null; then
        export TERMINAL="$term"
        break
    fi
done

# Default Programs:
export EDITOR=$(command -v nvim || echo "vim")
#if command -v nvim &> /dev/null; then
#  export EDITOR=nvim
#else
#  export EDITOR=vim
#fi
export VISUAL=$EDITOR
export GIT_EDITOR="$EDITOR"
export COLORTERM="truecolor"
export TERM="xterm-256color"
export READER="zathura"
export BROWSER="firefox"
export OPENER="xdg-open"
#export MANPAGER="$EDITOR +Man!"
#if [ "$EDITOR" = "nvim" ]; then
if command -v nvim &> /dev/null; then
    #export MANPAGER="sh -c 'col -b | nvim -c \"set ft=man ts=8 nomod nolist nonu noma\" -c \"autocmd VimEnter * call feedkeys(\\\"q\\\")\" -'"
    export MANPAGER="sh -c 'col -b | nvim -c \"set ft=man ts=8 nomod nolist nonu noma\" -c \"autocmd VimEnter * call feedkeys(\\\"\\<CR>q\\\")\" -'"
    #export MANPAGER="$nvim --clean -n -i NONE -u NORC -c 'colorscheme desert' -c 'highlight Normal ctermbg=NONE guibg=NONE' +Man\!"
else
    export MANPAGER="bat"
    #export MANPAGER="less -R --use-color -Dd+r -Du+b"
    #export MANPAGER="sh -c 'col -bx | bat -l man -p --pager \"less -R\"'"
fi
export MANROFFOPT="-c"
export PAGER="less"
export SUDO_ASKPASS=/usr/lib/ssh/x11-ssh-askpass
export FAQ_STYLE='github'
export VIDEO="mpv"
export IMAGE="phototonic"

# XDG Paths:
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export INPUTRC="${XDG_CONFIG_HOME:-$HOME/.config}/inputrc"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export HISTFILE="$ZDOTDIR/.zhistory"    # History filepath
export HISTSIZE=1000000                  # Maximum events for internal history
export SAVEHIST=1000000                   # Maximum events in history file
export BANG_HIST                 # Treat the '!' character specially during expansion.
export EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
export INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
export SHARE_HISTORY             # Share history between all sessions.
export HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
export HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
export HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
export HIST_FIND_NO_DUPS         # Do not display a line previously found.
export HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
export HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
export HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
export HIST_VERIFY               # Don't execute immediately upon history expansion.
export HIST_BEEP                 # Beep when accessing nonexistent history.
export INC_APPEND_HISTORY

# Customize `ls` colours
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd

# Other XDG paths:
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export VSCODE_PORTABLE="$XDG_DATA_HOME/vscode"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export PATH="/usr/bin/cmake:$PATH"
export PATH=$PATH:/opt/google/chrome
export DISCORD_USER_DATA_DIR="$XDG_DATA_HOME"
export LYNX_CFG="$XDG_CONFIG_HOME/.lynxrc"

# Manage Arch linux build sources
export ASPROOT="${XDG_CACHE_HOME:-$HOME/.cache}/asp"

# Homebrew
#export PATH=/opt/homebrew/bin:$PATH
export PATH="/opt/homebrew/sbin:$PATH"

# Nix-profile
export PATH=$HOME/.nix-profile/bin:$PATH

# GnuPG
export GPG_TTY=$(tty)
#export GNUPGHOME="$XDG_CONFIG_HOME/gnupg"

# Nvim
export NVIM_TUI_ENABLE_TRUE_COLOR=1

# Fzf
export FZF_DEFAULT_COMMAND="rg --files --hidden --glob '!{node_modules/*,.git/*}'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='-m --height 50% --border'


# enable git scripts
export DEVELOPMENT_DIRECTORY="$HOME/code"

# Android Home
export ANDROID_HOME=/opt/android-sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
#export PATH=$ANDROID_HOME/cmdline-tools/bin:$PATH
export PATH=$ANDROID_HOME/tools:$PATH
export PATH=$ANDROID_HOME/tools/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH
# Android emulator PATH
export PATH=$ANDROID_HOME/emulator:$PATH
# Android SDK ROOT PATH
export ANDROID_SDK_ROOT=/opt/android-sdk
export PATH=$ANDROID_SDK_ROOT:$PATH
#export ANDROID_SDK_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/android"

# Programming Environment Variables:

# Rust
export RUSTUP_HOME=${XDG_DATA_HOME:-$HOME/.local/share}/rustup
export CARGO_HOME=${XDG_DATA_HOME:-$HOME/.local/share}/cargo
export PATH="${CARGO_HOME}/bin:${RUSTUP_HOME}/bin:$PATH"
#export PATH="$PATH:$CARGO_HOME/bin"
#[[ -d $CARGO_HOME/bin ]] && path=($CARGO_HOME/bin $path)
if which rustc > /dev/null; then export RUST_BACKTRACE=1; fi
#export PATH="$HOME/.cargo/bin:$PATH"
#export CARGO_HOME=${XDG_DATA_HOME}/cargo
#export RUSTUP_HOME=${XDG_DATA_HOME}/rustup


# Dotnet
# # Currently dotnet does not support XDG ( https://github.com/dotnet/sdk/issues/10390 )
#export DOTNET_TOOLS_DIR="$HOME/.dotnet/tools"
export DOTNET_HOME=${XDG_DATA_HOME:-$HOME/.local/share}/dotnet
export DOTNET_CLI_HOME="$XDG_CONFIG_HOME/dotnet"
#mkdir -p "$DOTNET_CLI_HOME";
export PATH="$PATH":"$DOTNET_HOME"/tools
export DOTNET_ROOT=/opt/dotnet
# Disable telemetry for dotnet apps
export DOTNET_CLI_TELEMETRY_OPTOUT=1


# Java
#export JAVA_HOME=/usr/lib/jvm/default-java
#export JAVA_HOME='/usr/lib/jvm/java-8-openjdk'
#export JAVA_HOME='/usr/lib/jvm/java-10-openjdk'
#export JAVA_HOME='/usr/lib/jvm/java-11-openjdk'
#export JAVA_HOME='/usr/lib/jvm/java-17-openjdk'
export JAVA_HOME='/usr/lib/jvm/java-20-openjdk'
#export PATH=$JAVA_HOME/bin:$PATH
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java
#export DEFAULT_JVM_OPTS='"-Dcom.android.sdklib.toolsdir=$APP_HOME" -XX:+IgnoreUnrecognizedVMOptions'
#export _JAVA_AWT_WM_NONREPARENTING=1
#export JAVA_OPTS='-XX:+IgnoreUnrecognizedVMOptions --add-modules java.se.ee'
#export JAVA_OPTS='-XX:+IgnoreUnrecognizedVMOptions --add-modules java.xml.bind'
#Windows:
#set JAVA_OPTS=-XX:+IgnoreUnrecognizedVMOptions --add-modules java.se.ee


# Dart/Flutter
export PATH="/opt/flutter/bin:/usr/lib/dart/bin:$PATH"


# Go
export GO_PATH=${XDG_DATA_HOME}/go
export GOPATH="${XDG_DATA_HOME:-$HOME/.local/share}/go"


# Javascript
# NVM
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# global node installs (gross)
[[ -d "$XDG_DATA_HOME/node/bin" ]] && path=($XDG_DATA_HOME/node/bin $path)
export NODE_REPL_HISTORY="$XDG_DATA_HOME"/node_repl_history
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
#export NPM_CONFIG_INIT_AUTHOR_NAME='srdusr'
#export NPM_CONFIG_INIT_AUTHOR_EMAIL='trevorgray@srdusr.com'
#export NPM_CONFIG_INIT_AUTHOR_URL='https://srdusr.com'
#export NPM_CONFIG_INIT_LICENSE='GPL-3.0'
#export NPM_CONFIG_INIT_VERSION='0.0.0'
#export NPM_CONFIG_SIGN_GIT_TAG='true'

# Yarn
#if command -v yarn >/dev/null 2>&1; then
#    export PATH="$PATH:`yarn global bin`"
#fi
#export PATH="$(yarn global bin):$PATH"
#YARN_PATH="$HOME/.yarn/bin"
#YARN_BIN_EXPORT="$HOME/.config/yarn/global/node_modules/.bin"

# Ruby
export GEM_PATH="$XDG_DATA_HOME/ruby/gems"
export GEM_SPEC_CACHE="$XDG_DATA_HOME/ruby/specs"
export GEM_HOME="$XDG_DATA_HOME/ruby/gems"
#if [[ -d ~/.gem/ruby ]]; then
#	ver=$(find ~/.gem/ruby/* -maxdepth 0 | sort -rV | head -n 1)
#	export PATH="$PATH:${ver}/bin"
#fi


# Python
# lazy load pyenv
#export PYENV_ROOT=${PYENV_ROOT:-$HOME/.pyenv}
#[[ -a $PYENV_ROOT/bin/pyenv ]] && path=($PYENV_ROOT/bin $path)
#if type pyenv &> /dev/null || [[ -a $PYENV_ROOT/bin/pyenv ]]; then
#  function pyenv() {
#    unset pyenv
#    path=($PYENV_ROOT/shims $path)
#    eval "$(command pyenv init -)"
#    if which pyenv-virtualenv-init > /dev/null; then
#      eval "$(pyenv virtualenv-init -)"
#      export PYENV_VIRTUALENV_DISABLE_PROMPT=1
#    fi
#    pyenv $@
#  }
#fi
#export WORKON_HOME="$XDG_DATA_HOME/virtualenvs"
export WORKON_HOME=$HOME/.virtualenvs
export VIRTUALENVWRAPPER_PYTHON=`which python3`
export VIRTUALENVWRAPPER_VIRTUALENV=`which virtualenv`
#source /usr/local/bin/virtualenvwrapper.sh
source $(which virtualenvwrapper.sh)
export VIRTUAL_ENV_DISABLE_PROMPT=false
export JUPYTER_CONFIG_DIR="$XDG_CONFIG_HOME/jupyter"
export IPYTHONDIR="$XDG_CONFIG_HOME/jupyter"

# Python
[[ "$(uname)" == "Darwin" ]] && export PYTHON_CONFIGURE_OPTS="--enable-framework"
[[ "$(uname)" == "Linux" ]] && export PYTHON_CONFIGURE_OPTS="--enable-shared"

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# PHP
PATH="$HOME/.config/composer/vendor/bin:$PATH"


# Lua
export PATH=$PATH:/usr/local/luarocks/bin
#export PATH="$XDG_DATA_HOME/luarocks/bin:$PATH"

#ver=$(find lua* -maxdepth 0 | sort -rV | head -n 1)
#export LUA_PATH="$LUA_PATH:${ver}/share/lua/5.1/?.lua;${ver}/share/lua/5.1/?/init.lua;;"
#export LUA_CPATH="$LUA_CPATH:${ver}/lib/lua/5.1/?.so;;"

#LUAROCKS_PREFIX=/usr/local
#export LUA_PATH="$LUAROCKS_PREFIX/share/lua/5.1/?.lua;$LUAROCKS_PREFIX/share/lua/5.1/?/init.lua;;"
#export LUA_CPATH="$LUAROCKS_PREFIX/lib/lua/5.1/?.so;;"

#export LUA_PATH="<path-to-add>;;"
#export LUA_CPATH="./?.so;/usr/local/lib/lua/5.3/?.so;
#                /usr/local/share/lua/5.3/?.so;<path-to-add>"


# Program settings
#export MOZ_USE_XINPUT2="1"		# Mozilla smooth scrolling/touchpads.
# Pixel-perfect Firefox touchpad scrolling
export MOZ_USE_XINPUT2=1


# Scaling
#export QT_AUTO_SCREEN_SCALE_FACTOR=0
#export QT_SCALE_FACTOR=1
#export QT_SCREEN_SCALE_FACTORS="1;1;1"
#export GDK_SCALE=1
#export GDK_DPI_SCALE=1


#typeset -U PATH path
export GTK_IM_MODULE='fcitx'
export QT_IM_MODULE='fcitx'
export SDL_IM_MODULE='fcitx'
export XMODIFIERS='@im=fcitx'


# Start blinking
export LESS_TERMCAP_mb=$(tput bold; tput setaf 2) # green
# Start bold
export LESS_TERMCAP_md=$(tput bold; tput setaf 2) # green
# Start stand out
export LESS_TERMCAP_so=$(tput bold; tput setaf 3) # yellow
# End standout
export LESS_TERMCAP_se=$(tput rmso; tput sgr0)
# Start underline
export LESS_TERMCAP_us=$(tput smul; tput bold; tput setaf 1) # red
# End Underline
export LESS_TERMCAP_ue=$(tput sgr0)
# End bold, blinking, standout, underline
export LESS_TERMCAP_me=$(tput sgr0).
