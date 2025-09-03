#!/usr/bin/env bash

# Execute the main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

# Enhanced Dotfiles Installation Script
#======================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

#======================================
# Variables & Configuration
#======================================

# Color definitions for pretty UI
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'

# Dotfiles configuration
DOTFILES_URL='https://github.com/srdusr/dotfiles.git'
DOTFILES_DIR="$HOME/.cfg"
LOG_FILE="$HOME/.local/share/dotfiles_install.log"
TRASH_DIR="$HOME/.local/share/Trash"

# Installation tracking
INSTALL_SUMMARY=()
FAILED_ITEMS=()
SKIPPED_ITEMS=()

#======================================
# UI Functions
#======================================

# Print colorized output
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NOCOLOR}"
}

# Print header with decorative border
print_header() {
    local title="$1"
    local border_char="="
    local border_length=60

    echo
    print_color "$CYAN" "$(printf '%*s' $border_length '' | tr ' ' "$border_char")"
    print_color "$CYAN$BOLD" "$(printf '%*s' $(((border_length + ${#title}) / 2)) "$title")"
    print_color "$CYAN" "$(printf '%*s' $border_length '' | tr ' ' "$border_char")"
    echo
}

# Print section header
print_section() {
    local title="$1"
    echo
    print_color "$BLUE$BOLD" "▶ $title"
    print_color "$BLUE" "$(printf '%*s' $((${#title} + 2)) '' | tr ' ' '-')"
}

# Print success message
print_success() {
    local message="$1"
    print_color "$GREEN" "✓ $message"
    INSTALL_SUMMARY+=("✓ $message")
}

# Print error message
print_error() {
    local message="$1"
    print_color "$RED" "✗ $message" >&2
    FAILED_ITEMS+=("✗ $message")
}

# Print warning message
print_warning() {
    local message="$1"
    print_color "$YELLOW" "⚠ $message"
}

# Print info message
print_info() {
    local message="$1"
    print_color "$CYAN" "ℹ $message"
}

# Print skip message
print_skip() {
    local message="$1"
    print_color "$YELLOW" "⏭ $message"
    SKIPPED_ITEMS+=("⏭ $message")
}

#======================================
# Logging Functions
#======================================

# Setup logging
setup_logging() {
    local log_dir
    log_dir="$(dirname "$LOG_FILE")"

    # Create log directory if it doesn't exist
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" || {
            print_error "Failed to create log directory: $log_dir"
            exit 1
        }
    fi

    # Create trash directory if it doesn't exist
    if [[ ! -d "$TRASH_DIR" ]]; then
        mkdir -p "$TRASH_DIR" || {
            print_error "Failed to create trash directory: $TRASH_DIR"
            exit 1
        }
    fi

    # Move old log file to trash if it exists
    [[ -f "$LOG_FILE" ]] && mv "$LOG_FILE" "$TRASH_DIR/"

    # Initialize log file
    {
        echo "======================================="
        echo "Dotfiles Installation Log"
        echo "Date: $(date)"
        echo "User: $USER"
        echo "Host: $HOSTNAME"
        echo "OS: $(uname -s)"
        echo "======================================="
        echo
    } > "$LOG_FILE"

    # Redirect stderr to log file while keeping it visible
    exec 2> >(tee -a "$LOG_FILE" >&2)
}

# Log function
log_message() {
    local level="$1"
    local message="$2"
    echo "[$level] $(date +'%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

#======================================
# User Interaction Functions
#======================================

# Prompt function
prompt_user() {
    local question="$1"
    local default="${2:-Y}"
    local response

    while true; do
        if [[ "$default" == "Y" ]]; then
            print_color "$YELLOW" "$question [Y/n]: "
        else
            print_color "$YELLOW" "$question [y/N]: "
        fi

        read -r response

        # Use default if no response
        if [[ -z "$response" ]]; then
            response="$default"
        fi

        case "${response^^}" in
            Y|YES) return 0 ;;
            N|NO) return 1 ;;
            *) print_warning "Please answer Y/yes or N/no" ;;
        esac
    done
}

# Multi-choice prompt
prompt_choice() {
    local question="$1"
    shift
    local choices=("$@")
    local choice

    echo
    print_color "$YELLOW$BOLD" "$question"
    for i in "${!choices[@]}"; do
        print_color "$CYAN" "$((i + 1)). ${choices[i]}"
    done

    while true; do
        print_color "$YELLOW" "Please enter your choice (1-${#choices[@]}): "
        read -r choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#choices[@]})); then
            return $((choice - 1))
        else
            print_warning "Invalid choice. Please enter a number between 1 and ${#choices[@]}"
        fi
    done
}

#======================================
# System Detection Functions
#======================================

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Linux)   CFG_OS="linux" ;;
        Darwin)  CFG_OS="macos" ;;
        MINGW*|MSYS*|CYGWIN*) CFG_OS="windows" ;;
        *)       CFG_OS="unknown" ;;
    esac

    print_info "Detected OS: $CFG_OS"
    log_message "INFO" "Detected operating system: $CFG_OS"
}

# Detect privilege escalation tools
detect_privilege_tools() {
    if command -v sudo &>/dev/null; then
        PRIVILEGE_TOOL="sudo"
    elif command -v doas &>/dev/null; then
        PRIVILEGE_TOOL="doas"
    elif command -v pkexec &>/dev/null; then
        PRIVILEGE_TOOL="pkexec"
    elif [[ "$(id -u)" -eq 0 ]]; then
        PRIVILEGE_TOOL=""  # Running as root
    else
        PRIVILEGE_TOOL=""
        print_warning "No privilege escalation tool found"
        if prompt_user "Continue without privilege escalation? (Installation may fail for some components)" "N"; then
            print_info "Continuing without privilege escalation..."
        else
            print_error "Privilege escalation required. Exiting."
            exit 1
        fi
    fi

    [[ -n "$PRIVILEGE_TOOL" ]] && print_success "Using privilege escalation tool: $PRIVILEGE_TOOL"
}

# Detect Linux distribution
detect_linux_distro() {
    if [[ ! -f /etc/os-release ]]; then
        print_error "/etc/os-release not found"
        return 1
    fi

    source /etc/os-release

    case "$ID" in
        arch|manjaro|endeavouros)     DISTRO="PACMAN" ;;
        debian|ubuntu|mint|pop)       DISTRO="APT" ;;
        fedora|rhel|centos|rocky)     DISTRO="DNF" ;;
        opensuse*|sles)               DISTRO="ZYPPER" ;;
        gentoo)                       DISTRO="PORTAGE" ;;
        *)
            print_warning "Unknown distribution: $ID"
            # Try to detect package managers
            for pm in pacman apt dnf zypper emerge; do
                if command -v "$pm" &>/dev/null; then
                    case "$pm" in
                        pacman) DISTRO="PACMAN" ;;
                        apt) DISTRO="APT" ;;
                        dnf) DISTRO="DNF" ;;
                        zypper) DISTRO="ZYPPER" ;;
                        emerge) DISTRO="PORTAGE" ;;
                    esac
                    break
                fi
            done

            if [[ -z "${DISTRO:-}" ]]; then
                print_error "Could not detect package manager"
                return 1
            fi
            ;;
    esac

    print_success "Detected Linux distribution: $ID (Package manager: $DISTRO)"
    log_message "INFO" "Detected Linux distribution: $ID, Package manager: $DISTRO"
}

#======================================
# Utility Functions
#======================================

# Check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Download file with progress
download_file() {
    local url="$1"
    local output="$2"

    if command_exists wget; then
        wget --progress=bar:force -O "$output" "$url" 2>&1 | \
            while IFS= read -r line; do
                if [[ "$line" =~ [0-9]+% ]]; then
                    printf "\r%s" "$line"
                fi
            done
        echo
    elif command_exists curl; then
        curl --progress-bar -o "$output" "$url"
    else
        print_error "Neither wget nor curl found"
        return 1
    fi
}

# Create directory with proper permissions
create_dir() {
    local dir="$1"
    local permissions="${2:-755}"

    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || {
            print_error "Failed to create directory: $dir"
            return 1
        }
        chmod "$permissions" "$dir"
        print_success "Created directory: $dir"
    else
        print_info "Directory already exists: $dir"
    fi
}

#======================================
# Git Configuration Functions
#======================================

# Git wrapper to avoid conflicts
git_without_work_tree() {
    if [[ -d "$PWD/.git" ]] && [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]]; then
        local old_work_tree="$GIT_WORK_TREE"
        unset GIT_WORK_TREE
        git "$@"
        export GIT_WORK_TREE="$old_work_tree"
    else
        git "$@"
    fi
}

# Core config command
_config() {
    git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"
}

# Path mapping functions
_repo_path() {
    local f="$1"

    case "$f" in
        linux/*|macos/*|windows/*|common/*|profile/*|.*) echo "$f"; return ;;
    esac

    [[ "$f" = "$HOME"* ]] && f="${f#$HOME/}"
    echo "$CFG_OS/home/$f"
}

_sys_path() {
    local repo_path="$1"
    case "$repo_path" in
        */home/*) echo "$HOME/${repo_path#*/home/}" ;;
        *) echo "/$repo_path" ;;
    esac
}

# Enhanced config wrapper with better path handling
config() {
    local cmd="$1"
    shift

    case "$cmd" in
        add)
            for file_path in "$@"; do
                local repo_path
                repo_path="$(_repo_path "$file_path")"
                local full_repo_path="$DOTFILES_DIR/$repo_path"

                create_dir "$(dirname "$full_repo_path")"
                cp -a "$file_path" "$full_repo_path" || {
                    print_error "Failed to copy $file_path"
                    continue
                }

                _config add "$repo_path" || {
                    print_error "Failed to git add $repo_path"
                    continue
                }

                print_success "Added: $file_path → $repo_path"
            done
            ;;

        status)
            # Auto-sync modified files
            local synced_files=()
            while IFS= read -r repo_file; do
                [[ -z "$repo_file" ]] && continue
                local sys_file full_repo_path
                sys_file="$(_sys_path "$repo_file")"
                full_repo_path="$DOTFILES_DIR/$repo_file"

                if [[ -e "$sys_file" && -e "$full_repo_path" ]]; then
                    if ! diff -q "$full_repo_path" "$sys_file" >/dev/null 2>&1; then
                        cp -f "$sys_file" "$full_repo_path"
                        synced_files+=("$repo_file")
                    fi
                fi
            done < <(_config ls-files 2>/dev/null)

            if [[ ${#synced_files[@]} -gt 0 ]]; then
                print_section "Auto-synced Files"
                for repo_file in "${synced_files[@]}"; do
                    print_success "Synced: $(_sys_path "$repo_file") → $repo_file"
                done
                echo
            fi

            _config status
            ;;

        deploy)
            local deployed=()
            while IFS= read -r repo_file; do
                [[ -z "$repo_file" ]] && continue
                local sys_file full_repo_path
                sys_file="$(_sys_path "$repo_file")"
                full_repo_path="$DOTFILES_DIR/$repo_file"

                if [[ -e "$full_repo_path" ]]; then
                    create_dir "$(dirname "$sys_file")"
                    cp -a "$full_repo_path" "$sys_file" || {
                        print_error "Failed to deploy $repo_file"
                        continue
                    }
                    deployed+=("$repo_file")
                fi
            done < <(_config ls-files 2>/dev/null)

            if [[ ${#deployed[@]} -gt 0 ]]; then
                print_success "Deployed ${#deployed[@]} files"
            else
                print_warning "No files to deploy"
            fi
            ;;

        *)
            _config "$cmd" "$@"
            ;;
    esac
}


#======================================
# Installation Functions
#======================================

# Install dotfiles
install_dotfiles() {
    print_section "Installing Dotfiles"

    local update=false

    if [[ -d "$DOTFILES_DIR" ]]; then
        if prompt_user "Dotfiles repository already exists. Update it?"; then
            print_info "Updating existing dotfiles..."
            config pull origin main || {
                print_error "Failed to pull updates"
                return 1
            }
            update=true
        else
            print_skip "Skipping dotfiles update"
            return 0
        fi
    else
        print_info "Cloning dotfiles repository..."
        git clone --bare "$DOTFILES_URL" "$DOTFILES_DIR" || {
            print_error "Failed to clone dotfiles repository"
            return 1
        }
    fi

    # Check for conflicts
    local conflicts
    conflicts=$(config checkout 2>&1 | grep -E "^\s+" | awk '{print $1}' || true)

    if [[ -n "$conflicts" ]]; then
        print_warning "The following files will be overwritten:"
        echo "$conflicts"

        if prompt_user "Continue and overwrite these files?"; then
            # Backup conflicting files
            local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
            create_dir "$backup_dir"

            while IFS= read -r file; do
                [[ -z "$file" ]] && continue
                [[ -e "$HOME/$file" ]] && cp -r "$HOME/$file" "$backup_dir/"
            done <<< "$conflicts"

            print_info "Backed up conflicting files to: $backup_dir"
        else
            print_error "Installation cancelled by user"
            return 1
        fi
    fi

    # Checkout files
    config checkout -f || {
        print_error "Failed to checkout dotfiles"
        return 1
    }

    # Configure repository
    config config status.showUntrackedFiles no

    print_success "Dotfiles installed successfully"
}

# Create user directories
setup_user_dirs() {
    print_section "Setting Up User Directories"

    local directories=('.cache' '.config' '.local/bin' '.local/share' '.scripts')

    for dir in "${directories[@]}"; do
        create_dir "$HOME/$dir"
    done

    # Handle XDG user directories
    if [[ -f "$HOME/.config/user-dirs.dirs" ]]; then
        if prompt_user "Configure XDG user directories?"; then
            source "$HOME/.config/user-dirs.dirs"

            # Create XDG directories
            for var in XDG_DESKTOP_DIR XDG_DOWNLOAD_DIR XDG_TEMPLATES_DIR XDG_PUBLICSHARE_DIR \
                      XDG_DOCUMENTS_DIR XDG_MUSIC_DIR XDG_PICTURES_DIR XDG_VIDEOS_DIR; do
                local dir_path="${!var:-}"
                [[ -n "$dir_path" ]] && create_dir "$dir_path"
            done

            print_success "XDG user directories configured"
        fi
    fi
}

install_yq() {
    local bin_dir="$HOME/.local/bin"
    local yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
    local yq_path="$bin_dir/yq"

    print_info "Installing yq..."

    create_dir "$bin_dir"

    download_file "$yq_url" "$yq_path" || return 1

    chmod +x "$yq_path" || {
        print_error "Failed to set executable permissions for yq"
        return 1
    }

    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        export PATH="$bin_dir:$PATH"
        echo "export PATH=\"$bin_dir:\$PATH\"" >> "$HOME/.bashrc"
    fi

    print_success "yq installed successfully"
}

# Install packages based on OS and package manager
install_packages() {
    print_section "Installing Packages"

    local packages_file="packages.yml"

    # Check if yq is available for YAML parsing
    if ! command_exists yq; then
        if prompt_user "yq (YAML parser) is required. Install it?"; then
            install_yq || {
                print_error "Failed to install yq"
                return 1
            }
        else
            print_skip "Package installation (requires yq)"
            return 0
        fi
    fi

    if [[ ! -f "$packages_file" ]]; then
        print_warning "packages.yml not found, skipping package installation"
        return 0
    fi

    case "$CFG_OS" in
        linux)
            install_linux_packages "$packages_file"
            ;;
        macos)
            install_macos_packages "$packages_file"
            ;;
        windows)
            install_windows_packages "$packages_file"
            ;;
        *)
            print_warning "Package installation not supported for $CFG_OS"
            ;;
    esac
}

# Install Linux packages
install_linux_packages() {
    local packages_file="$1"
    local failed_packages=()
    local installed_packages=()

    # Get package list
    local packages=()
    mapfile -t packages < <(yq e '.PackageManager[]' "$packages_file" 2>/dev/null)

    # Add distro-specific packages
    case "$DISTRO" in
        PACMAN)
            mapfile -t -O ${#packages[@]} packages < <(yq e '.linux.arch[]' "$packages_file" 2>/dev/null)
            ;;
        APT)
            mapfile -t -O ${#packages[@]} packages < <(yq e '.linux.debian[]' "$packages_file" 2>/dev/null)
            ;;
        DNF)
            mapfile -t -O ${#packages[@]} packages < <(yq e '.linux.rhel[]' "$packages_file" 2>/dev/null)
            ;;
    esac

    if [[ ${#packages[@]} -eq 0 ]]; then
        print_warning "No packages found in configuration"
        return 0
    fi

    print_info "Found ${#packages[@]} packages to install"

    # Update package database first
    if prompt_user "Update package database before installing?"; then
        case "$DISTRO" in
            PACMAN) $PRIVILEGE_TOOL pacman -Sy ;;
            APT) $PRIVILEGE_TOOL apt update ;;
            DNF) $PRIVILEGE_TOOL dnf check-update || true ;;
            ZYPPER) $PRIVILEGE_TOOL zypper refresh ;;
            PORTAGE) $PRIVILEGE_TOOL emerge --sync ;;
        esac
    fi

    # Install packages
    for package in "${packages[@]}"; do
        [[ -z "$package" ]] && continue

        print_info "Installing $package..."

        case "$DISTRO" in
            PACMAN)
                if pacman -Q "$package" &>/dev/null; then
                    print_info "$package already installed"
                    continue
                fi
                if $PRIVILEGE_TOOL pacman -S --noconfirm "$package"; then
                    installed_packages+=("$package")
                else
                    failed_packages+=("$package")
                fi
                ;;
            APT)
                if dpkg -l "$package" 2>/dev/null | grep -q "^ii"; then
                    print_info "$package already installed"
                    continue
                fi
                if $PRIVILEGE_TOOL apt install -y "$package"; then
                    installed_packages+=("$package")
                else
                    failed_packages+=("$package")
                fi
                ;;
            DNF)
                if rpm -q "$package" &>/dev/null; then
                    print_info "$package already installed"
                    continue
                fi
                if $PRIVILEGE_TOOL dnf install -y "$package"; then
                    installed_packages+=("$package")
                else
                    failed_packages+=("$package")
                fi
                ;;
        esac
    done

    # Report results
    if [[ ${#installed_packages[@]} -gt 0 ]]; then
        print_success "Successfully installed ${#installed_packages[@]} packages"
    fi

    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        print_error "Failed to install ${#failed_packages[@]} packages: ${failed_packages[*]}"
    fi
}

# Install shell and plugins
setup_shell() {
    print_section "Setting Up Shell Environment"

    # Install Zsh if requested
    if prompt_user "Install and configure Zsh?"; then
        if ! command_exists zsh; then
            print_info "Installing Zsh..."
            case "$DISTRO" in
                PACMAN) $PRIVILEGE_TOOL pacman -S --noconfirm zsh ;;
                APT) $PRIVILEGE_TOOL apt install -y zsh ;;
                DNF) $PRIVILEGE_TOOL dnf install -y zsh ;;
            esac
        fi

        if command_exists zsh; then
            if prompt_user "Change default shell to Zsh?"; then
                local zsh_path
                zsh_path="$(which zsh)"
                if chsh -s "$zsh_path"; then
                    print_success "Default shell changed to Zsh"
                    print_warning "Please log out and log back in to apply changes"
                else
                    print_error "Failed to change default shell"
                fi
            fi

            # Install Zsh plugins
            install_zsh_plugins
        else
            print_error "Zsh installation failed"
        fi
    else
        print_skip "Zsh setup"
    fi
}

# Install Zsh plugins
install_zsh_plugins() {
    local plugins_dir="$HOME/.config/zsh/plugins"
    local plugins=(
        "zsh-you-should-use:https://github.com/MichaelAquilina/zsh-you-should-use.git"
        "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting.git"
        "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions.git"
    )

    create_dir "$plugins_dir"

    for plugin_info in "${plugins[@]}"; do
        local plugin_name="${plugin_info%%:*}"
        local plugin_url="${plugin_info##*:}"
        local plugin_path="$plugins_dir/$plugin_name"

        if [[ -d "$plugin_path" ]]; then
            print_info "$plugin_name already installed"
            if prompt_user "Update $plugin_name?"; then
                (cd "$plugin_path" && git pull) && print_success "Updated $plugin_name"
            fi
        else
            print_info "Installing $plugin_name..."
            if git clone "$plugin_url" "$plugin_path"; then
                print_success "Installed $plugin_name"
            else
                print_error "Failed to install $plugin_name"
            fi
        fi
    done
}

# Setup SSH
setup_ssh() {
    print_section "Setting Up SSH"

    local ssh_dir="$HOME/.ssh"

    if [[ ! -f "$ssh_dir/id_rsa" ]]; then
        if prompt_user "Generate SSH key pair?"; then
            create_dir "$ssh_dir" 700

            local email
            print_color "$YELLOW" "Enter email for SSH key (or press Enter for $USER@$HOSTNAME): "
            read -r email
            email="${email:-$USER@$HOSTNAME}"

            ssh-keygen -t rsa -b 4096 -f "$ssh_dir/id_rsa" -N '' -C "$email" && {
                print_success "SSH key pair generated"
                cat "$ssh_dir/id_rsa.pub" >> "$ssh_dir/authorized_keys"
                chmod 600 "$ssh_dir/authorized_keys"
                print_info "Public key added to authorized_keys"
            }
        fi
    else
        print_info "SSH key already exists"
    fi
}

#======================================
# Summary and Cleanup
#======================================

# Print installation summary
print_installation_summary() {
    print_header "Installation Summary"

    if [[ ${#INSTALL_SUMMARY[@]} -gt 0 ]]; then
        print_section "Successful Operations"
        printf '%s\n' "${INSTALL_SUMMARY[@]}"
    fi

    if [[ ${#SKIPPED_ITEMS[@]} -gt 0 ]]; then
        print_section "Skipped Items"
        printf '%s\n' "${SKIPPED_ITEMS[@]}"
    fi

    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        print_section "Failed Operations"
        printf '%s\n' "${FAILED_ITEMS[@]}"
        echo
        print_warning "Some operations failed. Check the log file: $LOG_FILE"
    fi

    echo
    print_color "$GREEN$BOLD" "Installation completed!"
    print_info "Log file: $LOG_FILE"

    if [[ ${#FAILED_ITEMS[@]} -eq 0 ]]; then
        print_color "$GREEN" "🎉 All operations completed successfully!"
    else
        print_color "$YELLOW" "⚠️  Installation completed with ${#FAILED_ITEMS[@]} issues"
    fi

    echo
    print_info "Next steps:"
    print_color "$CYAN" "  • Restart your shell or run: exec \$SHELL"
    print_color "$CYAN" "  • Review configuration files in: $DOTFILES_DIR"
    print_color "$CYAN" "  • Use 'config status' to manage dotfiles"
    echo
}

#======================================
# Main Installation Flow
#======================================

# Main installation function
main() {
    # Initialize
    setup_logging

    print_header "Enhanced Dotfiles Installation"
    print_info "Starting installation for user: $USER"
    print_info "Log file: $LOG_FILE"

    # Pre-flight checks
    detect_os
    detect_privilege_tools

    if [[ "$CFG_OS" == "linux" ]]; then
        detect_linux_distro || exit 1
    fi

    # Installation steps
    local steps=(
        "install_dotfiles:Install dotfiles repository"
        "setup_user_dirs:Setup user directories"
        "install_packages:Install system packages"
        "setup_shell:Setup shell environment"
        "setup_ssh:Setup SSH configuration"
    )

    echo
    print_color "$YELLOW$BOLD" "The following steps will be performed:"
    for i in "${!steps[@]}"; do
        local step_desc="${steps[i]#*:}"
        print_color "$CYAN" "$((i + 1)). $step_desc"
    done

    echo
    if ! prompt_user "Continue with installation?"; then
        print_info "Installation cancelled by user"
        exit 0
    fi

    # Execute installation steps
    for step_info in "${steps[@]}"; do
        local step_func="${step_info%%:*}"
        local step_desc="${step_info#*:}"

        echo
        print_section "$step_desc"

        if "$step_func"; then
            print_success "$step_desc completed"
        else
            print_error "$step_desc failed"
        fi
    done

    # Show summary
    print_installation_summary

    log_message "INFO" "Installation process completed"
}

