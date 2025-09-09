#!/usr/bin/env bash

# Created By: srdusr
# Created On: Tue 06 Sep 2025 16:20:52 PM CAT
# Project: Dotfiles installation script

# Dependencies: git, curl

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
STATE_FILE="$HOME/.local/share/dotfiles_install_state"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
PACKAGES_FILE="packages.yml"

# Network connectivity check
CONNECTIVITY_CHECKED=false
INTERNET_AVAILABLE=false

# Installation tracking
INSTALL_SUMMARY=()
FAILED_ITEMS=()
SKIPPED_ITEMS=()
COMPLETED_STEPS=()

# Script options
RESUME_MODE=false
UPDATE_MODE=false
VERBOSE_MODE=false
DRY_RUN=false
FORCE_MODE=false
INSTALL_MODE="ask"  # ask, essentials, full, profile

# Global variables for system detection
CFG_OS=""
DISTRO=""
PACKAGE_MANAGER=""
PRIVILEGE_TOOL=""
PRIVILEGE_CACHED=false

# Essential tools needed by this script
ESSENTIAL_TOOLS=("git" "curl" "wget")
PACKAGE_TOOLS=("yq" "jq")

# Installation profiles
declare -A INSTALLATION_PROFILES=(
    ["essentials"]="Essential packages only (git, curl, wget, vim, zsh)"
    ["minimal"]="Minimal setup for basic development"
    ["dev"]="Full development environment"
    ["server"]="Server configuration"
    ["full"]="Complete installation with all packages"
)

# Installation steps configuration
declare -A INSTALLATION_STEPS=(
    ["setup_environment"]="Setup installation environment"
    ["check_connectivity"]="Check internet connectivity"
    ["install_dependencies"]="Install dependencies"
    ["install_dotfiles"]="Install dotfiles repository"
    ["setup_user_dirs"]="Setup user directories"
    ["install_essentials"]="Install essential tools"
    ["install_packages"]="Install system packages"
    ["setup_shell"]="Setup shell environment"
    ["setup_ssh"]="Setup SSH configuration"
    ["configure_services"]="Configure system services"
    ["setup_development"]="Setup development environment"
    ["apply_tweaks"]="Apply system tweaks"
    ["deploy_config"]="Deploy config command and dotfiles"
)

# Step order (important for dependencies)
STEP_ORDER=(
    "setup_environment"
    "check_connectivity"
    "install_dependencies"
    "install_dotfiles"
    "setup_user_dirs"
    "install_essentials"
    "install_packages"
    "setup_shell"
    "setup_ssh"
    "configure_services"
    "setup_development"
    "apply_tweaks"
    "deploy_config"
)

#======================================
# State Management Functions
#======================================

save_state() {
    local current_step="$1"
    local status="$2"

    mkdir -p "$(dirname "$STATE_FILE")"

    {
        echo "LAST_STEP=$current_step"
        echo "STEP_STATUS=$status"
        echo "TIMESTAMP=$(date +%s)"
        echo "RESUME_AVAILABLE=true"
        echo "PRIVILEGE_CACHED=$PRIVILEGE_CACHED"
        echo "INSTALL_MODE=$INSTALL_MODE"
        echo "COMPLETED_STEPS=(${COMPLETED_STEPS[*]})"
        echo "CFG_OS=$CFG_OS"
        echo "DISTRO=${DISTRO:-}"
        echo "PACKAGE_MANAGER=${PACKAGE_MANAGER:-}"
        echo "PRIVILEGE_TOOL=${PRIVILEGE_TOOL:-}"
        echo "CONNECTIVITY_CHECKED=$CONNECTIVITY_CHECKED"
        echo "INTERNET_AVAILABLE=$INTERNET_AVAILABLE"
    } > "$STATE_FILE"
}

load_state() {
    if [[ -f "$STATE_FILE" ]]; then
        source "$STATE_FILE"
        return 0
    else
        return 1
    fi
}

clear_state() {
    [[ -f "$STATE_FILE" ]] && rm -f "$STATE_FILE"
}

is_step_completed() {
    local step="$1"
    [[ " ${COMPLETED_STEPS[*]} " =~ " ${step} " ]]
}

mark_step_completed() {
    local step="$1"
    if ! is_step_completed "$step"; then
        COMPLETED_STEPS+=("$step")
    fi
    save_state "$step" "completed"
}

mark_step_failed() {
    local step="$1"
    save_state "$step" "failed"
}

#======================================
# UI Functions
#======================================

print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NOCOLOR}"

    if [[ -n "${LOG_FILE:-}" && -f "$LOG_FILE" ]]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
    fi
}

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

print_section() {
    local title="$1"
    echo
    print_color "$BLUE$BOLD" "▶ $title"
    print_color "$BLUE" "$(printf '%*s' $((${#title} + 2)) '' | tr ' ' '-')"
}

print_success() {
    local message="$1"
    print_color "$GREEN" "✓ $message"
    INSTALL_SUMMARY+=("✓ $message")
}

print_error() {
    local message="$1"
    print_color "$RED" "✗ $message" >&2
    FAILED_ITEMS+=("✗ $message")
}

print_warning() {
    local message="$1"
    print_color "$YELLOW" "⚠ $message"
}

print_info() {
    local message="$1"
    if [[ "$VERBOSE_MODE" == true ]] || [[ "${2:-}" == "always" ]]; then
        print_color "$CYAN" "ℹ $message"
    fi
}

print_skip() {
    local message="$1"
    print_color "$YELLOW" "⏭ $message"
    SKIPPED_ITEMS+=("⏭ $message")
}

print_dry_run() {
    local message="$1"
    print_color "$MAGENTA" "[DRY RUN] $message"
}

#======================================
# Network Connectivity Functions
#======================================

check_internet_connectivity() {
    if [[ "$CONNECTIVITY_CHECKED" == true ]]; then
        return $([[ "$INTERNET_AVAILABLE" == true ]] && echo 0 || echo 1)
    fi

    print_section "Checking Internet Connectivity"

    local test_urls=("8.8.8.8" "1.1.1.1" "google.com" "github.com")

    for url in "${test_urls[@]}"; do
        if ping -c 1 -W 2 "$url" &>/dev/null || curl -s --connect-timeout 5 "https://$url" &>/dev/null; then
            INTERNET_AVAILABLE=true
            CONNECTIVITY_CHECKED=true
            print_success "Internet connectivity confirmed"
            return 0
        fi
    done

    INTERNET_AVAILABLE=false
    CONNECTIVITY_CHECKED=true
    print_error "No internet connectivity detected"

    # Try to connect to WiFi or prompt user
    attempt_network_connection

    return 1
}

attempt_network_connection() {
    print_warning "Attempting to establish network connection..."

    # Try NetworkManager
    if command_exists nmcli; then
        print_info "Available WiFi networks:"
        nmcli device wifi list 2>/dev/null || print_warning "Could not list WiFi networks"

        if prompt_user "Would you like to connect to a WiFi network?"; then
            print_color "$YELLOW" "Enter WiFi network name (SSID): "
            read -r wifi_ssid
            if [[ -n "$wifi_ssid" ]]; then
                print_color "$YELLOW" "Enter WiFi password: "
                read -rs wifi_password
                echo

                if execute_with_privilege "nmcli device wifi connect '$wifi_ssid' password '$wifi_password'"; then
                    print_success "Connected to WiFi network: $wifi_ssid"
                    # Re-check connectivity
                    CONNECTIVITY_CHECKED=false
                    check_internet_connectivity
                    return $?
                else
                    print_error "Failed to connect to WiFi network"
                fi
            fi
        fi
    fi

    # Try other connection methods
    if command_exists iwctl; then
        print_info "You can also connect manually using iwctl"
    fi

    return 1
}

#======================================
# System Detection Functions
#======================================

detect_os() {
    case "$(uname -s)" in
        Linux)   CFG_OS="linux" ;;
        Darwin)  CFG_OS="macos" ;;
        MINGW*|MSYS*|CYGWIN*) CFG_OS="windows" ;;
        *)       CFG_OS="unknown" ;;
    esac

    print_info "Detected OS: $CFG_OS" "always"
}

detect_privilege_tools() {
    if [[ "$(id -u)" -eq 0 ]]; then
        PRIVILEGE_TOOL=""
        print_info "Running as root, no privilege escalation needed"
        return 0
    fi

    for tool in sudo doas pkexec; do
        if command -v "$tool" &>/dev/null; then
            PRIVILEGE_TOOL="$tool"
            print_success "Using privilege escalation tool: $PRIVILEGE_TOOL"
            return 0
        fi
    done

    print_warning "No privilege escalation tool found (sudo, doas, pkexec)"
    PRIVILEGE_TOOL=""
    return 1
}

test_privilege_access() {
    if [[ "$PRIVILEGE_CACHED" == true ]]; then
        return 0
    fi

    if [[ -z "$PRIVILEGE_TOOL" ]]; then
        return 0  # Running as root or no privilege needed
    fi

    print_info "Testing privilege access..."
    if "$PRIVILEGE_TOOL" -v &>/dev/null || echo "test" | "$PRIVILEGE_TOOL" -S true &>/dev/null; then
        PRIVILEGE_CACHED=true
        print_success "Privilege access confirmed"
        return 0
    else
        print_error "Failed to obtain privilege access"
        return 1
    fi
}

detect_package_manager() {
    # First try to detect from OS release files
    if [[ "$CFG_OS" == "linux" && -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
            arch|manjaro|endeavouros|artix)
                DISTRO="$ID"
                PACKAGE_MANAGER="pacman" ;;
            debian|ubuntu|mint|pop|elementary|zorin)
                DISTRO="$ID"
                PACKAGE_MANAGER="apt" ;;
            fedora|rhel|centos|rocky|almalinux)
                DISTRO="$ID"
                PACKAGE_MANAGER="dnf" ;;
            opensuse*|sles)
                DISTRO="$ID"
                PACKAGE_MANAGER="zypper" ;;
            gentoo|funtoo)
                DISTRO="$ID"
                PACKAGE_MANAGER="portage" ;;
            alpine)
                DISTRO="$ID"
                PACKAGE_MANAGER="apk" ;;
            void)
                DISTRO="$ID"
                PACKAGE_MANAGER="xbps" ;;
            nixos)
                DISTRO="$ID"
                PACKAGE_MANAGER="nix" ;;
            *)
                print_warning "Unknown distribution: $ID, trying to detect package manager directly"
                ;;
        esac
    elif [[ "$CFG_OS" == "macos" ]]; then
        DISTRO="macos"
        if command -v brew &>/dev/null; then
            PACKAGE_MANAGER="brew"
        else
            PACKAGE_MANAGER="brew-install"  # Will install homebrew
        fi
    fi

    # Fallback: detect by available commands
    if [[ -z "$PACKAGE_MANAGER" ]]; then
        local managers=(
            "pacman:pacman"
            "apt:apt"
            "dnf:dnf"
            "yum:yum"
            "zypper:zypper"
            "emerge:portage"
            "apk:apk"
            "xbps-install:xbps"
            "nix-env:nix"
            "pkg:pkg"
            "brew:brew"
        )

        for manager in "${managers[@]}"; do
            local cmd="${manager%:*}"
            local name="${manager#*:}"
            if command -v "$cmd" &>/dev/null; then
                PACKAGE_MANAGER="$name"
                break
            fi
        done
    fi

    if [[ -n "$PACKAGE_MANAGER" ]]; then
        print_success "Detected package manager: $PACKAGE_MANAGER"
        [[ -n "$DISTRO" ]] && print_info "Distribution: $DISTRO"
        return 0
    else
        print_error "Could not detect package manager"
        return 1
    fi
}

#======================================
# Utility Functions
#======================================

command_exists() {
    command -v "$1" &>/dev/null
}

execute_command() {
    local cmd="$*"

    if [[ "$DRY_RUN" == true ]]; then
        print_dry_run "$cmd"
        return 0
    fi

    if [[ "$VERBOSE_MODE" == true ]]; then
        print_info "Running: $cmd"
    fi

    eval "$cmd"
}

execute_with_privilege() {
    local cmd="$*"

    if [[ "$DRY_RUN" == true ]]; then
        if [[ -n "$PRIVILEGE_TOOL" ]]; then
            print_dry_run "$PRIVILEGE_TOOL $cmd"
        else
            print_dry_run "$cmd"
        fi
        return 0
    fi

    if [[ -n "$PRIVILEGE_TOOL" ]]; then
        if [[ "$PRIVILEGE_CACHED" != true ]]; then
            test_privilege_access || return 1
        fi
        eval "$PRIVILEGE_TOOL $cmd"
    else
        eval "$cmd"
    fi
}

prompt_user() {
    local question="$1"
    local default="${2:-Y}"
    local response

    if [[ "$FORCE_MODE" == true ]]; then
        print_info "Auto-answering '$question' with: $default"
        [[ "$default" =~ ^[Yy] ]] && return 0 || return 1
    fi

    while true; do
        if [[ "$default" == "Y" ]]; then
            print_color "$YELLOW" "$question [Y/n]: "
        else
            print_color "$YELLOW" "$question [y/N]: "
        fi

        read -r response

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

create_dir() {
    local dir="$1"
    local permissions="${2:-755}"

    if [[ "$DRY_RUN" == true ]]; then
        print_dry_run "Create directory: $dir (mode: $permissions)"
        return 0
    fi

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

setup_logging() {
    local log_dir
    log_dir="$(dirname "$LOG_FILE")"

    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" || {
            print_error "Failed to create log directory: $log_dir"
            exit 1
        }
    fi

    {
        echo "======================================="
        echo "Dotfiles Installation Log"
        echo "Date: $(date)"
        echo "User: $USER"
        echo "Host: ${HOSTNAME:-$(hostname)}"
        echo "OS: $(uname -s)"
        echo "Install Mode: $INSTALL_MODE"
        echo "======================================="
        echo
    } > "$LOG_FILE"

    print_info "Log file initialized: $LOG_FILE" "always"
}

get_package_name() {
    local package="$1"
    local packages_file="${2:-}"

    # If packages.yml is available, check for distribution-specific mappings
    if [[ -n "$packages_file" ]] && [[ -f "$packages_file" ]] && command_exists yq; then
        local distro_package=""

        # Try to get package name for current distribution
        case "$DISTRO" in
            arch|manjaro|endeavouros|artix)
                distro_package=$(yq eval ".arch.$package" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")
                ;;
            debian|ubuntu|mint|pop|elementary|zorin)
                distro_package=$(yq eval ".debian.$package" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")
                ;;
            fedora|rhel|centos|rocky|almalinux)
                distro_package=$(yq eval ".rhel.$package" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")
                ;;
            opensuse*|sles)
                distro_package=$(yq eval ".opensuse.$package" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")
                ;;
            gentoo|funtoo)
                distro_package=$(yq eval ".gentoo.$package" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")
                ;;
            macos)
                distro_package=$(yq eval ".macos[]" "$packages_file" 2>/dev/null | grep "^$package$" || echo "")
                ;;
        esac

        # Return the distribution-specific package name if found
        if [[ -n "$distro_package" ]]; then
            echo "$distro_package"
            return 0
        fi
    fi

    # Fallback to original package name
    echo "$package"
}

get_package_use_flags() {
    local package="$1"
    local packages_file="${2:-}"

    # Only relevant for Gentoo/Portage
    if [[ "$PACKAGE_MANAGER" != "portage" ]]; then
        echo ""
        return 0
    fi

    if [[ -n "$packages_file" ]] && [[ -f "$packages_file" ]] && command_exists yq; then
        local use_flags
        use_flags=$(yq eval ".gentoo_use_flags.$package" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")
        echo "$use_flags"
    else
        echo ""
    fi
}

#======================================
# Dependency Installation Functions
#======================================

install_dependencies_if_missing() {
    print_section "Checking for dependencies git, wget/curl"
    save_state "install_dependencies" "started"

    local missing_deps=()
    local failed_deps=()

    # Check for missing essential tools
    for tool in "${ESSENTIAL_TOOLS[@]}"; do
        if ! command_exists "$tool"; then
            missing_deps+=("$tool")
        fi
    done

    # If no internet and dependencies are missing, try offline packages
    if [[ "$INTERNET_AVAILABLE" != true ]] && [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_warning "No internet connection available"
        print_info "Attempting to install dependencies from local packages..."

        # Try to install from local package cache
        for tool in "${missing_deps[@]}"; do
            if install_package_offline "$tool"; then
                print_success "Installed $tool from local cache"
            else
                failed_deps+=("$tool")
            fi
        done
    elif [[ ${#missing_deps[@]} -gt 0 ]]; then
        # Online installation
        print_info "Installing missing dependencies: ${missing_deps[*]}"
        update_package_database

        for tool in "${missing_deps[@]}"; do
            if install_single_package "$tool" "dependency"; then
                print_success "Installed dependency: $tool"
            else
                failed_deps+=("$tool")
            fi
        done
    fi

    if [[ ${#failed_deps[@]} -gt 0 ]]; then
        print_error "Failed to install dependencies: ${failed_deps[*]}"
        mark_step_failed "install_dependencies"
        return 1
    else
        mark_step_completed "install_dependencies"
        return 0
    fi
}

install_package_offline() {
    local package="$1"

    case "$PACKAGE_MANAGER" in
        pacman)
            # Check if package is in cache
            if execute_with_privilege "pacman -U /var/cache/pacman/pkg/${package}-*.pkg.tar.*" 2>/dev/null; then
                return 0
            fi
            ;;
        apt)
            # Try from local cache
            if execute_with_privilege "apt-get install --no-download '$package'" 2>/dev/null; then
                return 0
            fi
            ;;
    esac

    return 1
}

#======================================
# Package Management Functions
#======================================

install_single_package() {
    local package="$1"
    local package_type="${2:-system}"
    local packages_file="${3:-}"

    # Get the correct package name for this distro
    local pkg_name
    pkg_name=$(get_package_name "$package" "$packages_file")

    # Get USE flags for Gentoo
    local use_flags
    use_flags=$(get_package_use_flags "$package" "$packages_file")

    print_info "Installing $package_type package: $pkg_name"

    case "$PACKAGE_MANAGER" in
        pacman)
            execute_with_privilege "pacman -S --noconfirm '$pkg_name'" ;;
        apt)
            execute_with_privilege "apt-get install -y '$pkg_name'" ;;
        dnf)
            execute_with_privilege "dnf install -y '$pkg_name'" ;;
        yum)
            execute_with_privilege "yum install -y '$pkg_name'" ;;
        zypper)
            execute_with_privilege "zypper install -y '$pkg_name'" ;;
        portage)
            local emerge_cmd="emerge"
            if [[ -n "$use_flags" ]]; then
                emerge_cmd="USE='$use_flags' emerge"
                print_info "Using USE flags for $pkg_name: $use_flags"
            fi
            execute_with_privilege "$emerge_cmd '$pkg_name'" ;;
        apk)
            execute_with_privilege "apk add '$pkg_name'" ;;
        xbps)
            execute_with_privilege "xbps-install -y '$pkg_name'" ;;
        nix)
            execute_command "nix-env -iA nixpkgs.$pkg_name" ;;
        brew)
            execute_command "brew install '$pkg_name'" ;;
        brew-install)
            print_error "Homebrew not installed. Please install it first."
            return 1 ;;
        *)
            print_error "Package manager '$PACKAGE_MANAGER' not supported"
            return 1 ;;
    esac
}

update_package_database() {
    print_info "Updating package database..."

    case "$PACKAGE_MANAGER" in
        pacman)
            execute_with_privilege "pacman -Sy" ;;
        apt)
            execute_with_privilege "apt-get update" ;;
        dnf)
            execute_with_privilege "dnf check-update" || true ;;
        yum)
            execute_with_privilege "yum check-update" || true ;;
        zypper)
            execute_with_privilege "zypper refresh" ;;
        portage)
            execute_with_privilege "emerge --sync" ;;
        apk)
            execute_with_privilege "apk update" ;;
        xbps)
            execute_with_privilege "xbps-install -S" ;;
        brew)
            execute_command "brew update" ;;
        *)
            print_info "Package database update not needed for $PACKAGE_MANAGER" ;;
    esac
}

install_homebrew() {
    if command_exists brew; then
        print_info "Homebrew already installed"
        return 0
    fi

    print_info "Installing Homebrew..."
    if execute_command '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'; then
        print_success "Homebrew installed"
        PACKAGE_MANAGER="brew"

        # Add to PATH for current session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        return 0
    else
        print_error "Failed to install Homebrew"
        return 1
    fi
}

install_yq() {
    if command_exists yq; then
        print_info "yq already installed"
        return 0
    fi

    print_info "Installing yq..."

    local bin_dir="$HOME/.local/bin"
    create_dir "$bin_dir"

    local yq_path="$bin_dir/yq"
    local yq_url=""

    case "$(uname -m)" in
        x86_64|amd64)
            yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" ;;
        aarch64|arm64)
            yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_arm64" ;;
        armv7l)
            yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_arm" ;;
        *)
            print_error "Unsupported architecture: $(uname -m)"
            return 1 ;;
    esac

    if execute_command "curl -L '$yq_url' -o '$yq_path'"; then
        execute_command "chmod +x '$yq_path'"

        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
            export PATH="$bin_dir:$PATH"
        fi

        print_success "yq installed successfully"
        return 0
    else
        print_error "Failed to install yq"
        return 1
    fi
}

parse_packages_from_yaml() {
    local packages_file="$1"
    local section="$2"
    local packages=()

    if [[ ! -f "$packages_file" ]]; then
        print_warning "Package file not found: $packages_file"
        return 1
    fi

    if ! command_exists yq; then
        print_error "yq not available for parsing packages.yml"
        return 1
    fi

    # Try to parse packages from the specified section
    if yq eval ".$section" "$packages_file" &>/dev/null; then
        mapfile -t packages < <(yq eval ".$section[]" "$packages_file" 2>/dev/null | grep -v "^null$" || true)
    fi

    # Output packages
    printf '%s\n' "${packages[@]}"
}

install_packages_from_yaml() {
    local packages_file="$1"
    local profile="${2:-essentials}"
    local failed_packages=()
    local installed_count=0

    print_section "Installing Packages (Profile: $profile)"

    if [[ ! -f "$packages_file" ]]; then
        print_warning "Package file not found: $packages_file, skipping package installation"
        return 0
    fi

    # Define sections to install based on profile
    local sections=()
    case "$profile" in
        essentials)
            sections=("common" "essentials") ;;
        minimal)
            sections=("common" "essentials" "minimal") ;;
        dev)
            sections=("common" "essentials" "dev") ;;
        server)
            sections=("common" "essentials" "server") ;;
        full)
            sections=("common" "essentials" "dev" "server" "desktop") ;;
        *)
            if [[ -f "profiles/$profile.yml" ]]; then
                packages_file="profiles/$profile.yml"
                sections=("packages")
            else
                print_error "Unknown profile: $profile"
                return 1
            fi
            ;;
    esac

    # Install packages from each section
    for section in "${sections[@]}"; do
        print_info "Installing packages from section: $section"

        local packages
        mapfile -t packages < <(parse_packages_from_yaml "$packages_file" "$section")

        if [[ ${#packages[@]} -eq 0 ]]; then
            print_info "No packages found in section: $section"
            continue
        fi

        print_info "Found ${#packages[@]} packages in section $section"

        for package in "${packages[@]}"; do
            [[ -z "$package" ]] && continue

            if install_single_package "$package" "$section" "$packages_file"; then
                print_success "Installed: $package"
                ((installed_count++))
            else
                print_error "Failed to install: $package"
                failed_packages+=("$package")
            fi
        done
    done

    print_info "Package installation summary:"
    print_color "$GREEN" "  Installed: $installed_count"
    print_color "$RED" "  Failed: ${#failed_packages[@]}"

    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        print_warning "Failed packages: ${failed_packages[*]}"
        print_info "Failed packages will be listed in the final summary"
        return 0
    else
        print_success "All packages installed successfully"
        return 0
    fi
}

#======================================
# Dotfiles Management System (Config Command)
#======================================

install_config_command() {
    print_info "Installing config command for dotfiles management"

    # Known function files where cfg might already be defined
    local function_files=(
        "$HOME/.config/zsh/user/functions.zsh"
        "$HOME/.bashrc"
    )

    # Check if cfg is already defined
    local cfg_defined=false
    for f in "${function_files[@]}"; do
        if [[ -f "$f" ]] && grep -q '^\s*cfg\s*()' "$f"; then
            cfg_defined=true
            # Source the file to make cfg available in current session
            # Only source if not already sourced
            if ! type cfg >/dev/null 2>&1; then
                # shellcheck disable=SC1090
                source "$f"
                print_info "Sourced cfg from $f"
            fi
            break
        fi
    done

    if [[ "$cfg_defined" == true ]]; then
        print_info "cfg function already defined, no need to append"
        return
    fi

    # Determine current shell
    local current_shell
    current_shell=$(basename "$SHELL")

    local profile_files=()

    case "$current_shell" in
        bash)
            profile_files+=("$HOME/.bashrc")
            [[ -f "$HOME/.profile" ]] && profile_files+=("$HOME/.profile")
            ;;
        zsh)
            profile_files+=("$HOME/.zshrc")
            [[ -f "$HOME/.config/zsh/.zshrc" ]] && profile_files+=("$HOME/.config/zsh/.zshrc")
            [[ -f "$HOME/.profile" ]] && profile_files+=("$HOME/.profile")
            ;;
        *)
            [[ -f "$HOME/.profile" ]] && profile_files+=("$HOME/.profile")
            ;;
    esac

    # If no profile files exist, create .bashrc
    if [[ ${#profile_files[@]} -eq 0 ]]; then
        profile_files+=("$HOME/.bashrc")
        touch "$HOME/.bashrc"
    fi

    # Append cfg function to profiles if not already present
    for profile in "${profile_files[@]}"; do
        if [[ -w "$profile" ]] && ! grep -q "# Dotfiles config function" "$profile" 2>/dev/null; then
            cat >> "$profile" << 'EOF'

# Dotfiles Management System
if [[ -d "$HOME/.cfg" && -d "$HOME/.cfg/refs" ]]; then
    # Core git wrapper with repository as work-tree
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
        local target_dir=""
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
                        local rel_path
                        if [[ "$file_path" == /* ]]; then
                            rel_path="$(basename "$file_path")"
                        else
                            rel_path="$file_path"
                        fi
                        repo_path="$target_dir/$rel_path"
                    else
                        repo_path="$(_repo_path "$file_path")"
                    fi

                    local full_repo_path="$HOME/.cfg/$repo_path"
                    mkdir -p "$(dirname "$full_repo_path")"
                    cp -a "$file_path" "$full_repo_path"

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
                    local full_repo_path="$HOME/.cfg/$repo_file"
                    local sys_file="$(_sys_path "$repo_file")"  # destination only

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
            checkout)
                echo "Checking out dotfiles from .cfg..."
                _config ls-files | while read -r repo_file; do
                    local full_repo_path="$HOME/.cfg/$repo_file"
                    local sys_file="$(_sys_path "$repo_file")"

                    if [[ -e "$full_repo_path" && -n "$sys_file" ]]; then
                        local dest_dir
                        dest_dir="$(dirname "$sys_file")"

                        # Create destination if it doesn't exist
                        if [[ "$sys_file" == /* && "$sys_file" != "$HOME/"* ]]; then
                            _sudo_prompt mkdir -p "$dest_dir"
                            _sudo_prompt cp -a "$full_repo_path" "$sys_file"
                        else
                            mkdir -p "$dest_dir"
                            cp -a "$full_repo_path" "$sys_file"
                        fi

                        echo "Checked out: $repo_file -> $sys_file"
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
EOF
            print_success "Added config function to $profile"
        else
            print_info "Config function already exists in $profile or file not writable"
        fi
    done

    return 0
}


deploy_config() {
    print_section "Deploying Configuration"
    save_state "deploy_config" "started"

    # Install and setup the config command first
    install_config_command

    # Deploy dotfiles from repository to system
    if [[ -d "$DOTFILES_DIR" ]]; then
        print_info "Deploying dotfiles from repository to system locations..."

        # Source shell configuration to make config function available
        reload_shell_config

        # Check if config function is available
        if declare -f config >/dev/null 2>&1 || type config >/dev/null 2>&1; then
            print_info "Config function available, deploying files..."

            if [[ "$DRY_RUN" == true ]]; then
                print_dry_run "config restore ."
                print_dry_run "config reset"
                print_dry_run "config deploy"
            else
                # Use the config function to deploy files
                if config deploy; then
                    print_success "Dotfiles deployed successfully"
                else
                    print_warning "Some files may have failed to deploy"
                fi
            fi
        else
            print_info "Config function not available, using manual deployment..."
            manual_deploy_dotfiles
        fi

        # Set appropriate permissions
        set_dotfile_permissions

    else
        print_warning "Dotfiles directory not found, skipping deployment"
    fi

    mark_step_completed "deploy_config"
}

reload_shell_config() {
    print_info "Reloading shell configuration..."

    # Source common shell files if they exist
    local shell_files=()

    case "$(basename "$SHELL")" in
        bash)
            shell_files+=("$HOME/.bashrc" "$HOME/.profile")
            ;;
        zsh)
            shell_files+=("$HOME/.zshrc" "$HOME/.config/zsh/.zshrc" "$HOME/.profile")
            ;;
        *)
            shell_files+=("$HOME/.profile")
            ;;
    esac

    for shell_file in "${shell_files[@]}"; do
        if [[ -f "$shell_file" ]]; then
            print_info "Sourcing: $shell_file"
            # shellcheck disable=SC1090
            source "$shell_file" 2>/dev/null || print_warning "Failed to source $shell_file"
        fi
    done
}

#======================================
# Installation Step Functions
#======================================

setup_environment() {
    print_section "Setting Up Environment"
    save_state "setup_environment" "started"

    detect_os
    detect_privilege_tools
    detect_package_manager || {
        print_error "Cannot proceed without a supported package manager"
        mark_step_failed "setup_environment"
        return 1
    }

    if [[ -n "$PRIVILEGE_TOOL" ]]; then
        test_privilege_access || {
            print_error "Cannot obtain necessary privileges"
            mark_step_failed "setup_environment"
            return 1
        }
    fi

    mark_step_completed "setup_environment"
}

check_connectivity() {
    print_section "Checking Connectivity"
    save_state "check_connectivity" "started"

    if check_internet_connectivity; then
        mark_step_completed "check_connectivity"
        return 0
    else
        print_warning "Limited internet connectivity - some features may be unavailable"
        mark_step_completed "check_connectivity"
        return 0  # Don't fail completely
    fi
}

install_dependencies() {
    print_section "Installing Dependencies"
    save_state "install_dependencies" "started"

    if install_dependencies_if_missing; then
        mark_step_completed "install_dependencies"
        return 0
    else
        mark_step_failed "install_dependencies"
        return 1
    fi
}

install_dotfiles() {
    print_section "Installing Dotfiles"
    save_state "install_dotfiles" "started"

    local update=false

    # Check internet connectivity for git operations
    if [[ "$INTERNET_AVAILABLE" != true ]]; then
        print_warning "No internet connectivity - skipping dotfiles installation"
        mark_step_completed "install_dotfiles"
        return 0
    fi

    if [[ -d "$DOTFILES_DIR" ]]; then
        if [[ "$UPDATE_MODE" == true ]] || prompt_user "Dotfiles repository already exists. Update it?"; then
            print_info "Updating existing dotfiles..."
            if execute_command "git --git-dir='$DOTFILES_DIR' --work-tree='$HOME/.cfg' pull origin main"; then
                update=true
                print_success "Dotfiles updated successfully"
            else
                print_error "Failed to pull updates"
                mark_step_failed "install_dotfiles"
                return 1
            fi
        else
            print_skip "Skipping dotfiles update"
            mark_step_completed "install_dotfiles"
            return 0
        fi
    else
        print_info "Cloning dotfiles repository..."
        if execute_command "git clone --bare '$DOTFILES_URL' '$DOTFILES_DIR'"; then
            print_success "Dotfiles repository cloned"
        else
            print_error "Failed to clone dotfiles repository"
            mark_step_failed "install_dotfiles"
            return 1
        fi
    fi

    # Configure the repository
    execute_command "git --git-dir='$DOTFILES_DIR' --work-tree='$HOME/.cfg' config status.showUntrackedFiles no"

    mark_step_completed "install_dotfiles"
    print_success "Dotfiles installed successfully"
}

setup_user_dirs() {
    print_section "Setting Up User Directories"
    save_state "setup_user_dirs" "started"

    local directories=('.cache' '.config' '.local/bin' '.local/share' '.scripts')

    for dir in "${directories[@]}"; do
        create_dir "$HOME/$dir"
    done

    # Set up XDG directories
    if command_exists xdg-user-dirs-update; then
        execute_command "xdg-user-dirs-update"
        print_success "XDG user directories configured"
    fi

    mark_step_completed "setup_user_dirs"
}

install_essentials() {
    print_section "Installing Essential Tools"
    save_state "install_essentials" "started"

    # Install package processing tools first
    for tool in "${PACKAGE_TOOLS[@]}"; do
        if ! command_exists "$tool"; then
            case "$tool" in
                yq)
                    if install_yq; then
                        print_success "Installed package tool: $tool"
                    else
                        print_error "Failed to install package tool: $tool"
                        mark_step_failed "install_essentials"
                        return 1
                    fi
                    ;;
                jq)
                    if install_single_package "jq" "essential"; then
                        print_success "Installed package tool: $tool"
                    else
                        print_error "Failed to install package tool: $tool"
                        mark_step_failed "install_essentials"
                        return 1
                    fi
                    ;;
            esac
        else
            print_info "Package tool already available: $tool"
        fi
    done

    mark_step_completed "install_essentials"
}

install_packages() {
    print_section "Installing Packages"
    save_state "install_packages" "started"

    # Skip if essentials-only mode
    if [[ "$INSTALL_MODE" == "essentials" ]]; then
        print_skip "Package installation (essentials-only mode)"
        mark_step_completed "install_packages"
        return 0
    fi

    # Skip if no internet and packages require download
    if [[ "$INTERNET_AVAILABLE" != true ]]; then
        print_warning "No internet connectivity - skipping package installation"
        mark_step_completed "install_packages"
        return 0
    fi

    # Determine profile to install
    local profile="$INSTALL_MODE"
    if [[ "$INSTALL_MODE" == "ask" ]]; then
        profile="dev"  # Default
    fi

    # Change to home directory to find packages.yml
    local original_dir="$PWD"
    cd "$HOME" 2>/dev/null || true

    # Look for packages.yml in common locations
    local packages_files=("$PACKAGES_FILE" "common/$PACKAGES_FILE" ".cfg/common/$PACKAGES_FILE")
    local found_packages_file=""

    for pf in "${packages_files[@]}"; do
        if [[ -f "$pf" ]]; then
            found_packages_file="$pf"
            break
        fi
    done

    if [[ -n "$found_packages_file" ]]; then
        if install_packages_from_yaml "$found_packages_file" "$profile"; then
            mark_step_completed "install_packages"
        else
            print_warning "Some packages failed to install, but continuing..."
            mark_step_completed "install_packages"  # Don't fail the whole installation
        fi
    else
        print_warning "packages.yml not found, skipping package installation"
        mark_step_completed "install_packages"
    fi

    cd "$original_dir" 2>/dev/null || true
}

setup_shell() {
    print_section "Setting Up Shell Environment"
    save_state "setup_shell" "started"

    if command_exists zsh; then
        if [[ "$FORCE_MODE" == true ]] || prompt_user "Change default shell to Zsh?"; then
            local zsh_path
            zsh_path="$(command -v zsh)"
            if execute_with_privilege "chsh -s '$zsh_path' '$USER'"; then
                print_success "Default shell changed to Zsh"
                print_warning "Please log out and log back in to apply changes"
            else
                print_error "Failed to change default shell"
            fi
        fi
    else
        print_warning "Zsh not installed, skipping shell setup"
    fi

    # Install Zsh plugins if in dotfiles directory
    if [[ -f "$HOME/.zshrc" || -f "$HOME/.config/zsh/.zshrc" ]]; then
        install_zsh_plugins
    fi

    mark_step_completed "setup_shell"
}

install_zsh_plugins() {
    if [[ "$INTERNET_AVAILABLE" != true ]]; then
        print_warning "No internet connectivity - skipping Zsh plugins installation"
        return 0
    fi

    local zsh_plugins_dir="$HOME/.config/zsh/plugins"

    print_info "Installing Zsh plugins..."
    create_dir "$HOME/.config/zsh"
    create_dir "$zsh_plugins_dir"

    local plugins=(
        "zsh-you-should-use:https://github.com/MichaelAquilina/zsh-you-should-use.git"
        "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting.git"
        "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions.git"
    )

    for plugin_info in "${plugins[@]}"; do
        local plugin_name="${plugin_info%:*}"
        local plugin_url="${plugin_info#*:}"
        local plugin_dir="$zsh_plugins_dir/$plugin_name"

        if [[ ! -d "$plugin_dir" ]]; then
            print_info "Installing $plugin_name..."
            if execute_command "git clone '$plugin_url' '$plugin_dir'"; then
                print_success "Installed $plugin_name"
            else
                print_error "Failed to install $plugin_name"
            fi
        else
            print_info "$plugin_name already installed"
        fi
    done
}

setup_ssh() {
    print_section "Setting Up SSH"
    save_state "setup_ssh" "started"

    local ssh_dir="$HOME/.ssh"

    if [[ ! -f "$ssh_dir/id_rsa" && ! -f "$ssh_dir/id_ed25519" ]]; then
        if [[ "$FORCE_MODE" == true ]] || prompt_user "Generate SSH key pair?"; then
            create_dir "$ssh_dir" 700

            local email="${USER}@${HOSTNAME:-$(hostname)}"
            local key_file="$ssh_dir/id_ed25519"

            if execute_command "ssh-keygen -t ed25519 -f '$key_file' -N '' -C '$email'"; then
                print_success "SSH key pair generated (Ed25519)"
                execute_command "chmod 600 '$key_file'"
                execute_command "chmod 644 '$key_file.pub'"

                if [[ "$DRY_RUN" != true ]] && [[ -f "$key_file.pub" ]]; then
                    print_info "Your public key:"
                    print_color "$GREEN" "$(cat "$key_file.pub")"
                    print_info "Copy this key to your Git hosting service"
                fi
            else
                print_error "Failed to generate SSH key"
                mark_step_failed "setup_ssh"
                return 1
            fi
        fi
    else
        print_info "SSH key already exists"
    fi

    mark_step_completed "setup_ssh"
}

# Helper function to detect the init system
detect_init_system() {
    if [ -d /run/systemd/system ]; then
        echo "systemd"
    elif command -v rc-service &>/dev/null; then
        echo "openrc"
    elif [ -d /etc/sv ]; then
        echo "runit"
    elif command -v service &>/dev/null; then
        echo "sysvinit"
    else
        echo "unknown"
    fi
}

# Helper function to manage a service (enable/start)
manage_service() {
    local action="$1"
    local service="$2"
    local init_system="$3"
    local success=false

    case "$init_system" in
        systemd)
            if [ "$action" == "enable" ]; then
                execute_command "$PRIVILEGE_TOOL systemctl enable '$service'"
                success=$?
            elif [ "$action" == "start" ]; then
                execute_command "$PRIVILEGE_TOOL systemctl start '$service'"
                success=$?
            fi
            ;;
        openrc)
            if [ "$action" == "enable" ]; then
                execute_command "$PRIVILEGE_TOOL rc-update add '$service' default"
                success=$?
            elif [ "$action" == "start" ]; then
                execute_command "$PRIVILEGE_TOOL rc-service '$service' start"
                success=$?
            fi
            ;;
        runit)
            if [ "$action" == "enable" ]; then
                # Runit services are enabled by creating a symlink in the run level directory
                execute_command "$PRIVILEGE_TOOL ln -sf /etc/sv/'$service' /var/service/"
                success=$?
            elif [ "$action" == "start" ]; then
                # The 'start' action is usually implied by the symlink, but you can
                # manually start it if needed
                execute_command "$PRIVILEGE_TOOL sv start '$service'"
                success=$?
            fi
            ;;
        sysvinit|unknown)
            # Use the generic 'service' command
            if [ "$action" == "start" ]; then
                execute_command "$PRIVILEGE_TOOL service '$service' start"
                success=$?
            fi
            # Enabling is system-dependent for sysvinit/unknown; we'll check for chkconfig
            if [ "$action" == "enable" ]; then
                if command -v chkconfig &>/dev/null; then
                    execute_command "$PRIVILEGE_TOOL chkconfig '$service' on"
                    success=$?
                else
                    success=0
                fi
            fi
            ;;
        *)
            print_error "Unknown init system: $init_system. Cannot $action service '$service'."
            return 1
            ;;
    esac

    return $((1 - success))
}

# Configure system services
configure_services() {
    print_section "Configuring System Services"
    save_state "configure_services" "started"

    if [[ "$CFG_OS" != "linux" ]]; then
        print_skip "Service configuration (not supported on $CFG_OS)"
        mark_step_completed "configure_services"
        return 0
    fi

    # Detect the init system once
    local INIT_SYSTEM=$(detect_init_system)
    print_info "Detected Init System: $INIT_SYSTEM"

    # Enable TLP for laptop power management
    if command_exists tlp; then
        print_info "TLP is installed"
        if [[ "$FORCE_MODE" == true ]] || prompt_user "Enable TLP power management service?"; then
            if manage_service "enable" "tlp" "$INIT_SYSTEM"; then
                manage_service "start" "tlp" "$INIT_SYSTEM"
                print_success "TLP enabled and started"
            else
                print_error "Failed to enable TLP"
            fi
        fi
    elif [[ "$FORCE_MODE" == true ]] || prompt_user "Install and enable TLP for better battery life?"; then
        case "$DISTRO" in
            PACMAN) execute_command "$PRIVILEGE_TOOL pacman -S --noconfirm tlp tlp-rdw" ;;
            APT) execute_command "$PRIVILEGE_TOOL apt install -y tlp tlp-rdw" ;;
            DNF) execute_command "$PRIVILEGE_TOOL dnf install -y tlp tlp-rdw" ;;
        esac

        if command_exists tlp; then
            manage_service "enable" "tlp" "$INIT_SYSTEM"
            manage_service "start" "tlp" "$INIT_SYSTEM"
            print_success "TLP installed, enabled and started"
        fi
    fi

    # Configure other useful services
    local services_to_enable=()

    # Check for and configure common services
    # NOTE: The 'is-enabled' check is non-portable and removed for simplicity
    if command_exists docker; then
        if [[ "$FORCE_MODE" == true ]] || prompt_user "Enable Docker service?"; then
            services_to_enable+=("docker")
        fi
    fi

    if command_exists bluetooth; then
        if [[ "$FORCE_MODE" == true ]] || prompt_user "Enable Bluetooth service?"; then
            services_to_enable+=("bluetooth")
        fi
    fi

    # Enable selected services
    for service in "${services_to_enable[@]}"; do
        if manage_service "enable" "$service" "$INIT_SYSTEM"; then
            manage_service "start" "$service" "$INIT_SYSTEM"
            print_success "Enabled and started $service"
        else
            print_error "Failed to enable $service"
        fi
    done

    mark_step_completed "configure_services"
}

setup_tmux_plugins() {
    if [[ "$INTERNET_AVAILABLE" != true ]]; then
        print_warning "No internet connectivity - skipping Tmux plugins installation"
        return 0
    fi

    local tpm_dir="$HOME/.config/tmux/plugins/tpm"
    local plugins_dir="$HOME/.config/tmux/plugins"

    if [[ ! -f "$HOME/.tmux.conf" && ! -f "$HOME/.config/tmux/tmux.conf" ]]; then
        print_info "Tmux config not found, skipping plugin setup"
        return 0
    fi

    print_info "Setting up Tmux plugins..."
    create_dir "$plugins_dir"

    if [[ ! -d "$tpm_dir" || ! "$(ls -A "$tpm_dir" 2>/dev/null)" ]]; then
        print_info "Installing Tmux Plugin Manager (TPM)..."
        if execute_command "git clone https://github.com/tmux-plugins/tpm '$tpm_dir'"; then
            print_success "TPM installed successfully"
            print_info "Run 'tmux' and press 'prefix + I' to install plugins"
        else
            print_error "Failed to install TPM"
        fi
    else
        print_info "TPM already installed"
    fi
}

setup_development() {
    print_section "Setting Up Development Environment"
    save_state "setup_development" "started"

    # Git configuration
    if command_exists git; then
        if [[ "$FORCE_MODE" == true ]] || prompt_user "Configure Git global settings?"; then
            configure_git
        fi
    fi

    # Development tools based on install mode
    case "$INSTALL_MODE" in
        dev|full)
            install_development_tools
            ;;
        *)
            print_info "Skipping development tools installation for mode: $INSTALL_MODE"
            ;;
    esac

    mark_step_completed "setup_development"
}

configure_git() {
    local git_name="${USER}"
    local git_email="${USER}@${HOSTNAME:-$(hostname)}"

    if [[ "$FORCE_MODE" != true ]]; then
        print_color "$YELLOW" "Enter your Git username [$git_name]: "
        read -r input_name
        [[ -n "$input_name" ]] && git_name="$input_name"

        print_color "$YELLOW" "Enter your Git email [$git_email]: "
        read -r input_email
        [[ -n "$input_email" ]] && git_email="$input_email"
    fi

    execute_command "git config --global user.name '$git_name'"
    execute_command "git config --global user.email '$git_email'"
    execute_command "git config --global init.defaultBranch main"
    execute_command "git config --global pull.rebase false"
    print_success "Git configured with name: $git_name, email: $git_email"
}

install_development_tools() {
    if [[ "$INTERNET_AVAILABLE" != true ]]; then
        print_warning "No internet connectivity - skipping development tools installation"
        return 0
    fi

    print_info "Installing development tools..."

    # Install Rust if not present
    if ! command_exists rustc; then
        install_rust
    fi

    # Install Node.js via NVM if not present
    if ! command_exists node; then
        install_nvm
        install_node
    fi

    # Install Yarn if Node.js is available
    if command_exists npm && ! command_exists yarn; then
        install_yarn
    fi
}

install_rust() {
    print_info "Installing Rust via rustup..."

    if command_exists rustup; then
        print_info "Rust already installed"
        return 0
    fi

    local cargo_home="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
    local rustup_home="${XDG_DATA_HOME:-$HOME/.local/share}/rustup"

    create_dir "$(dirname "$cargo_home")"

    if execute_command "CARGO_HOME='$cargo_home' RUSTUP_HOME='$rustup_home' curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"; then
        print_success "Rust installed successfully"

        # Add to PATH for current session
        if [[ -f "$cargo_home/env" ]]; then
            source "$cargo_home/env"
        fi

        return 0
    else
        print_error "Failed to install Rust"
        return 1
    fi
}

install_nvm() {
    local nvm_dir="$HOME/.config/nvm"

    if [[ -d "$nvm_dir" && -f "$nvm_dir/nvm.sh" ]]; then
        print_info "NVM already installed"
        return 0
    fi

    print_info "Installing Node Version Manager (NVM)..."
    create_dir "$nvm_dir"

    if execute_command "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | NVM_DIR='$nvm_dir' bash"; then
        export NVM_DIR="$nvm_dir"
        if [[ -s "$NVM_DIR/nvm.sh" ]]; then
            source "$NVM_DIR/nvm.sh"
            print_success "NVM installed successfully"
            return 0
        else
            print_error "NVM installation failed - script not found"
            return 1
        fi
    else
        print_error "Failed to install NVM"
        return 1
    fi
}

install_node() {
    if command_exists node; then
        print_info "Node.js already installed"
        return 0
    fi

    print_info "Installing Node.js..."

    # Source NVM if available
    local nvm_dir="$HOME/.config/nvm"
    if [[ -s "$nvm_dir/nvm.sh" ]]; then
        export NVM_DIR="$nvm_dir"
        source "$NVM_DIR/nvm.sh"
    fi

    if command_exists nvm; then
        if execute_command "nvm install --lts" && execute_command "nvm use --lts" && execute_command "nvm alias default lts/*"; then
            print_success "Node.js installed successfully"
            return 0
        else
            print_error "Failed to install Node.js via NVM"
            return 1
        fi
    else
        print_error "NVM not available for Node.js installation"
        return 1
    fi
}

install_yarn() {
    print_info "Installing Yarn..."

    if execute_command "curl -o- -L https://yarnpkg.com/install.sh | bash"; then
        print_success "Yarn installed successfully"

        # Add to PATH for current session
        local yarn_bin="$HOME/.yarn/bin"
        if [[ -d "$yarn_bin" && ":$PATH:" != *":$yarn_bin:"* ]]; then
            export PATH="$yarn_bin:$PATH"
        fi

        return 0
    else
        print_error "Failed to install Yarn"
        return 1
    fi
}

apply_tweaks() {
    print_section "Applying System Tweaks"
    save_state "apply_tweaks" "started"

    case "$CFG_OS" in
        linux)
            apply_linux_tweaks
            ;;
        macos)
            apply_macos_tweaks
            ;;
        *)
            print_info "No system tweaks defined for $CFG_OS"
            ;;
    esac

    mark_step_completed "apply_tweaks"
}

apply_linux_tweaks() {
    # --- Locale tweak ---
    if command -v localectl >/dev/null 2>&1; then
        local current_locale
        current_locale=$(localectl status | grep "System Locale" | cut -d= -f2 | cut -d, -f1)
        if [[ "$current_locale" != "en_US.UTF-8" ]]; then
            if prompt_user "Set system locale to en_US.UTF-8?"; then
                if execute_with_privilege "localectl set-locale LANG=en_US.UTF-8"; then
                    print_success "Locale set to en_US.UTF-8"
                else
                    print_error "Failed to set locale"
                fi
            fi
        fi
    fi

    # --- Power / Display timeout tweaks ---
    if command -v gsettings >/dev/null 2>&1; then
        print_info "Setting GNOME power/display timeouts to 'never'"

        # Turn off blank screen
        gsettings set org.gnome.desktop.session idle-delay 0

        # Turn off automatic suspend
        gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
        gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'

        print_success "GNOME power/display settings applied"
    else
        print_info "gsettings not found; skipping GNOME power/display tweaks"
    fi

    print_info "Linux system tweaks applied"
}

apply_macos_tweaks() {
    print_info "macOS system tweaks applied (placeholder)"
}

#======================================
# Installation Mode Selection
#======================================

select_installation_mode() {
    if [[ "$INSTALL_MODE" != "ask" ]]; then
        return 0  # Mode already set via command line
    fi

    print_header "Installation Mode Selection"

    print_color "$CYAN" "Available installation modes:"
    echo

    local mode_number=1
    local mode_options=()

    for mode in essentials minimal dev server full; do
        local description="${INSTALLATION_PROFILES[$mode]}"
        print_color "$YELLOW" "$mode_number. $mode - $description"
        mode_options+=("$mode")
        ((mode_number++))
    done

    echo
    print_color "$CYAN" "You can also specify a custom profile from the profiles/ directory"
    echo

    while true; do
        print_color "$YELLOW" "Select installation mode [1-5] or enter profile name [dev]: "
        read -r response

        if [[ -z "$response" ]]; then
            INSTALL_MODE="dev"
            break
        elif [[ "$response" =~ ^[1-5]$ ]]; then
            INSTALL_MODE="${mode_options[$((response-1))]}"
            break
        elif [[ "$response" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
            # Check if it's a valid profile
            if [[ -f "profiles/$response.yml" ]] || [[ "${INSTALLATION_PROFILES[$response]:-}" ]]; then
                INSTALL_MODE="$response"
                break
            else
                print_warning "Profile '$response' not found"
            fi
        else
            print_warning "Invalid selection. Please enter 1-5 or a profile name"
        fi
    done

    print_success "Selected installation mode: $INSTALL_MODE"
    print_info "Description: ${INSTALLATION_PROFILES[$INSTALL_MODE]:-Custom profile}"
}

#======================================
# Command Line Argument Parsing
#======================================

show_help() {
    cat << EOF
Dotfiles Installation Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -r, --resume            Resume from last failed step
    -u, --update            Update existing dotfiles and packages
    -v, --verbose           Enable verbose output
    -n, --dry-run           Show what would be done without executing
    -f, --force             Force reinstallation and skip prompts
    -m, --mode MODE         Installation mode (essentials|minimal|dev|server|full|PROFILE)

INSTALLATION MODES:
    essentials              Install only essential packages (git, curl, etc.)
    minimal                 Minimal setup for basic development
    dev                     Full development environment (default)
    server                  Server configuration
    full                    Complete installation with all packages
    PROFILE                 Custom profile from profiles/ directory

EXAMPLES:
    $0                      # Interactive installation (asks for mode)
    $0 --mode essentials    # Install essentials only
    $0 --mode dev           # Development environment
    $0 --resume             # Resume from last failed step
    $0 --update --mode full # Update and install all packages
    $0 --dry-run --mode dev # Preview development installation

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -r|--resume)
                RESUME_MODE=true
                shift
                ;;
            -u|--update)
                UPDATE_MODE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE_MODE=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE_MODE=true
                shift
                ;;
            -m|--mode)
                INSTALL_MODE="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Validate install mode
    if [[ "$INSTALL_MODE" != "ask" ]]; then
        if [[ ! "${INSTALLATION_PROFILES[$INSTALL_MODE]:-}" ]] && [[ ! -f "profiles/$INSTALL_MODE.yml" ]]; then
            print_error "Invalid installation mode: $INSTALL_MODE"
            print_info "Available modes: ${!INSTALLATION_PROFILES[*]}"
            exit 1
        fi
    fi
}

#======================================
# Summary Functions
#======================================

print_installation_summary() {
    print_header "Installation Summary"

    local total_steps=${#STEP_ORDER[@]}
    local completed_count=${#COMPLETED_STEPS[@]}
    local failed_count=${#FAILED_ITEMS[@]}

    print_section "Progress Overview"
    print_color "$CYAN" "Installation Mode: $INSTALL_MODE"
    print_color "$CYAN" "Total Steps: $total_steps"
    print_color "$GREEN" "Completed: $completed_count"
    print_color "$RED" "Failed: $failed_count"

    if [[ ${#INSTALL_SUMMARY[@]} -gt 0 ]]; then
        print_section "Successful Operations"
        printf '%s\n' "${INSTALL_SUMMARY[@]}"
    fi

    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        print_section "Failed Operations"
        printf '%s\n' "${FAILED_ITEMS[@]}"
        print_warning "Check the log file: $LOG_FILE"
    fi

    if [[ ${#SKIPPED_ITEMS[@]} -gt 0 ]]; then
        print_section "Skipped Operations"
        printf '%s\n' "${SKIPPED_ITEMS[@]}"
    fi

    echo
    print_color "$GREEN$BOLD" "Installation completed!"
    print_info "Log file: $LOG_FILE" "always"
}

#======================================
# Main Installation Flow
#======================================

execute_step() {
    local step_name="$1"
    local step_desc="${INSTALLATION_STEPS[$step_name]}"

    if is_step_completed "$step_name" && [[ "$FORCE_MODE" != true ]]; then
        print_success "$step_desc (already completed)"
        return 0
    fi

    if "$step_name"; then
        print_success "$step_desc completed"
        mark_step_completed "$step_name"
        return 0
    else
        print_error "$step_desc failed"
        mark_step_failed "$step_name"
        return 1
    fi
}

main() {
    parse_arguments "$@"
    setup_logging

    print_header "Dotfiles Installation"

    if [[ "$DRY_RUN" == true ]]; then
        print_warning "DRY RUN MODE - No changes will be made"
        echo
    fi

    print_info "Starting installation for user: $USER" "always"
    print_info "Log file: $LOG_FILE" "always"

    # Handle resume mode
    if [[ "$RESUME_MODE" == true ]]; then
        if load_state; then
            print_info "Resuming from previous installation..." "always"
            print_info "Last step: ${LAST_STEP:-unknown}" "always"
            if [[ -n "${COMPLETED_STEPS:-}" ]]; then
                eval "COMPLETED_STEPS=(${COMPLETED_STEPS:-})"
            fi
        else
            print_warning "No previous installation state found"
            print_info "Starting fresh installation..."
            RESUME_MODE=false
        fi
    fi

    # Select installation mode if not specified
    select_installation_mode

    # Show installation plan
    echo
    print_color "$YELLOW$BOLD" "Installation Plan (Mode: $INSTALL_MODE):"
    local step_number=1
    for step in "${STEP_ORDER[@]}"; do
        local step_desc="${INSTALLATION_STEPS[$step]}"
        if is_step_completed "$step" && [[ "$FORCE_MODE" != true ]]; then
            print_color "$GREEN" "$step_number. $step_desc (✓ completed)"
        else
            print_color "$CYAN" "$step_number. $step_desc"
        fi
        step_number=$((step_number + 1))
    done

    echo
    if [[ "$FORCE_MODE" != true ]] && [[ "$DRY_RUN" != true ]] && ! prompt_user "Continue with installation?"; then
        print_info "Installation cancelled by user"
        exit 0
    fi

    # Execute installation steps
    local failed_steps=()
    local step_number=1
    local total_steps=${#STEP_ORDER[@]}

    for step in "${STEP_ORDER[@]}"; do
        echo
        print_color "$MAGENTA$BOLD" "[$step_number/$total_steps] ${INSTALLATION_STEPS[$step]}"

        if execute_step "$step"; then
            print_info "Step completed successfully: $step"
        else
            failed_steps+=("$step")
            print_error "Step failed: $step"

            if [[ "$FORCE_MODE" != true ]] && [[ "$DRY_RUN" != true ]]; then
                echo
                if ! prompt_user "Step '$step' failed. Continue with remaining steps?" "Y"; then
                    print_info "Installation stopped by user"
                    break
                fi
            fi
        fi

        step_number=$((step_number + 1))
    done

    # Post-installation
    if [[ ${#failed_steps[@]} -eq 0 ]]; then
        print_success "All installation steps completed successfully!"
        clear_state
    else
        print_warning "${#failed_steps[@]} steps failed: ${failed_steps[*]}"
        if [[ "${failed_steps[-1]:-}" != "" ]]; then
            save_state "${failed_steps[-1]}" "failed"
        fi
    fi

    print_installation_summary

    # Final recommendations
    if [[ "$DRY_RUN" != true ]]; then
        echo
        print_section "Post-Installation Recommendations"
        print_color "$CYAN" "• Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
        print_color "$CYAN" "• Review your dotfiles configuration in: $DOTFILES_DIR"
        print_color "$CYAN" "• Use the 'config' command to manage your dotfiles"

        if [[ ${#failed_steps[@]} -gt 0 ]]; then
            print_color "$YELLOW" "• Run '$0 --resume' to retry failed steps"
            print_color "$YELLOW" "• Check the log file for detailed error information: $LOG_FILE"
        fi

        echo
        print_color "$GREEN$BOLD" "Thank you for using the Dotfiles Installation Script!"
    fi

    [[ ${#failed_steps[@]} -eq 0 ]] && exit 0 || exit 1
}

#======================================
# Script Entry Point
#======================================

cleanup_on_exit() {
    local exit_code=$?

    if [[ $exit_code -ne 0 ]] && [[ "$DRY_RUN" != true ]]; then
        print_error "Installation interrupted (exit code: $exit_code)"

        if [[ -n "${current_step:-}" ]]; then
            save_state "$current_step" "interrupted"
            print_info "State saved. Run with --resume to continue"
        fi
    fi
}

handle_interrupt() {
    print_warning "Installation interrupted by user"
    exit 130
}

trap cleanup_on_exit EXIT
trap handle_interrupt INT

# Execute main if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Check basic requirements
    for req in git curl; do
        if ! command_exists "$req"; then
            print_error "$req is required but not installed"
            exit 1
        fi
    done

    main "$@"
fi
