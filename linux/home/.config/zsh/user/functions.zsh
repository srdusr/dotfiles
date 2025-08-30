## Function to temporarily unset GIT_WORK_TREE
function git_without_work_tree() {
    # Only proceed if a git command is being run
    if [ "$1" = "git" ]; then
        shift
        # Check if the current directory is inside a Git work tree
        if git rev-parse --is-inside-work-tree &>/dev/null; then
            # If inside a work tree, temporarily unset GIT_WORK_TREE
            GIT_WORK_TREE_OLD="$GIT_WORK_TREE"
            unset GIT_WORK_TREE
            git "$@"
            export GIT_WORK_TREE="$GIT_WORK_TREE_OLD"
        else
            # If not inside a work tree, call git command directly
            git "$@"
        fi
    else
        # If it's not a git command, just execute it normally
        command "$@"
    fi
}

# Set alias conditionally
alias git='git_without_work_tree git'

# Set bare dotfiles repository git environment variables dynamically
function set_git_env_vars() {
    # Check if the current command is a package manager command
    if [[ "${(%)${(z)history[1]}}" =~ ^(pacman|yay|apt|dnf|brew|npm|pip|gem|go|cargo) ]]; then
        return
    fi
    local git_dir="$(git rev-parse --git-dir -C . 2>/dev/null)"
    if [[ -n "$git_dir" ]]; then
        local is_bare="$(git -C "$git_dir" rev-parse --is-bare-repository 2>/dev/null)"
        if [[ "$is_bare" == "true" ]]; then
            export GIT_DIR="$HOME/.cfg"
            export GIT_WORK_TREE=$(realpath $(eval echo ~))
        else
            unset GIT_DIR
            unset GIT_WORK_TREE
        fi
    else
        local root_dir="$(git rev-parse --show-toplevel 2>/dev/null)"
        if [[ -n "$root_dir" ]]; then
            unset GIT_DIR
            export GIT_WORK_TREE="$root_dir"
        else
            export GIT_DIR="$HOME/.cfg"
            export GIT_WORK_TREE=$(realpath $(eval echo ~))
        fi
    fi
}

# Define an auto_cd hook to automatically update Git environment variables
#function chpwd() {
#    set_git_env_vars
#}
# Call the function to set Git environment variables when the shell starts up
set_git_env_vars


function gsp() {
    # Config file for subtrees
    #
    # Format:
    # <prefix>;<remote address>;<remote branch>
    # # Lines starting with '#' will be ignored
    GIT_SUBTREE_FILE="$PWD/.gitsubtrees"

    if [ ! -f "$GIT_SUBTREE_FILE" ]; then
        echo "Nothing to do - file <$GIT_SUBTREE_FILE> does not exist."
        return
    fi

    if ! command -v config &> /dev/null; then
        echo "Error: 'config' command not found. Make sure it's available in your PATH."
        return
    fi

    OLD_IFS=$IFS
    IFS=$'\n'
    for LINE in $(cat "$GIT_SUBTREE_FILE"); do

        # Skip lines starting with '#'.
        if [[ $LINE = \#* ]]; then
            continue
        fi

        # Parse the current line.
        PREFIX=$(echo "$LINE" | cut -d';' -f 1)
        REMOTE=$(echo "$LINE" | cut -d';' -f 2)
        BRANCH=$(echo "$LINE" | cut -d';' -f 3)

        # Pull from the remote.
        echo "Executing: git subtree pull --prefix=$PREFIX $REMOTE $BRANCH"
        if git subtree pull --prefix="$PREFIX" "$REMOTE" "$BRANCH"; then
            echo "Subtree pull successful for $PREFIX."
        else
            echo "Error: Subtree pull failed for $PREFIX."
        fi
    done

    IFS=$OLD_IFS
}

# Print previous command into a file
getlast () {
    fc -nl $((HISTCMD - 1))
}

# Enter directory and list contents
#cd() { builtin cd $@ && lsd }
cd() {
    if [ -n "$1" ]; then
        builtin cd "$@" && ls
    else
        builtin cd ~ && ls
    fi
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

# cd into $XDG_CONFIG_HOME/$1 directory
c() {
    local root=${XDG_CONFIG_HOME:-~/.config}
    local dname="$root/$1"
    if [[ ! -d "$dname" ]]; then
        return
    fi
    cd "$dname"
}

# Make and cd into directory and any parent directories
mkcd () {
    if [[ -z "$1" ]]; then
        echo "Usage: mkcd <dir>" 1>&2
        return 1
    fi
    mkdir -p "$1"
    cd "$1"
}

bak() {
    if [[ -e "$1" ]]; then
        echo "Found: $1"
        mv "${1%.*}"{,.bak}
    elif [[ -e "$1.bak" ]]; then
        echo "Found: $1.bak"
        mv "$1"{.bak,}
    fi
}

back() {
    for file in "$@"; do
        cp -r "$file" "$file".bak
    done
}

# tre is a shorthand for tree
tre() {
    tree -aC -I \
        '.git|.hg|.svn|.tmux|.backup|.vim-backup|.swap|.vim-swap|.undo|.vim-undo|*.bak|tags' \
        --dirsfirst "$@" \
        | less
}

# switch from/to project/package dir
pkg() {
    if [ "$#" -eq 2 ]; then
        ln -s "$(readlink -f $1)" "$(readlink -f $2)"/._pkg
        ln -s "$(readlink -f $2)" "$(readlink -f $1)"/._pkg
    else
        cd "$(readlink -f ./._pkg)"
    fi
}

# Prepare C/C++ project for Language Server Protoco
lsp-prep() {
    (cd build && cmake .. -DCMAKE_EXPORT_COMPILE_COMMANDS=ON) \
        && ln -sf build/compile_commands.json
}

reposize() {
    url=`echo $1 \
        | perl -pe 's#(?:https?://github.com/)([\w\d.-]+\/[\w\d.-]+).*#\1#g' \
        | perl -pe 's#git\@github.com:([\w\d.-]+\/[\w\d.-]+)\.git#\1#g'
    `
    printf "https://github.com/$url => "
    curl -s https://api.github.com/repos/$url \
        | jq '.size' \
        | numfmt --to=iec --from-unit=1024
}

# Launch a program in a terminal without getting any output,
# and detache the process from terminal
# (can then close the terminal without terminating process)
-echo() {
    "$@" &> /dev/null & disown
}

# Reload shell
function reload() {
    local compdump_files="$ZDOTDIR/.zcompdump*"

    if ls $compdump_files &> /dev/null; then
        rm -f $compdump_files
    fi

    exec $SHELL -l
}

#pom() {
#    local -r HOURS=${1:?}
#    local -r MINUTES=${2:-0}
#    local -r POMODORO_DURATION=${3:-25}
#
#    bc <<< "(($HOURS * 60) + $MINUTES) / $POMODORO_DURATION"
#}

#mnt() {
#    local FILE="/mnt/external"
#    if [ ! -z $2 ]; then
#        FILE=$2
#    fi
#
#    if [ ! -z $1 ]; then
#        sudo mount "$1" "$FILE" -o rw
#        echo "Device in read/write mounted in $FILE"
#    fi
#
#    if [ $# = 0 ]; then
#        echo "You need to provide the device (/dev/sd*) - use lsblk"
#    fi
#}
#
#umnt() {
#    local DIRECTORY="/mnt"
#    if [ ! -z $1 ]; then
#        DIRECTORY=$1
#    fi
#    MOUNTED=$(grep $DIRECTORY /proc/mounts | cut -f2 -d" " | sort -r)
#    cd "/mnt"
#    sudo umount $MOUNTED
#    echo "$MOUNTED unmounted"
#}

mntmtp() {
    local DIRECTORY="$HOME/mnt"
    if [ ! -z $2 ]; then
        local DIRECTORY=$2
    fi
    if [ ! -d $DIRECTORY ]; then
        mkdir $DIRECTORY
    fi

    if [ ! -z $1 ]; then
        simple-mtpfs --device "$1" "$DIRECTORY"
        echo "MTPFS device in read/write mounted in $DIRECTORY"
    fi

    if [ $# = 0 ]; then
        echo "You need to provide the device number - use simple-mtpfs -l"
    fi
}

umntmtp() {
    local DIRECTORY="$HOME/mnt"
    if ; then
        DIRECTORY=$1
    fi
    cd $HOME
    umount $DIRECTORY
    echo "$DIRECTORY with mtp filesystem unmounted"
}
duckduckgo() {
    lynx -vikeys -accept_all_cookies "https://lite.duckduckgo.com/lite/?q=$@"
}

wikipedia() {
    lynx -vikeys -accept_all_cookies "https://en.wikipedia.org/wiki?search=$@"
}
#function filesize() {
#    # Check if 'du' supports the -b option, which provides sizes in bytes.
#    if du -b /dev/null > /dev/null 2>&1; then
#        local arg=-sbh;  # If supported, use -sbh options for 'du'.
#    else
#        local arg=-sh;   # If not supported, use -sh options for 'du'.
#    fi
#
#    # Check if no arguments are provided.
#    if [ "$#" -eq 0 ]; then
#        # Calculate and display sizes for all files and directories in cwd.
#        du $arg ./*
#    else
#        # Calculate and display sizes for the specified files and directories.
#        du $arg -- "$@"
#    fi
#}
#

fgl() {
    git log --graph --color=always \
        --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
    fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
        --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}

fgb() {
  local branches branch
  branches=$(git --no-pager branch -vv) &&
  branch=$(echo "$branches" | fzf +m) &&
  git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

# +--------+
# | Pacman |
# +--------+

# TODO can improve that with a bind to switch to what was installed
fpac() {
    pacman -Slq | fzf --multi --reverse --preview 'pacman -Si {1}' | xargs -ro sudo pacman -S
}

fyay() {
    yay -Slq | fzf --multi --reverse --preview 'yay -Si {1}' | xargs -ro yay -S
}

# +------+
# | tmux |
# +------+

fmux() {
    prj=$(find $XDG_CONFIG_HOME/tmuxp/ -execdir bash -c 'basename "${0%.*}"' {} ';' | sort | uniq | nl | fzf | cut -f 2)
    echo $prj
    [ -n "$prj" ] && tmuxp load $prj
}

# ftmuxp - propose every possible tmuxp session
ftmuxp() {
    if [[ -n $TMUX ]]; then
        return
    fi

    # get the IDs
    ID="$(ls $XDG_CONFIG_HOME/tmuxp | sed -e 's/\.yml$//')"
    if [[ -z "$ID" ]]; then
        tmux new-session
    fi

    create_new_session="Create New Session"

    ID="${create_new_session}\n$ID"
    ID="$(echo $ID | fzf | cut -d: -f1)"

    if [[ "$ID" = "${create_new_session}" ]]; then
        tmux new-session
    elif [[ -n "$ID" ]]; then
        # Change name of urxvt tab to session name
        printf '\033]777;tabbedx;set_tab_name;%s\007' "$ID"
        tmuxp load "$ID"
    fi
}

# ftmux - help you choose tmux sessions
ftmux() {
    if [[ ! -n $TMUX ]]; then
        # get the IDs
        ID="`tmux list-sessions`"
        if [[ -z "$ID" ]]; then
            tmux new-session
        fi
        create_new_session="Create New Session"
        ID="$ID\n${create_new_session}:"
        ID="`echo $ID | fzf | cut -d: -f1`"
        if [[ "$ID" = "${create_new_session}" ]]; then
            tmux new-session
        elif [[ -n "$ID" ]]; then
            printf '\033]777;tabbedx;set_tab_name;%s\007' "$ID"
            tmux attach-session -t "$ID"
        else
            :  # Start terminal normally
        fi
    fi
}

# +-------+
# | Other |
# +-------+

# List install files for dotfiles
fdot() {
    file=$(find "$DOTFILES/install" -exec basename {} ';' | sort | uniq | nl | fzf | cut -f 2)
    [ -n "$file" ] && "$EDITOR" "$DOTFILES/install/$file"
}

# List projects
fwork() {
    result=$(find ~/workspace/* -type d -prune -exec basename {} ';' | sort | uniq | nl | fzf | cut -f 2)
    [ -n "$result" ] && cd ~/workspace/$result
}

# Open pdf with Zathura
fpdf() {
    result=$(find -type f -name '*.pdf' | fzf --bind "ctrl-r:reload(find -type f -name '*.pdf')" --preview "pdftotext {} - | less")
    [ -n "$result" ] && nohup zathura "$result" &> /dev/null & disown
}

# Open epubs with Zathura
fepub() {
    result=$(find -type f -name '*.epub' | fzf --bind "ctrl-r:reload(find -type f -name '*.epub')")
    [ -n "$result" ] && nohup zathura "$result" &> /dev/null & disown
}

# Search and find directories in the dir stack
fpop() {
    # Only work with alias d defined as:

    # alias d='dirs -v'
    # for index ({1..9}) alias "$index"="cd +${index}"; unset index

    d | fzf --height="20%" | cut -f 1 | source /dev/stdin
}

#ip() {
#  emulate -LR zsh
#
#  if [[ $1 == 'get' ]]; then
#    res=$(curl -s ipinfo.io/ip)
#    echo -n $res | xsel --clipboard
#    echo "copied $res to clipboard"
#  # only run ip if it exists
#  elif (( $+commands[ip] )); then
#    command ip $*
#  fi
#}

ssh-create() {
    if [ ! -z "$1" ]; then
        ssh-keygen -f $HOME/.ssh/$1 -t rsa -N '' -C "$1"
        chmod 700 $HOME/.ssh/$1*
    fi
}

historystat() {
    history 0 | awk '{print $2}' | sort | uniq -c | sort -n -r | head
}

promptspeed() {
    for i in $(seq 1 10); do /usr/bin/time zsh -i -c exit; done
}

#matrix () {
#    local lines=$(tput lines)
#    cols=$(tput cols)
#
#    awkscript='
#    {
#        letters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*()"
#        lines=$1
#        random_col=$3
#        c=$4
#        letter=substr(letters,c,1)
#        cols[random_col]=0;
#        for (col in cols) {
#            line=cols[col];
#            cols[col]=cols[col]+1;
#            printf "\033[%s;%sH\033[2;32m%s", line, col, letter;
#            printf "\033[%s;%sH\033[1;37m%s\033[0;0H", cols[col], col, letter;
#            if (cols[col] >= lines) {
#                cols[col]=0;
#            }
#        }
#    }
#    '
#
#    echo -e "\e[1;40m"
#    clear
#
#    while :; do
#        echo $lines $cols $(( $RANDOM % $cols)) $(( $RANDOM % 72 ))
#        sleep 0.05
#    done | awk "$awkscript"
#}

matrix() {
    local lines=$(tput lines)
    cols=$(tput cols)

    # Check if tmux is available
    if command -v tmux > /dev/null; then
        # Save the current status setting
        local status_setting=$(tmux show -g -w -v status)

        # Turn off tmux status
        tmux set -g status off
    else
        echo "tmux is not available. Exiting."
        return 1
    fi

    # Function to restore terminal state
    restore_terminal() {
        # Clear the screen
        clear

        # Bring back tmux status to its original setting
        if command -v tmux > /dev/null; then
            tmux set -g status "$status_setting"
        fi
    }

    trap 'restore_terminal' INT

    awkscript='
    {
        letters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*()"
        lines=$1
        random_col=$3
        c=$4
        letter=substr(letters,c,1)
        cols[random_col]=0;
        for (col in cols) {
            line=cols[col];
            cols[col]=cols[col]+1;
            printf "\033[%s;%sH\033[2;32m%s", line, col, letter;
            printf "\033[%s;%sH\033[1;37m%s\033[0;0H", cols[col], col, letter;
            if (cols[col] >= lines) {
                cols[col]=0;
            }
        }
    }
    '

    echo -e "\e[1;40m"
    clear

    while :; do
        echo $lines $cols $(( $RANDOM % $cols)) $(( $RANDOM % 72 ))
        sleep 0.05
    done | awk "$awkscript"

    # Restore terminal state
    restore_terminal
}

## Reload shell
function reload() {
  local compdump_files="$ZDOTDIR/.zcompdump*"

  if ls $compdump_files &> /dev/null; then
      rm -f $compdump_files
  fi

  exec $SHELL -l
}
## Generate a secure password
function passgen() {
  LC_ALL=C tr -dc ${1:-"[:graph:]"} < /dev/urandom | head -c ${2:-20}
}
## Encode/Decode string using base64
function b64e() {
  echo "$@" | base64
}

function b64d() {
  echo "$@" | base64 -D
}
# Search through all man pages
function fman() {
    man -k . | fzf -q "$1" --prompt='man> '  --preview $'echo {} | tr -d \'()\' | awk \'{printf "%s ", $2} {print $1}\' | xargs -r man' | tr -d '()' | awk '{printf "%s ", $2} {print $1}' | xargs -r man
}
# Back up a file. Usage "backupthis <filename>"
backupthis() {
    cp -riv $1 ${1}-$(date +%Y%m%d%H%M).backup;
}

# Spawn a clone of current terminal
putstate () {
    declare +x >~/environment.tmp
    declare -x >>~/environment.tmp
    echo cd "$PWD" >>~/environment.tmp
}

getstate () {
    . ~/environment.tmp
}

# use ctrl-z to toggle in and out of bg
function toggle_fg_bg() {
    if [[ $#BUFFER -eq 0 ]]; then
        BUFFER="fg"
        zle accept-line
    else
        BUFFER=""
        zle clear-screen
    fi
}
zle -N toggle_fg_bg
bindkey '^Z' toggle_fg_bg

# Tmux layout
openSession () {
    tmux split-window -h -t
    tmux split-window -v -t
    tmux resize-pane -U 5
}

# archive compress
compress() {
    if [[ -n "$1" ]]; then
        local file=$1
        shift
        case "$file" in
            *.tar ) tar cf "$file" "$*" ;;
            *.tar.bz2 ) tar cjf "$file" "$*" ;;
            *.tar.gz ) tar czf "$file" "$*" ;;
            *.tgz ) tar czf "$file" "$*" ;;
            *.zip ) zip "$file" "$*" ;;
            *.rar ) rar "$file" "$*" ;;
            * ) tar zcvf "$file.tar.gz" "$*" ;;
        esac
    else
        echo 'usage: compress <foo.tar.gz> ./foo ./bar'
    fi
}

# archive extract
extract() {
    if [[ -f "$1" ]] ; then
        local filename=$(basename "$1")
        local foldername=${filename%%.*}
        local fullpath=$(perl -e 'use Cwd "abs_path";print abs_path(shift)' "$1")
        local didfolderexist=false
        if [[ -d "$foldername" ]]; then
            didfolderexist=true
            read -p "$foldername already exists, do you want to overwrite it? (y/n) " -n 1
            echo
            if [[ "$REPLY" =~ ^[Nn]$ ]]; then
                return
            fi
        fi
        mkdir -p "$foldername" && cd "$foldername"
        case "$1" in
            *.tar.bz2) tar xjf "$fullpath" ;;
            *.tar.gz) tar xzf "$fullpath" ;;
            *.tar.xz) tar Jxvf "$fullpath" ;;
            *.tar.Z) tar xzf "$fullpath" ;;
            *.tar) tar xf "$fullpath" ;;
            *.taz) tar xzf "$fullpath" ;;
            *.tb2) tar xjf "$fullpath" ;;
            *.tbz) tar xjf "$fullpath" ;;
            *.tbz2) tar xjf "$fullpath" ;;
            *.tgz) tar xzf "$fullpath" ;;
            *.txz) tar Jxvf "$fullpath" ;;
            *.zip) unzip "$fullpath" ;;
            *) echo "'$1' cannot be extracted via extract()" \
                && cd .. \
                && ! "$didfolderexist" \
                && rm -r "$foldername" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
## Extract with one command
#extract () {
#    if [ -f $1 ] ; then
#        case $1 in
#            *.tar.bz2)   tar xjf $1        ;;
#            *.tar.gz)    tar xzf $1     ;;
#            *.bz2)       bunzip2 $1       ;;
#            *.rar)       rar x $1     ;;
#            *.gz)        gunzip $1     ;;
#            *.tar)       tar xf $1        ;;
#            *.tbz2)      tar xjf $1      ;;
#            *.tgz)       tar xzf $1       ;;
#            *.zip)       unzip $1     ;;
#            *.Z)         uncompress $1  ;;
#            *.7z)        7z x $1    ;;
#            *)           echo "'$1' cannot be extracted via extract()" ;;
#        esac
#    else
#        echo "'$1' is not a valid file"
#    fi
#}

ports() {
    local result
    result=$(sudo netstat -tulpn | grep LISTEN)
    echo "$result" | fzf
}

trash() {
    case "$1" in
        --list)
            ls -A1 ~/.local/share/Trash/files/
            ;;
        --empty)
            ls -A1 ~/.local/share/Trash/files/ && \rm -rfv ~/.local/share/Trash/files/*
            ;;
        --restore)
            gio trash --restore "$(gio trash --list | fzf | cut -f 1)"
            ;;
        --delete)
            trash_files=$(ls -A ~/.local/share/Trash/files/ | fzf --multi); echo $trash_files | xargs -I {} rm -rf ~/.local/share/Trash/files/{}
            ;;
        *)
            gio trash "$@"
            ;;
    esac
}

# Git
## Use gh instead of git (fast GitHub command line client).
#if type gh >/dev/null; then
#  alias git=gh
#  if type compdef >/dev/null 2>/dev/null; then
#     compdef gh=git
#  fi
#fi
#check_gh_installed() {
#    if command -v gh &> /dev/null; then
#        return 0  # gh is installed
#    else
#        return 1  # gh is not installed
#    fi
#}
#
## Set alias for git to gh if gh is installed
#if check_gh_installed; then
#    alias git=gh
#fi

# No arguments: `git status`
# With arguments: acts like `git`
g() {
    if [ $# -gt 0 ]; then
        git "$@"           # If arguments are provided, pass them to git
    else
        git status        # Otherwise, show git status
    fi
}

# Complete g like git
compdef g=git

# Define functions for common Git commands
ga() { g add "$@"; }                   # ga: Add files to the staging area
gaw() { g add -A && g diff --cached -w | g apply --cached -R; }   # gaw: Add all changes to the staging area and unstage whitespace changes
grm() { g rm "$@"; }
gb() { g branch "$@"; }                # gb: List branches
gbl() { g branch -l "$@"; }            # gbl: List local branches
gbD() { g branch -D "$@"; }            # gbD: Delete a branch
gbu() { g branch -u "$@"; }            # gbu: Set upstream branch
ge() { g clone "$@"; }
gc() { g commit "$@"; }                # gc: Commit changes
gcm() { g commit -m "$@"; }            # gcm: Commit with a message
gca() { g commit -a "$@"; }            # gca: Commit all changes
gcaa() { g commit -a --amend "$@"; }   # gcaa: Amend the last commit
gcam() { g commit -a -m "$@"; }        # gcam: Commit all changes with a message
gce() { g commit -e "$@"; }            # gce: Commit with message and allow editing
gcfu() { g commit --fixup "$@"; }      # gcfu: Commit fixes in the context of the previous commit
gco() { g checkout "$@"; }             # gco: Checkout a branch or file
gcob() { g checkout -b "$@"; }         # gcob: Checkout a new branch
gcoB() { g checkout -B "$@"; }         # gcoB: Checkout a new branch, even if it exists
gcp() { g cherry-pick "$@"; }          # gcp: Cherry-pick a commit
gcpc() { g cherry-pick --continue "$@"; }  # gcpc: Continue cherry-picking after resolving conflicts
gd() { g diff "$@"; }                  # gd: Show changes
#gd^() { g diff HEAD^ HEAD "$@"; }      # gd^: Show changes between HEAD^ and HEAD
gds() { g diff --staged "$@"; }        # gds: Show staged changes
gl() { g lg "$@"; }                    # gl: Show a customized log
glg() { g log --graph --decorate --all "$@"; }   # glg: Show a customized log with graph
gls() {                                # Query `glog` with regex query.
  query="$1"
  shift
  glog --pickaxe-regex "-S$query" "$@"
}
gdc() { g diff --cached "$@"; }        # gdc: Show changes between the working directory and the index
gu() { g pull "$@"}                    # gu: Pull
gp() { g push "$@"}                    # gp: Push
gpom() { g push origin main "$@"; }  # gpom: Push changes to origin main
gr() { g remote "$@"; }                # gr: Show remote
gra() { g rebase --abort "$@"; }       # gra: Abort a rebase
grb() { g rebase --committer-date-is-author-date "$@"; }   # grb: Rebase with the author date preserved
grbom() { grb --onto master "$@"; }    # grbom: Rebase onto master
grbasi() { g rebase --autosquash --interactive "$@"; }    # grbasi: Interactive rebase with autosquash
grc() { g rebase --continue "$@"; }    # grc: Continue a rebase
grs() { g restore --staged "$@"; }     # grs: Restore changes staged for the next commit
grv() { g remote -v "$@"; }            # grv: Show remote URLs after each name
grh() { g reset --hard "$@"; }         # grh: Reset the repository and the working directory
grH() { g reset HEAD "$@"; }           # grH: Reset the index but not the working directory
#grH^() { g reset HEAD^ "$@"; }         # grH^: Reset the index and working directory to the state of the HEAD's first parent
gs() { g status -sb "$@"; }            # gs: Show the status of the working directory and the index
gsd() { g stash drop "$@"; }           # gsd: Drop a stash
gsl() { g stash list --date=relative "$@"; }   # gsl: List all stashes
gsp() { g stash pop "$@"; }            # gsp: Apply and remove a single stash
gss() { g stash show "$@"; }           # gss: Show changes recorded in the stash as a diff
gst() { g status "$@"; }               # gst: Show the status of the working directory and the index
gsu() { g standup "$@"; }              # gsu: Customized standup command
gforgotrecursive() { g submodule update --init --recursive --remote "$@"; }   # gforgotrecursive: Update submodules recursively
gfp() { g commit --amend --no-edit && g push --force-with-lease "$@"; }      # gfp: Amending the last commit and force-pushing
