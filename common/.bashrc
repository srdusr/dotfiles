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

# Get the current active terminal
term="$(cat /proc/"$PPID"/comm)"

# Set a default prompt
p='\[\033[01;37m\]┌─[\[\033[01;32m\]srdusr\[\033[01;37m\]]-[\[\033[01;36m\]archlinux\[\033[01;37m\]]-[\[\033[01;33m\]\W\]\[\033[00;37m\]\[\033
\[\033[01;37m\]└─[\[\033[05;33m\]$\[\033[00;37m\]\[\033[01;37m\]]\[\033[00;37m\] '

# Set transparency and prompt while using st
if [[ $term = "st" ]]; then
  transset-df "0.65" --id "$WINDOWID" >/dev/null

  #                        [Your_Name]-----|                                |=======|------[Your_Distro]
  #                 [Color]--------|       |                   [Color]------|       |
  #          [Style]------------|  |       |             [Style]---------|  |       |
  #                             V  V       V                             V  V       V
  p='\[\033[01;37m\]┌─[\[\033[01;32m\]srdusr\[\033[01;37m\]]-[\[\033[01;36m\]archlinux\[\033[01;37m\]]-[\[\033[01;33m\]\W\[\033[00;37m\]\[\033[01;37m\]]
\[\033[01;37m\]└─[\[\033[05;33m\]$\[\033[00;37m\]\[\033[01;37m\]]\[\033[00;37m\] '
#                         A  A   A
#              [Style]----|  |   |-------- [Your_Choice]
#         [Color]------------|

fi

# If not running interactively, dont do anything
[[ $- != *i* ]] && return

# My alias commands
alias ls='ls --color=auto -1'
alias shred='shred -uzvn3'
alias wallset='feh --bg-fill'

# Dotfiles Management System
if [[ -d "$HOME/.cfg" && -d "$HOME/.cfg/refs" ]]; then
    # Core git wrapper with repository as work-tree
    _config() {
        git --git-dir="$HOME/.cfg" --work-tree="$HOME" "$@"
    }

    # Detect OS
    case "$(uname -s)" in
        Linux)   CFG_OS="linux" ;;
        Darwin)  CFG_OS="macos" ;;
        MINGW*|MSYS*|CYGWIN*) CFG_OS="windows" ;;
        *)       CFG_OS="other" ;;
    esac

    # Map system path to repository path
    _repo_path() {
        local f="$1"

        # If it's an absolute path that's not in HOME, handle it specially
        if [[ "$f" == /* && "$f" != "$HOME/"* ]]; then
            echo "$CFG_OS/${f#/}"
            return
        fi

        # Check for paths that should go to the repository root
        case "$f" in
            common/*|linux/*|macos/*|windows/*|profile/*|README.md)
                echo "$f"
                return
                ;;
            "$HOME/"*)
                f="${f#$HOME/}"
                ;;
        esac

        # Default: put under OS-specific home
        echo "$CFG_OS/home/$f"
    }

    _sys_path() {
        local repo_path="$1"
        local os_path_pattern="$CFG_OS/"

        # Handle OS-specific files that are not in the home subdirectory
        if [[ "$repo_path" == "$os_path_pattern"* && "$repo_path" != */home/* ]]; then
            echo "/${repo_path#$os_path_pattern}"
            return
        fi

        case "$repo_path" in
            # Common configs → OS-specific config dirs
            common/config/*)
                case "$CFG_OS" in
                    linux)
                        local base="${XDG_CONFIG_HOME:-$HOME/.config}"
                        echo "$base/${repo_path#common/config/}"
                        ;;
                    macos)
                        echo "$HOME/Library/Application Support/${repo_path#common/config/}"
                        ;;
                    windows)
                        echo "$LOCALAPPDATA\\${repo_path#common/config/}"
                        ;;
                    *)
                        echo "$HOME/.config/${repo_path#common/config/}"
                        ;;
                esac
                ;;

            # Common assets → stay in repo
            common/assets/*)
                echo "$HOME/.cfg/$repo_path"
                ;;

            # Other common files (dotfiles like .bashrc, .gitconfig, etc.) → $HOME
            common/*)
                echo "$HOME/${repo_path#common/}"
                ;;

            # OS-specific home
            */home/*)
                echo "$HOME/${repo_path#*/home/}"
                ;;

            # Profile configs and README → stay in repo
            profile/*|README.md)
                echo "$HOME/.cfg/$repo_path"
                ;;

            # Default fallback
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

        # Parse optional --target flag for add
        if [[ "$cmd" == "add" ]]; then
            while [[ "$1" == --* ]]; do
                case "$1" in
                    --target|-t)
                        target_dir="$2"
                        shift 2
                        ;;
                    *)
                        echo "Unknown option: $1"
                        return 1
                        ;;
                esac
            done
        fi

        case "$cmd" in
            add)
                local file_path
                for file_path in "$@"; do
                    local repo_path
                    if [[ -n "$target_dir" ]]; then
                        # Keep relative path inside target_dir
                        local rel_path
                        if [[ "$file_path" == /* ]]; then
                            # Absolute path → just take the filename
                            rel_path="$(basename "$file_path")"
                        else
                            # Relative path → preserve nested dirs
                            rel_path="$file_path"
                        fi
                        repo_path="$target_dir/$rel_path"
                    else
                        repo_path="$(_repo_path "$file_path")"
                    fi

                    local full_repo_path="$HOME/.cfg/$repo_path"
                    mkdir -p "$(dirname "$full_repo_path")"

                    # Copy the file safely
                    cp -a "$file_path" "$full_repo_path"

                    # Add to git safely
                    git --git-dir="$HOME/.cfg" --work-tree="$HOME/.cfg" add "$repo_path"

                    echo "Added: $file_path -> $repo_path"
                done
                ;;
            rm)
                local rm_opts=""
                local file_path_list=()

                for arg in "$@"; do
                    if [[ "$arg" == "-"* ]]; then
                        rm_opts+=" $arg"
                    else
                        file_path_list+=("$arg")
                    fi
                done

                for file_path in "${file_path_list[@]}"; do
                    local repo_path="$(_repo_path "$file_path")"

                    if [[ "$rm_opts" == *"-r"* ]]; then
                        _config rm --cached -r "$repo_path"
                    else
                        _config rm --cached "$repo_path"
                    fi

                    eval "rm $rm_opts \"$file_path\""
                    echo "Removed: $file_path"
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
                local auto_synced=()
                while read -r repo_file; do
                    local sys_file="$(_sys_path "$repo_file")"
                    local full_repo_path="$HOME/.cfg/$repo_file"
                    if [[ -e "$sys_file" && -e "$full_repo_path" ]]; then
                        if ! diff -q "$full_repo_path" "$sys_file" >/dev/null 2>&1; then
                            cp -fa "$sys_file" "$full_repo_path"
                            auto_synced+=("$repo_file")
                        fi
                    fi
                done < <(_config ls-files)
                if [[ ${#auto_synced[@]} -gt 0 ]]; then
                    echo "=== Auto-synced Files ==="
                    for repo_file in "${auto_synced[@]}"; do
                        echo "synced: $(_sys_path "$repo_file") -> $repo_file"
                    done
                    echo
                fi
                _config status
                echo
                ;;
            deploy)
                _config ls-files | while read -r repo_file; do
                    local sys_file="$(_sys_path "$repo_file")"
                    local full_repo_path="$HOME/.cfg/$repo_file"
                    if [[ -e "$full_repo_path" ]]; then
                        if [[ -n "$sys_file" ]]; then
                            local dest_dir="$(dirname "$sys_file")"
                            if [[ "$sys_file" == /* && "$sys_file" != "$HOME/"* ]]; then
                                _sudo_prompt mkdir -p "$dest_dir"
                                _sudo_prompt cp -a "$full_repo_path" "$sys_file"
                            else
                                mkdir -p "$dest_dir"
                                cp -a "$full_repo_path" "$sys_file"
                            fi
                            echo "Deployed: $repo_file -> $sys_file"
                        fi
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

PS1=$p

bind -m vi-command 'Control-l: clear-screen'
bind -m vi-insert 'Control-l: clear-screen'

export EDITOR="nvim"

#export NVM_DIR="$HOME/.local/share/nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PROMPT_COMMAND="resize &>/dev/null ; $PROMPT_COMMAND"

# Rust environment (silent if not installed)
export RUSTUP_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/rustup"
export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
export PATH="$CARGO_HOME/bin:$RUSTUP_HOME/bin:$PATH"

if command -v rustc >/dev/null 2>&1; then
    export RUST_BACKTRACE=1
fi
