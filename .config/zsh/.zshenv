
#export XINITRC="$HOME/.config/X11/.xinitrc"
#export INPUTRC="${XDG_CONFIG_HOME:-$HOME/.config}/X11/.inputrc"
#export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
#export XAUTHORITY="$XDG_RUNTIME_DIR/.Xauthority" # This line will break some DMs.
#export XINITRC="$XDG_CONFIG_HOME"/X11/xinitrc
#export XAUTHORITY="$XDG_RUNTIME_DIR"/Xauthority

# Path
#export PATH="$PATH:${$(find ~/.local/bin ~/.local/share/npm/bin -type d -printf %p:)%%:}"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local:$HOME/.local/bin:$HOME/.local/bin/scripts:$HOME/Scripts:$HOME/.local/bin/statusbar


# Default Programs:
export EDITOR="nvim"
export VISUAL="nvim"
export READER="zathura"
export TERMINAL="alacritty"
export COLORTERM="truecolor"
export TERM="xterm-256color"
export BROWSER="firefox"
export OPENER="xdg-open"
export PAGER="less"
export WM="bspwm"
export XDG_SESSION_TYPE=X11

# XDG Paths:
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:="$HOME/.config"}
#export XDG_DATA_HOME=${XDG_DATA_HOME:="$HOME/.local/share"}
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME=${XDG_CACHE_HOME:="$HOME/.cache"}
export XINITRC="$HOME/.config/X11/.xinitrc"
export INPUTRC="${XDG_CONFIG_HOME:-$HOME/.config}/X11/.inputrc"
export ICEAUTHORITY="$XDG_CACHE_HOME"/.ICEauthority
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

# Other XDG Paths:
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
export NVM_DIR="$XDG_DATA_HOME"/nvm
export NODE_REPL_HISTORY="$XDG_DATA_HOME"/node_repl_history
export ASPROOT="${XDG_CACHE_HOME:-$HOME/.cache}/asp"
# fixing paths
export XSERVERRC="$XDG_CONFIG_HOME"/X11/xserverrc
#export GEM_PATH="$XDG_DATA_HOME/ruby/gems"
#export GEM_SPEC_CACHE="$XDG_DATA_HOME/ruby/specs"
#export GEM_HOME="$XDG_DATA_HOME/ruby/gems"
#export GOPATH="$XDG_DATA_HOME"/go
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
#export CARGO_HOME="$XDG_DATA_HOME"/cargo
#export PATH=$CARGO_HOME/bin:$PATH
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"
#export WORKON_HOME="$XDG_DATA_HOME"/virtualenvs
export WGETRC="$XDG_CONFIG_HOME"/wget/wgetrc
export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker
export IPYTHONDIR="$XDG_CONFIG_HOME"/jupyter, export JUPYTER_CONFIG_DIR="$XDG_CONFIG_HOME"/jupyter
export CARGO_HOME=$HOME/.cargo
export PATH="$HOME/.cargo/bin:$PATH"
#export RUSTUP_HOME=$HOME/.cargo/bin
## RUST
#typeset -U path
#path+=(~/.cargo/bin)
#export RUST_SRC_PATH=$(rustc --print sysroot)/lib/rustlib/src/rust/src
#export RUST_SRC_PATH=$HOME/.rustup/toolchains/nightly-x86_64-apple-darwin/lib/rustlib/src/rust/src
#export GOPATH=$HOME/go
#export GORACE=''
#export KINDLEGEN_HOME=/Users/adben/Downloads/KindleGen_Mac_i386_v2_9
#export GOROOT=$GO_HOME
#export PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
#export PATH=$PATH:$HOME/.local/bin # for stack - haskell
#export PATH=$PATH:/usr/local/lib/ruby/gems/2.6.0/bin

# xsession start script

#export USERXSESSION="$XDG_CONFIG_HOME/X11/xsession"
#export USERXSESSIONRC="$XDG_CONFIG_HOME/X11/xsessionrc"
#export ALTUSERXSESSION="$XDG_CONFIG_HOME/X11/Xsession"
#export ERRFILE="$XDG_CONFIG_HOME/X11/xsession-errors"

# Doesn't seem to work
#export ANDROID_SDK_HOME="$XDG_CONFIG_HOME"/android
#export ANDROID_AVD_HOME="$XDG_DATA_HOME"/android
#export ANDROID_EMULATOR_HOME="$XDG_DATA_HOME"/android
#export ADB_VENDOR_KEY="$XDG_CONFIG_HOME"/android
# Disable files
#export LESSHISTFILE=-


# Program settings
#export MOZ_USE_XINPUT2="1"		# Mozilla smooth scrolling/touchpads.


#export tmux.conf=XDG_CONFIG_HOME/tmux/tmux.conf
#export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
#export GOPATH="${XDG_DATA_HOME:-$HOME/.local/share}/go"
# Scaling
#export QT_AUTO_SCREEN_SCALE_FACTOR=0
#export QT_SCALE_FACTOR=1
#export QT_SCREEN_SCALE_FACTORS="1;1;1"
#export GDK_SCALE=1
#export GDK_DPI_SCALE=1


#export VIDEO="mpv"
#export IMAGE="sxiv"

#xbindkeys -f "$XDG_CONFIG_HOME"/xbindkeys/config
# Path
#path=("$HOME/scripts" "$HOME/scripts/alsa" "$HOME/scripts/dragon" "$HOME/scripts/lf" "$HOME/scripts/i3" "$HOME/scripts/pulse"
#	"$HOME/scripts/polybar" "$HOME/scripts/bspwm" "$HOME/scripts/lemonbar" "$HOME/scripts/transmission"
#	"$HOME/bin/tweetdeck-linux-x64" "$XDG_DATA_HOME/ruby/gems/bin" "$HOME/go/bin" "$HOME/.local/share/cargo/bin"
#	"$XDG_DATA_HOME/npm/bin" "$HOME/.local/bin" "$path[@]")
#export PATH

#typeset -U PATH path
export GTK_IM_MODULE='fcitx'
export QT_IM_MODULE='fcitx'
export SDL_IM_MODULE='fcitx'
export XMODIFIERS='@im=fcitx'




# Start blinking
#export LESS_TERMCAP_mb=$(tput bold; tput setaf 2) # green
# Start bold
#export LESS_TERMCAP_md=$(tput bold; tput setaf 2) # green
# Start stand out
#export LESS_TERMCAP_so=$(tput bold; tput setaf 3) # yellow
# End standout
#export LESS_TERMCAP_se=$(tput rmso; tput sgr0)
# Start underline
#export LESS_TERMCAP_us=$(tput smul; tput bold; tput setaf 1) # red
# End Underline
#export LESS_TERMCAP_ue=$(tput sgr0)
# End bold, blinking, standout, underline
#export LESS_TERMCAP_me=$(tput sgr0).
#. "/home/sxrdusr/.local/share/cargo/env"
. "$HOME/.cargo/env"
