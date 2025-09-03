# Dotfiles Management System
if [[ -d "$HOME/.cfg" && -d "$HOME/.cfg/refs" ]]; then

    # Core git wrapper with repository as work-tree
    _config() {
        git --git-dir="$HOME/.cfg" --work-tree="$HOME" "$@"
    }

    # Detect OS
    case "$(uname -s)" in
        Linux)    CFG_OS="linux" ;;
        Darwin)  CFG_OS="macos" ;;
        MINGW*|MSYS*|CYGWIN*) CFG_OS="windows" ;;
        *)        CFG_OS="other" ;;
    esac

    # Map system path to repository path
    _repo_path() {
        local f="$1"
        local relative_path="${f#$HOME/}"
        local repo_path

        # If it's an absolute path that's not in HOME, handle it specially
        if [[ "$f" == /* && "$f" != "$HOME/"* ]]; then
            echo "$CFG_OS/root/$f"
            return
        fi

        # Check for paths that are explicitly within the repo structure
        case "$f" in
            "$HOME/.cfg/"*)
                # We do not want to track files within the bare repo itself
                echo ""
                return
                ;;
            "common/"*)
                # Common files remain in the common directory
                echo "$f"
                return
                ;;
            "$CFG_OS/"*)
                # OS-specific files remain in their respective OS directories
                echo "$f"
                return
                ;;
            *)
                # Default: place under OS-specific home
                echo "$CFG_OS/home/$relative_path"
                return
                ;;
        esac
    }

    # Map repository path back to system path
    _sys_path() {
        local repo_path="$1"
        local file_path

        case "$repo_path" in
            common/config/*)
                # Maps common config files to the appropriate configuration directory
                file_path="${repo_path#common/config/}"
                if [[ "$CFG_OS" == "windows" ]]; then
                    echo "$HOME/AppData/Local/$file_path"
                else
                    echo "$HOME/.config/$file_path"
                fi
                ;;
            common/bin/*)
                # Maps common bin files to the appropriate user local bin directory
                file_path="${repo_path#common/bin/}"
                if [[ "$CFG_OS" == "windows" ]]; then
                    echo "$HOME/bin/$file_path"
                else
                    echo "$HOME/.local/bin/$file_path"
                fi
                ;;
            common/*)
                # Maps remaining common files to the home directory
                file_path="${repo_path#common/}"
                echo "$HOME/$file_path"
                ;;
            */home/*)
                # Maps OS-specific home files to $HOME
                file_path="${repo_path#*/home/}"
                echo "$HOME/$file_path"
                ;;
            */root/*)
                # Maps root files to the absolute root directory
                file_path="${repo_path#*/root/}"
                echo "/$file_path"
                ;;
            *)
                # Fallback for other paths
                echo "$HOME/$repo_path"
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
                echo "Error: No privilege escalation tool (sudo, doas, pkexec) found."
                return 1
            fi
        fi
    }

    # NOTE: can change `config` to whatever you feel comfortable ie. dotfiles, dots, cfg etc.
    config() {
        local cmd="$1"; shift
        case "$cmd" in
            add)
                local file_path
                for file_path in "$@"; do
                    local repo_path="$(_repo_path "$file_path")"
                    if [[ -z "$repo_path" ]]; then
                         echo "Warning: Ignoring file within the bare repo: $file_path"
                         continue
                    fi
                    local full_repo_path="$HOME/.cfg/$repo_path"
                    mkdir -p "$(dirname "$full_repo_path")"
                    cp -a "$file_path" "$full_repo_path"
                    _config add "$repo_path"
                    echo "Added: $file_path -> $repo_path"
                done
                ;;
            rm)
                local file_path
                for file_path in "$@"; do
                    local repo_path="$(_repo_path "$file_path")"
                    _config rm "$repo_path"
                    rm -f "$HOME/.cfg/$repo_path"
                    echo "Removed: $file_path ($repo_path)"
                done
                ;;
            sync)
                local direction="${1:-to-repo}"; shift
                _config ls-files | while read -r repo_file; do
                    local sys_file="$(_sys_path "$repo_file")"
                    local full_repo_path="$HOME/.cfg/$repo_file"
                    if [[ "$direction" == "to-repo" ]]; then
                        if [[ -e "$sys_file" && -n "$(diff "$full_repo_path" "$sys_file")" ]]; then
                            cp -a "$sys_file" "$full_repo_path"
                            echo "Synced to repo: $sys_file"
                        fi
                    elif [[ "$direction" == "from-repo" ]]; then
                        if [[ -e "$full_repo_path" && -n "$(diff "$full_repo_path" "$sys_file")" ]]; then
                            local dest_dir="$(dirname "$sys_file")"
                            if [[ "$sys_file" == "/etc"* || "$sys_file" == "/usr"* ]]; then
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
                            \cp -fa "$sys_file" "$full_repo_path"
                            auto_synced+=("$repo_file")
                        fi
                    fi
                done < <(_config ls-files)
                if [[ ${#auto_synced[@]} -gt 0 ]]; then
                    echo "=== Auto-synced Files ==="
                    for repo_file in "${auto_synced[@]}"; do
                        echo "synced: $(_sys_path "$repo_file") → $repo_file"
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
                            if [[ "$sys_file" == "/etc"* || "$sys_file" == "/usr"* ]]; then
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


## Dotfiles Management System
#if [[ -d "$HOME/.cfg" && -d "$HOME/.cfg/refs" ]]; then
#
#    # Detect OS
#    case "$(uname -s)" in
#        Linux)   CFG_OS="linux" ;;
#        Darwin)  CFG_OS="macos" ;;
#        MINGW*|MSYS*|CYGWIN*) CFG_OS="windows" ;;
#        *)       CFG_OS="other" ;;
#    esac
#
#    # Core git wrapper with repository as work-tree
#    _config() {
#        git --git-dir="$HOME/.cfg" --work-tree="$HOME/.cfg" "$@"
#    }
#
#    # Map system path to repository path
#    _repo_path() {
#        local f="$1"
#
#        # Already in repo structure - return as-is
#        case "$f" in
#            linux/*|macos/*|windows/*|common/*|profile/*|.*)
#                echo "$f"
#                return
#                ;;
#        esac
#
#        # Convert absolute path to relative from HOME
#        [[ "$f" = "$HOME"* ]] && f="${f#$HOME/}"
#
#        # Default: put under OS-specific home
#        echo "$CFG_OS/home/$f"
#    }
#
#    # Map repository path back to system path
#    _sys_path() {
#        local repo_path="$1"
#
#        case "$repo_path" in
#            */home/*)
#                echo "$HOME/${repo_path#*/home/}"
#                ;;
#            *)
#                echo "/$repo_path"
#                ;;
#        esac
#    }
#
#    # Enhanced config command
#    config() {
#        local cmd="$1"; shift
#
#        case "$cmd" in
#            add)
#                # Auto-sync before adding
#                config auto-sync
#
#                for f in "$@"; do
#                    # Convert to absolute path
#                    [[ "$f" != /* ]] && f="$HOME/$f"
#
#                    if [[ ! -e "$f" ]]; then
#                        echo "File not found: $f" >&2
#                        continue
#                    fi
#
#                    # Get repository path
#                    local repo_path="$(_repo_path "$f")"
#                    local full_repo_path="$HOME/.cfg/$repo_path"
#
#                    # Create directory structure in repository
#                    mkdir -p "$(dirname "$full_repo_path")"
#
#                    # Copy file to repository structure
#                    cp "$f" "$full_repo_path"
#
#                    # Add to git using the structured path
#                    _config add "$repo_path"
#
#                    echo "Added: $f → $repo_path"
#                done
#                ;;
#
#            rm)
#                for f in "$@"; do
#                    local repo_path="$(_repo_path "$f")"
#                    _config rm "$repo_path"
#                    rm -f "$HOME/.cfg/$repo_path"
#                    echo "Removed: $f ($repo_path)"
#                done
#                ;;
#
#            sync)
#                # Sync files between home and repository structure
#                local direction="${1:-to-repo}"  # to-repo or from-repo
#                shift
#
#                if [[ $# -gt 0 ]]; then
#                    # Sync specific files
#                    for f in "$@"; do
#                        [[ "$f" != /* ]] && f="$HOME/$f"
#                        local repo_path="$(_repo_path "$f")"
#                        local full_repo_path="$HOME/.cfg/$repo_path"
#
#                        case "$direction" in
#                            to-repo)
#                                if [[ -e "$f" ]]; then
#                                    mkdir -p "$(dirname "$full_repo_path")"
#                                    cp "$f" "$full_repo_path"
#                                    echo "Synced to repo: $f → $repo_path"
#                                fi
#                                ;;
#                            from-repo)
#                                if [[ -e "$full_repo_path" ]]; then
#                                    mkdir -p "$(dirname "$f")"
#                                    cp "$full_repo_path" "$f"
#                                    echo "Synced from repo: $repo_path → $f"
#                                fi
#                                ;;
#                        esac
#                    done
#                else
#                    # Sync all tracked files
#                    _config ls-files | while read -r repo_path; do
#                        local sys_path="$(_sys_path "$repo_path")"
#                        local full_repo_path="$HOME/.cfg/$repo_path"
#
#                        case "$direction" in
#                            to-repo)
#                                if [[ -e "$sys_path" ]]; then
#                                    cp "$sys_path" "$full_repo_path"
#                                    echo "Synced to repo: $sys_path → $repo_path"
#                                fi
#                                ;;
#                            from-repo)
#                                if [[ -e "$full_repo_path" ]]; then
#                                    mkdir -p "$(dirname "$sys_path")"
#                                    cp "$full_repo_path" "$sys_path"
#                                    echo "Synced from repo: $repo_path → $sys_path"
#                                fi
#                                ;;
#                        esac
#                    done
#                fi
#                ;;
#
#            status)
#                # Auto-sync any modified files
#                local auto_synced=()
#                while read -r repo_file; do
#                    local sys_file="$(_sys_path "$repo_file")"
#                    local full_repo_path="$HOME/.cfg/$repo_file"
#                    if [[ -e "$sys_file" && -e "$full_repo_path" ]]; then
#                        if ! diff -q "$full_repo_path" "$sys_file" >/dev/null 2>&1; then
#                            \cp -f "$sys_file" "$full_repo_path"
#                            auto_synced+=("$repo_file")
#                        fi
#                    fi
#                done < <(_config ls-files)
#
#                if [[ ${#auto_synced[@]} -gt 0 ]]; then
#                    echo "=== Auto-synced Files ==="
#                    for repo_file in "${auto_synced[@]}"; do
#                        echo "synced: $(_sys_path "$repo_file") → $repo_file"
#                    done
#                    echo
#                fi
#
#                echo "=== Git Status ==="
#                _config status
#
#                echo
#                #echo "=== Path Mappings ==="
#                #_config ls-files | while read -r repo_file; do
#                #    echo "$repo_file ↔ $(_sys_path "$repo_file")"
#                #done
#                ;;
#
#            deploy)
#                # Deploy from repository structure to system
#                echo "Deploying dotfiles from repository structure..."
#                _config ls-files | while read -r repo_file; do
#                    local sys_file="$(_sys_path "$repo_file")"
#                    local full_repo_path="$HOME/.cfg/$repo_file"
#
#                    if [[ -e "$full_repo_path" ]]; then
#                        echo "Deploying: $repo_file → $sys_file"
#                        mkdir -p "$(dirname "$sys_file")"
#                        cp "$full_repo_path" "$sys_file"
#                    fi
#                done
#                ;;
#
#            auto-sync)
#                # Auto-sync all modified tracked files
#                _config ls-files | while read -r repo_file; do
#                    local sys_file="$(_sys_path "$repo_file")"
#                    local full_repo_path="$HOME/.cfg/$repo_file"
#
#                    if [[ -e "$sys_file" && -e "$full_repo_path" ]]; then
#                        if ! diff -q "$full_repo_path" "$sys_file" >/dev/null 2>&1; then
#                            cp "$sys_file" "$full_repo_path"
#                            echo "Auto-synced: $sys_file → $repo_file"
#                        fi
#                    fi
#                done
#                ;;
#
#            ls-structure)
#                # Show repository structure
#                echo "Repository structure:"
#                _config ls-files | sed 's|/[^/]*$|/|' | sort -u | while read -r dir; do
#                    echo "  $dir"
#                done
#                ;;
#
#            ls-mappings)
#                # List all tracked files with mappings
#                _config ls-files | while read -r repo_file; do
#                    local sys_file="$(_sys_path "$repo_file")"
#                    echo "$repo_file ↔ $sys_file"
#                done
#                ;;
#
#            *)
#                # Pass through to git
#                _config "$cmd" "$@"
#                ;;
#        esac
#    }
#
#    # Completion
#    _config_completion() {
#        local cur="${COMP_WORDS[COMP_CWORD]}"
#        case "${COMP_WORDS[1]}" in
#            add|edit)
#                COMPREPLY=($(compgen -f -- "$cur"))
#                ;;
#            sync)
#                if [[ ${COMP_WORDS[2]} == "to-repo" || ${COMP_WORDS[2]} == "from-repo" ]]; then
#                    COMPREPLY=($(compgen -f -- "$cur"))
#                else
#                    COMPREPLY=($(compgen -W "to-repo from-repo" -- "$cur"))
#                fi
#                ;;
#        esac
#    }
#
#    compdef _config_completion config
#    #complete -F _config_completion config
#fi

# Git
# Use gh instead of git (fast GitHub command line client).
if type gh >/dev/null; then
  alias git=gh
  if type compdef >/dev/null 2>/dev/null; then
     compdef gh=git
  fi
fi
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

# Git alias commands
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

# Temporarily unset GIT_WORK_TREE
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
#alias git='git_without_work_tree git'

# Set bare dotfiles repository git environment variables dynamically
function set_git_env_vars() {
    # Do nothing unless ~/.cfg exists and is a bare git repo
    [[ -d "$HOME/.cfg" ]] || return
    git --git-dir="$HOME/.cfg" rev-parse --is-bare-repository &>/dev/null || return

    # Skip if last command was a package manager
    if [[ "${(%)${(z)history[1]}}" =~ ^(pacman|yay|apt|dnf|brew|npm|pip|gem|go|cargo) ]]; then
        return
    fi

    # Only set env vars if not already inside another Git repo
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        export GIT_DIR="$HOME/.cfg"
        export GIT_WORK_TREE="$(realpath ~)"
    else
        unset GIT_DIR
        unset GIT_WORK_TREE
    fi
}

# Hook and initial call
function chpwd() { set_git_env_vars }
set_git_env_vars

# Git Subtrees
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

# Copy the current command to a file
copy_command_to_file() {
    # Only write the last command if BUFFER is not empty
    if [[ -n "$BUFFER" ]]; then
        echo "$BUFFER" > ~/command_log.txt  # Overwrite with the latest command
    else
        # If the buffer is empty, remove the previous log file
        command rm -f ~/command_log.txt  # Optionally remove the log if no command is present
    fi
}

# Display the latest command from the log in the user input
display_latest_command() {
    if [[ -f ~/command_log.txt ]]; then
        # Read the last command from the log
        local last_command
        last_command=$(< ~/command_log.txt)

        # Only display if the last command is not empty
        if [[ -n "$last_command" ]]; then
            BUFFER="$last_command"  # Set the BUFFER to the last command
            CURSOR=${#BUFFER}       # Set the cursor to the end of the command
        fi
    fi
    zle reset-prompt            # Refresh the prompt
}

# Go up a directory
go_up() {
    copy_command_to_file  # Copy the current command to a file
    BUFFER=""             # Clear the current command line
    cd .. || return       # Change directory and return if it fails
    display_latest_command # Display the latest command in the user input
}

# Initialize a variable to store the previous directory
previous_dir=""

# Function to change directories
go_into() {
    copy_command_to_file  # Copy the current command to a file

    # Use fzf or another tool to choose the directory
    local dir
    dir=$( (ls -d */; echo "Go Last directory:") | fzf --height 40% --reverse --tac)  # Include previous directory as an option

    if [[ -n "$dir" ]]; then
        # Check if the user selected the previous directory
        if [[ "$dir" == Previous:* ]]; then
            cd - || return  # Change to the previous directory
        else
            cd "${dir%/}" || return  # Change directory if a selection is made (remove trailing slash)
        fi

        # Save the current directory to previous_dir
        previous_dir=$(pwd)  # Update previous_dir to current directory after changing
        BUFFER=""             # Clear the current command line
        display_latest_command # Display the last command if available
    fi
}

# Register functions as ZLE widgets
zle -N go_up
zle -N go_into




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

guest() {
  local guest="$1"
  shift

  local port
  if [[ "$#" -ge 2 && "${@: -1}" =~ ^[0-9]+$ ]]; then
    port="${@: -1}"
    set -- "${@:1:$(($#-1))}"
  fi

  if [[ -z "$guest" || "$#" -lt 1 ]]; then
    echo "Send file(s) or directories to remote machine"
    echo "Usage: guest <guest-alias> <file-or-directory>... [port]"
    return 1
  fi

  # Auto-detect port
  if [[ -z "$port" ]]; then
    if nc -z localhost 22220 2>/dev/null; then
      port=22220
    elif nc -z localhost 22 2>/dev/null; then
      port=22
    else
      echo "No known SSH port (22220 or 22) is open. Specify a port manually."
      return 1
    fi
  fi

  for src in "$@"; do
    src="${src/#\~/$HOME}"
    if [[ ! -e "$src" ]]; then
      echo "Error: '$src' does not exist."
      continue
    fi

    local abs_path dest_dir rel_dir rsync_src rsync_dest

    abs_path=$(realpath "$src")
    rel_dir="${abs_path#$HOME/}"
    dest_dir=$(dirname "$rel_dir")

    # Ensure target dir exists remotely
    ssh -p "$port" "$guest" "mkdir -p ~/$dest_dir"

    if [[ -d "$src" ]]; then
      # Add trailing slash to copy contents instead of nesting the dir
      rsync_src="${src%/}/"
      rsync_dest="~/$rel_dir/"
    else
      rsync_src="$src"
      rsync_dest="~/$dest_dir/"
    fi

    echo "Sending '$src' to '$guest:$rsync_dest'..."
    rsync -avz -e "ssh -p $port" "$rsync_src" "$guest:$rsync_dest"
  done
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

extract() {
    if [[ -f "$1" ]] ; then
        local filename
        filename=$(basename "$1")
        local foldername="${filename%%.*}"
        local fullpath
        fullpath=$(perl -e 'use Cwd "abs_path";print abs_path(shift)' "$1")
        local didfolderexist=false

        if [[ -d "$foldername" ]]; then
            didfolderexist=true
            read -p "$foldername already exists, do you want to overwrite it? (y/n) " -n 1
            echo
            if [[ "$REPLY" =~ ^[Nn]$ ]]; then
                return
            fi
        fi

        mkdir -p "$foldername" && cd "$foldername" || return

        case "$1" in
            *.tar.bz2) tar xjf "$fullpath" ;;
            *.tar.gz)  tar xzf "$fullpath" ;;
            *.tar.xz)  tar Jxf "$fullpath" ;;
            *.tar.Z)   tar xzf "$fullpath" ;;
            *.tar)     tar xf "$fullpath" ;;
            *.taz)     tar xzf "$fullpath" ;;
            *.tb2)     tar xjf "$fullpath" ;;
            *.tbz)     tar xjf "$fullpath" ;;
            *.tbz2)    tar xjf "$fullpath" ;;
            *.tgz)     tar xzf "$fullpath" ;;
            *.txz)     tar Jxf "$fullpath" ;;
            *.rar)     unrar x -o+ "$fullpath" >/dev/null ;;
            *.zip)     unzip -o "$fullpath" ;;
            *)
                echo "'$1' cannot be extracted via extract()" \
                && cd .. \
                && ! "$didfolderexist" \
                && rm -r "$foldername"
                ;;
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

what() {
    type "$1"
    echo "$PATH"
}

shutdown() {
    if [ "$#" -eq 0 ]; then
        sudo /sbin/shutdown -h now
    else
        sudo /sbin/shutdown -h "$@"
    fi
}

windowManagerName () {
    local window=$(
        xprop -root -notype
    )

    local identifier=$(
        echo "${window}" |
        awk '$1=="_NET_SUPPORTING_WM_CHECK:"{print $5}'
    )

    local attributes=$(
        xprop -id "${identifier}" -notype -f _NET_WM_NAME 8t
    )

    local name=$(
        echo "${attributes}" |
        grep "_NET_WM_NAME = " |
        cut --delimiter=' ' --fields=3 |
        cut --delimiter='"' --fields=2
    )

    echo "${name}"
}

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

# Gentoo
emg() {
  if [[ -z "$1" ]]; then
    echo "Usage: emg [USE_FLAGS] package [package...]"
    return 1
  fi

  if [[ "$1" =~ ^[^-].* ]]; then
    local use_flags="$1"
    shift
    sudo USE="$use_flags" emerge -av "$@"
  else
    sudo emerge -av "$@"
  fi
}

# Remove command from history
forget () { # Accepts one history line number as argument or search term
  if [[ -z "$1" ]]; then
    echo "Usage: hist <history_number> | hist -s <search_term>"
    return 1
  fi

  if [[ "$1" == "-s" ]]; then
    if [[ -z "$2" ]]; then
      echo "Usage: hist -s <search_term>"
      return 1
    fi

    local search_term="$2"

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
      LC_ALL=C sed -i "/${search_term}/d" "$HISTFILE"  # GNU sed
    else
      LC_ALL=C sed -i '' "/${search_term}/d" "$HISTFILE"  # BSD/macOS sed
    fi

    fc -R "$HISTFILE"
    echo "Deleted all history entries matching '$search_term'."
  else
    local num=$1
    local cmd=$(fc -ln $num $num 2>/dev/null)

    if [[ -z "$cmd" ]]; then
      echo "No history entry found for index $num"
      return 1
    fi

    history -d $num

    local escaped_cmd=$(echo "$cmd" | sed 's/[\/&]/\\&/g')

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
      LC_ALL=C sed -i "/${escaped_cmd}/d" "$HISTFILE"
    else
      LC_ALL=C sed -i '' "/${escaped_cmd}/d" "$HISTFILE"
    fi

    fc -R "$HISTFILE"
    echo "Deleted '$cmd' from history."
  fi
}

# Remove hist command itself
remove_hist_command() {
 [[ $1 != 'hist '* ]]
}

remove_hist_command


search() {
    # Search for a pattern in the specified directory (non-recursive).
    dir="${1:-.}"
    ls -1 "$dir" | grep -i "$2"
}

deepsearch() {
    # Perform a recursive search for a pattern in the specified directory.
    dir="${1:-.}"
    find "$dir" -iname "$2"
}

notes() {
    local base_dir="$HOME/documents/main/"

    if [[ -z "$1" ]]; then
        # No argument → cd to notes directory
        cd "$base_dir" || return
        return
    fi

    local target="$1"  # The argument itself

    # Use find to check if the file exists anywhere in the base directory
    local found_files=($(find "$base_dir" -type f -name "$target"))

    if [[ ${#found_files[@]} -eq 1 ]]; then
        # Only one match found, open it directly
        $EDITOR "${found_files[0]}"
    elif [[ ${#found_files[@]} -gt 1 ]]; then
        # Multiple files found, prompt the user to select one
        echo "Multiple files found for '$target'. Please choose one:"
        PS3="Please enter a number to select a file (1-${#found_files[@]}): "
        select selected_file in "${found_files[@]}"; do
            if [[ -n "$selected_file" ]]; then
                $EDITOR "$selected_file"
                break
            else
                echo "Invalid selection, try again."
            fi
        done
    else
        # If no match found, search for a directory
        local found_dir=$(find "$base_dir" -type d -name "$target" -print -quit)

        if [[ -n "$found_dir" ]]; then
            # Directory found, cd into it
            cd "$found_dir" || return
        else
            # If no match found, create the file and open it
            local full_target="$base_dir/$target"
            mkdir -p "$(dirname "$full_target")"
            $EDITOR "$full_target"
        fi
    fi
}

# Enable tab completion for files and directories
_notes_complete() {
    local base_dir="$HOME/documents/main"
    compadd -o nospace -- $(find "$base_dir" -type f -o -type d -printf '%P\n')
}

compdef _notes_complete notes


ship() {
  local binary_dir="$HOME/.local/share"
  local bin_symlink_dir="$HOME/.local/bin"
  local project_dirs=(
    "$HOME/projects/"
    "$HOME/src/"
    "$HOME/src/site/"
  )

  mkdir -p "$binary_dir" "$bin_symlink_dir"

  local project_dir=""

  if [[ -n "$1" ]]; then
    # Project name specified
    for dir in "${project_dirs[@]}"; do
      if [[ -d "$dir/$1" ]]; then
        project_dir="$dir/$1"
        break
      fi
    done

    if [[ -z "$project_dir" ]]; then
      echo "Project '$1' not found."
      return 1
    fi
  else
    # No argument: pick latest edited
    local bin_file
    bin_file=$(find "${project_dirs[@]}" -type f -name "Cargo.toml" -exec stat --format="%Y %n" {} \; 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-)

    if [[ -z "$bin_file" ]]; then
      echo "No Cargo.toml found."
      return 1
    fi

    project_dir=$(dirname "$bin_file")
  fi

  cd "$project_dir" || return
  echo "Building project in $project_dir..."

  # Build it
  cargo build --release || { echo "Build failed"; return 1; }

  # Assume binary has same name as project dir
  local binary_name
  binary_name=$(basename "$project_dir")
  local built_binary="target/release/$binary_name"

  if [[ -x "$built_binary" ]]; then
    echo "Copying $built_binary to $binary_dir/$binary_name"
    cp "$built_binary" "$binary_dir/$binary_name"

    # Create/Update symlink
    local symlink_path="$bin_symlink_dir/$binary_name"
    ln -sf "$binary_dir/$binary_name" "$symlink_path"

    echo "Binary is now at: $binary_dir/$binary_name"
    echo "Symlink created at: $symlink_path"
  else
    echo "Built binary not found: $built_binary"
    echo "You may need to manually specify the output binary."
  fi
}


forge() {

  local install=no
  local usage="Usage: forge [--install]"

  # Handle --install flag
  if [[ "$1" == "--install" ]]; then
    install=yes
    shift
  elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "$usage"
    return 0
  fi

  if [[ -f "CMakeLists.txt" ]]; then
    echo "📦 CMake project detected"
    [[ ! -d build ]] && mkdir build
    cmake -B build -DCMAKE_BUILD_TYPE=Release || return 1
    cmake --build build || return 1
    [[ "$install" == "yes" ]] && sudo cmake --install build

  elif [[ -f "meson.build" ]]; then
    echo "📦 Meson project detected"
    if [[ ! -d build ]]; then
      meson setup build || return 1
    fi
    ninja -C build || return 1
    [[ "$install" == "yes" ]] && sudo ninja -C build install

  elif [[ -f "Makefile" ]]; then
    echo "📦 Makefile project detected"
    # Try `make all`, fallback to `make` if `all` fails
    if make -q all 2>/dev/null; then
      make all || return 1
    else
      make || return 1
    fi
    [[ "$install" == "yes" ]] && sudo make install

  else
    echo "❌ No supported build system found."
    return 1
  fi
}

windows_home() {
  for dir in /mnt/windows/Users/*(N); do
    base=${dir:t}   # `:t` is zsh's "tail" = basename
    if [[ -d $dir && ! $base =~ ^(All Users|Default|Default User|Public|nx|desktop.ini)$ ]]; then
      echo "$dir"
      return 0
    fi
  done
  return 1
}

if winhome_path=$(windows_home); then
  hash -d winhome="$winhome_path"
fi
