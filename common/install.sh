#!/usr/bin/env bash

# Created By: srdusr
# Created On: Tue 06 Sep 2025 16:20:52 PM CAT
# Project: Dotfiles installation script

# Dependencies: git, curl

# TODO: install fonts/icons  ie Whitesur, San Francisco JetBrains Mono

# POSIX-compatible shim: if not running under bash (e.g., invoked via `sh -c "$(curl ...)"`),
# re-exec the remainder of this script with bash.
#if [ -z "${BASH_VERSION:-}" ]; then
#  tmp="$(mktemp)" || exit 1
#  # Read the rest of the script into a temp file, then exec bash on it
#  cat > "$tmp"
#  exec bash "$tmp" "$@"
#  exit 1
#fi

set -euo pipefail  # Exit on error, undefined vars, pipe failures

#======================================
# Variables & Configuration
#======================================

# Color definitions
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
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
ASK_MODE=false  # New: ask for each step
INSTALL_MODE="ask"  # ask, essentials, full, profile

# Global variables for system detection
CFG_OS=""
DISTRO=""
PACKAGE_MANAGER=""
PACKAGE_UPDATE_CMD=""
PACKAGE_INSTALL_CMD=""
PRIVILEGE_TOOL=""
PRIVILEGE_CACHED=false

# Essential tools needed by this script
ESSENTIAL_TOOLS=("git" "curl" "wget")
PACKAGE_TOOLS=("yq" "jq")

# Config command tracking
CONFIG_COMMAND_AVAILABLE=false
CONFIG_COMMAND_FILE=""

# Steps can be skipped by providing a comma-separated list in SKIP_STEPS
SKIP_STEPS="${SKIP_STEPS:-}"

# Run control: run only a specific step, or start from a specific step
RUN_ONLY_STEP="${RUN_ONLY_STEP:-}"
RUN_FROM_STEP="${RUN_FROM_STEP:-}"
__RUN_FROM_STARTED=false

# Interactive per-step prompt even without --ask (opt-in)
# Set INTERACTIVE_SKIP=true to be prompted for non-essential steps.
INTERACTIVE_SKIP="${INTERACTIVE_SKIP:-false}"

# Steps considered essential (should rarely be skipped)
ESSENTIAL_STEPS=(
    setup_environment
    check_connectivity
    detect_package_manager
    install_dependencies
)

is_step_skipped() {
    local step="$1"
    [[ ",${SKIP_STEPS}," == *",${step},"* ]]
}

skip_step_if_requested() {
    local step="$1"
    if is_step_skipped "$step"; then
        print_skip "Skipping step by request: $step"
        mark_step_completed "$step"
        return 1
    fi
    return 0
}

should_run_step() {
    local step="$1"
    # If RUN_ONLY_STEP is set, only run that exact step
    if [[ -n "$RUN_ONLY_STEP" && "$step" != "$RUN_ONLY_STEP" ]]; then
        print_skip "Skipping step (RUN_ONLY_STEP=$RUN_ONLY_STEP): $step"
        return 1
    fi
    # If RUN_FROM_STEP is set, skip until we reach it, then run subsequent steps
    if [[ -n "$RUN_FROM_STEP" && "$__RUN_FROM_STARTED" != true ]]; then
        if [[ "$step" == "$RUN_FROM_STEP" ]]; then
            __RUN_FROM_STARTED=true
        else
            print_skip "Skipping step until RUN_FROM_STEP=$RUN_FROM_STEP: $step"
            return 1
        fi
    fi
    return 0
}

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
    ["detect_package_manager"]="Detect or configure package manager"
    ["install_dependencies"]="Install dependencies"
    ["install_dotfiles"]="Install dotfiles repository"
    ["deploy_config"]="Deploy config command and dotfiles"
    ["setup_user_dirs"]="Setup user directories"
    ["setup_passwords"]="Setup user and root passwords (optional)"
    ["install_essentials"]="Install essential tools"
    ["install_packages"]="Install system packages"
    ["setup_shell"]="Setup shell environment"
    ["setup_ssh"]="Setup SSH configuration"
    ["configure_services"]="Configure system services"
    ["configure_git"]="Configure git"
    ["setup_development_environment"]="Setup development environment"
    ["apply_tweaks"]="Apply system tweaks"
)

# Step order
STEP_ORDER=(
    "setup_environment"
    "check_connectivity"
    "detect_package_manager"
    "install_dependencies"
    "install_dotfiles"
    "deploy_config"
    "setup_user_dirs"
    "setup_passwords"
    "install_essentials"
    "install_packages"
    "setup_shell"
    "setup_ssh"
    "configure_services"
    "configure_git"
    "setup_development_environment"
    "apply_tweaks"
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
    print_color "$CYAN" "[DRY RUN] $message"
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
    print_section "Detecting Package Manager"
    save_state "detect_package_manager" "started"

    # First try to detect from OS release files
    if [[ "$CFG_OS" == "linux" && -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
            arch|manjaro|endeavouros|artix)
                DISTRO="$ID"
                PACKAGE_MANAGER="pacman"
                PACKAGE_UPDATE_CMD="pacman -Sy"
                PACKAGE_INSTALL_CMD="pacman -S --noconfirm"
                ;;
            debian|ubuntu|mint|pop|elementary|zorin)
                DISTRO="$ID"
                PACKAGE_MANAGER="apt"
                PACKAGE_UPDATE_CMD="apt-get update"
                PACKAGE_INSTALL_CMD="apt-get install -y"
                ;;
            fedora|rhel|centos|rocky|almalinux)
                DISTRO="$ID"
                PACKAGE_MANAGER="dnf"
                PACKAGE_UPDATE_CMD="dnf check-update"
                PACKAGE_INSTALL_CMD="dnf install -y"
                ;;
            opensuse*|sles)
                DISTRO="$ID"
                PACKAGE_MANAGER="zypper"
                PACKAGE_UPDATE_CMD="zypper refresh"
                PACKAGE_INSTALL_CMD="zypper install -y"
                ;;
            gentoo)
                DISTRO="$ID"
                PACKAGE_MANAGER="portage"
                PACKAGE_UPDATE_CMD="emerge --sync"
                PACKAGE_INSTALL_CMD="emerge"
                ;;
            alpine)
                DISTRO="$ID"
                PACKAGE_MANAGER="apk"
                PACKAGE_UPDATE_CMD="apk update"
                PACKAGE_INSTALL_CMD="apk add"
                ;;
            void)
                DISTRO="$ID"
                PACKAGE_MANAGER="xbps"
                PACKAGE_UPDATE_CMD="xbps-install -S"
                PACKAGE_INSTALL_CMD="xbps-install -y"
                ;;
            nixos)
                DISTRO="$ID"
                PACKAGE_MANAGER="nix"
                PACKAGE_UPDATE_CMD="nix-channel --update"
                PACKAGE_INSTALL_CMD="nix-env -iA nixpkgs."
                ;;
        esac
    elif [[ "$CFG_OS" == "macos" ]]; then
        DISTRO="macos"
        if command -v brew &>/dev/null; then
            PACKAGE_MANAGER="brew"
            PACKAGE_UPDATE_CMD="brew update"
            PACKAGE_INSTALL_CMD="brew install"
        else
            PACKAGE_MANAGER="brew-install"
        fi
    fi

    # Fallback: detect by available commands
    if [[ -z "$PACKAGE_MANAGER" ]]; then
        local managers=(
            "pacman:pacman:pacman -Sy:pacman -S --noconfirm"
            "apt:apt:apt-get update:apt-get install -y"
            "dnf:dnf:dnf check-update:dnf install -y"
            "yum:yum:yum check-update:yum install -y"
            "zypper:zypper:zypper refresh:zypper install -y"
            "emerge:portage:emerge --sync:emerge"
            "apk:apk:apk update:apk add"
            "xbps-install:xbps:xbps-install -S:xbps-install -y"
            "nix-env:nix:nix-channel --update:nix-env -iA nixpkgs."
            "pkg:pkg:pkg update:pkg install -y"
            "brew:brew:brew update:brew install"
        )

        for manager in "${managers[@]}"; do
            local cmd="${manager%%:*}"
            local name="${manager#*:}"; name="${name%%:*}"
            local update_cmd="${manager#*:*:}"; update_cmd="${update_cmd%%:*}"
            local install_cmd="${manager##*:}"

            if command -v "$cmd" &>/dev/null; then
                PACKAGE_MANAGER="$name"
                PACKAGE_UPDATE_CMD="$update_cmd"
                PACKAGE_INSTALL_CMD="$install_cmd"
                break
            fi
        done
    fi

    if [[ -n "$PACKAGE_MANAGER" ]]; then
        print_success "Detected package manager: $PACKAGE_MANAGER"
        [[ -n "$DISTRO" ]] && print_info "Distribution: $DISTRO"

        # Try to override commands from packages.yml -> package_managers
        # Find packages.yml in standard locations
        local original_dir="$PWD"
        cd "$HOME" 2>/dev/null || true
        # Search common locations for packages.yml, including repo-local and script directory
        local __script_dir
        __script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
        local packages_files=(
            "$PACKAGES_FILE" \
            "common/$PACKAGES_FILE" \
            ".cfg/common/$PACKAGES_FILE" \
            "$__script_dir/../packages.yml" \
            "$__script_dir/packages.yml" \
            "$DOTFILES_DIR/common/$PACKAGES_FILE" \
            "$DOTFILES_DIR/packages.yml"
        )
        local found_packages_file=""
        for pf in "${packages_files[@]}"; do
            if [[ -f "$pf" ]]; then
                found_packages_file="$pf"
                break
            fi
        done
        cd "$original_dir" 2>/dev/null || true

        # Optionally merge a profile overlay packages.yml over the base file
        local merged_packages_file=""
        if command_exists yq && [[ -n "$found_packages_file" ]]; then
            local overlay_candidates=(
                "$HOME/.cfg/profile/$INSTALL_MODE/packages.yml"
                "$HOME/profile/$INSTALL_MODE/packages.yml"
                "$__script_dir/../profile/$INSTALL_MODE/packages.yml"
                "$__script_dir/profile/$INSTALL_MODE/packages.yml"
                "$DOTFILES_DIR/profile/$INSTALL_MODE/packages.yml"
            )
            local overlay_file=""
            for opf in "${overlay_candidates[@]}"; do
                [[ -f "$opf" ]] && { overlay_file="$opf"; break; }
            done
            if [[ -n "$overlay_file" ]]; then
                merged_packages_file="$(mktemp)"
                if yq eval-all 'select(fileIndex==0) * select(fileIndex==1)' "$found_packages_file" "$overlay_file" >"$merged_packages_file" 2>/dev/null; then
                    print_info "Using merged packages.yml (base + profile overlay: $INSTALL_MODE)"
                else
                    print_warning "Failed to merge profile packages overlay; using base packages.yml"
                    rm -f "$merged_packages_file" 2>/dev/null || true
                    merged_packages_file=""
                fi
            fi
        fi

        # If we have a resolved file, set PACKAGES_FILE to its absolute path for downstream steps
        if [[ -n "$found_packages_file" ]]; then
            if [[ -n "$merged_packages_file" ]]; then
                PACKAGES_FILE="$merged_packages_file"
            else
                # Canonical absolute path
                PACKAGES_FILE="$(cd "$(dirname "$found_packages_file")" && pwd -P)/$(basename "$found_packages_file")"
            fi
            export PACKAGES_FILE
        fi

        if command_exists yq && [[ -n "${merged_packages_file:-$found_packages_file}" ]]; then
            # Prefer distro block, fallback to manager block
            # Initialize to avoid set -u (nounset) issues before assignment
            local pm_update="" pm_install=""
            if [[ -n "$DISTRO" ]]; then
                pm_update=$(yq eval ".package_managers.${DISTRO}.update" "${merged_packages_file:-$found_packages_file}" 2>/dev/null | grep -v "^null$" || echo "")
                pm_install=$(yq eval ".package_managers.${DISTRO}.install" "${merged_packages_file:-$found_packages_file}" 2>/dev/null | grep -v "^null$" || echo "")
            fi
            if [[ -z "$pm_update" || -z "$pm_install" ]]; then
                pm_update=$(yq eval ".package_managers.${PACKAGE_MANAGER}.update" "${merged_packages_file:-$found_packages_file}" 2>/dev/null | grep -v "^null$" || echo "")
                pm_install=$(yq eval ".package_managers.${PACKAGE_MANAGER}.install" "${merged_packages_file:-$found_packages_file}" 2>/dev/null | grep -v "^null$" || echo "")
            fi
            if [[ -n "$pm_update" && -n "$pm_install" ]]; then
                PACKAGE_UPDATE_CMD="$pm_update"
                PACKAGE_INSTALL_CMD="$pm_install"
                print_info "Using package manager commands from packages.yml"
            fi
        fi

        # Export for compatibility with packages.yml custom commands that reference CFG_DISTRO
        export CFG_DISTRO="$DISTRO"

        mark_step_completed "detect_package_manager"
        return 0
    else
        print_error "Could not detect package manager"
        manual_package_manager_setup
        return $?
    fi
}

manual_package_manager_setup() {
    print_warning "No supported package manager detected automatically"
    print_info "Please provide package manager commands manually:"

    while true; do
        print_color "$YELLOW" "Enter package update command (e.g., 'apt-get update'): "
        read -r PACKAGE_UPDATE_CMD
        [[ -n "$PACKAGE_UPDATE_CMD" ]] && break
        print_warning "Update command cannot be empty"
    done

    while true; do
        print_color "$YELLOW" "Enter package install command (e.g., 'apt-get install -y'): "
        read -r PACKAGE_INSTALL_CMD
        [[ -n "$PACKAGE_INSTALL_CMD" ]] && break
        print_warning "Install command cannot be empty"
    done

    PACKAGE_MANAGER="manual"
    print_success "Manual package manager configuration set"
    print_info "Update command: $PACKAGE_UPDATE_CMD"
    print_info "Install command: $PACKAGE_INSTALL_CMD"

    mark_step_completed "detect_package_manager"
    return 0
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
            printf "%b%s%b" "$YELLOW" "$question [Y/n]: " "$NOCOLOR"
        else
            printf "%b%s%b" "$YELLOW" "$question [y/N]: " "$NOCOLOR"
        fi

        read -r response

        if [[ -z "$response" ]]; then
            response="$default"
        fi

        case "${response^^}" in
            Y|YES) echo; return 0 ;;
            N|NO) echo; return 1 ;;
            *) echo; print_warning "Please answer Y/yes or N/no" ;;
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

get_package_names() {
    local package="$1"
    local packages_file="${2:-}"

    # If packages.yml is available, check for distribution-specific mappings
    if [[ -n "$packages_file" ]] && [[ -f "$packages_file" ]] && command_exists yq; then
        local distro_packages=""

        # Try to get package name(s) for current distribution
        case "$DISTRO" in
            arch|manjaro|endeavouros|artix)
                distro_packages=$(yq eval ".arch.$package" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")
                ;;
            debian|ubuntu|mint|pop|elementary|zorin)
                distro_packages=$(yq eval ".debian.$package" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")
                ;;
            fedora|rhel|centos|rocky|almalinux)
                distro_packages=$(yq eval ".rhel.$package" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")
                ;;
            opensuse*|sles)
                distro_packages=$(yq eval ".opensuse.$package" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")
                ;;
            gentoo)
                distro_packages=$(yq eval ".gentoo.$package" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")
                ;;
            alpine)
                distro_packages=$(yq eval ".alpine.$package" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")
                ;;
            void)
                distro_packages=$(yq eval ".void.$package" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")
                ;;
            macos)
                # macOS uses array format, check if package exists in the list
                if yq eval ".macos[]" "$packages_file" 2>/dev/null | grep -q "^$package$"; then
                    distro_packages="$package"
                fi
                ;;
        esac

        # Return the distribution-specific package name(s) if found
        if [[ -n "$distro_packages" ]]; then
            echo "$distro_packages"
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

    # If everything is already present, skip with a clear message
    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        print_skip "All required dependencies are already installed"
        mark_step_completed "install_dependencies"
        return 0
    fi

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
        print_success "Dependencies satisfied: ${missing_deps[*]}"
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

    # Get the correct package name(s) for this distro - can be multiple packages
    local pkg_names
    pkg_names=$(get_package_names "$package" "$packages_file")

    # Get USE flags for Gentoo
    local use_flags
    use_flags=$(get_package_use_flags "$package" "$packages_file")

    print_info "Installing $package_type package: $package -> $pkg_names"

    # Handle multiple packages
    local install_success=true
    for pkg_name in $pkg_names; do
        print_info "Installing: $pkg_name"

        case "$PACKAGE_MANAGER" in
            pacman)
                execute_with_privilege "$PACKAGE_INSTALL_CMD '$pkg_name'" || install_success=false
                ;;
            apt)
                execute_with_privilege "$PACKAGE_INSTALL_CMD '$pkg_name'" || install_success=false
                ;;
            dnf|yum)
                execute_with_privilege "$PACKAGE_INSTALL_CMD '$pkg_name'" || install_success=false
                ;;
            zypper)
                execute_with_privilege "$PACKAGE_INSTALL_CMD '$pkg_name'" || install_success=false
                ;;
            portage)
                local emerge_cmd="$PACKAGE_INSTALL_CMD"
                if [[ -n "$use_flags" ]]; then
                    emerge_cmd="USE='$use_flags' $PACKAGE_INSTALL_CMD"
                    print_info "Using USE flags for $pkg_name: $use_flags"
                fi
                execute_with_privilege "$emerge_cmd '$pkg_name'" || install_success=false
                ;;
            apk)
                execute_with_privilege "$PACKAGE_INSTALL_CMD '$pkg_name'" || install_success=false
                ;;
            xbps)
                execute_with_privilege "$PACKAGE_INSTALL_CMD '$pkg_name'" || install_success=false
                ;;
            nix)
                execute_command "$PACKAGE_INSTALL_CMD$pkg_name" || install_success=false
                ;;
            brew)
                execute_command "$PACKAGE_INSTALL_CMD '$pkg_name'" || install_success=false
                ;;
            brew-install)
                print_error "Homebrew not installed. Please install it first."
                return 1
                ;;
            manual)
                execute_with_privilege "$PACKAGE_INSTALL_CMD '$pkg_name'" || install_success=false
                ;;
            *)
                print_error "Package manager '$PACKAGE_MANAGER' not supported"
                return 1
                ;;
        esac
    done

    return $([[ "$install_success" == true ]] && echo 0 || echo 1)
}

update_package_database() {
    print_info "Updating package database..."

    case "$PACKAGE_MANAGER" in
        pacman)
            execute_with_privilege "$PACKAGE_UPDATE_CMD" ;;
        apt)
            execute_with_privilege "$PACKAGE_UPDATE_CMD" ;;
        dnf|yum)
            execute_with_privilege "$PACKAGE_UPDATE_CMD" || true ;;
        zypper)
            execute_with_privilege "$PACKAGE_UPDATE_CMD" ;;
        portage)
            execute_with_privilege "$PACKAGE_UPDATE_CMD" ;;
        apk)
            execute_with_privilege "$PACKAGE_UPDATE_CMD" ;;
        xbps)
            execute_with_privilege "$PACKAGE_UPDATE_CMD" ;;
        brew)
            execute_command "$PACKAGE_UPDATE_CMD" ;;
        manual)
            execute_with_privilege "$PACKAGE_UPDATE_CMD" ;;
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

    # Output packages (one per line)
    printf '%s\n' "${packages[@]}"
}

get_profile_package_groups() {
    local packages_file="$1"
    local profile="$2"
    local groups=()

    if [[ ! -f "$packages_file" ]]; then
        print_warning "Package file not found: $packages_file"
        return 1
    fi

    # Get package groups for the profile from the profiles section
    if yq eval ".profiles.$profile.packages" "$packages_file" &>/dev/null; then
        mapfile -t groups < <(yq eval ".profiles.$profile.packages[]" "$packages_file" 2>/dev/null | grep -v "^null$" || true)
    fi

    # Fallback to old method if profiles section doesn't exist
    if [[ ${#groups[@]} -eq 0 ]]; then
        case "$profile" in
            essentials)
                groups=("common" "essentials") ;;
            minimal)
                groups=("common" "essentials" "minimal") ;;
            dev)
                groups=("common" "essentials" "minimal" "dev") ;;
            server)
                groups=("common" "essentials" "minimal" "server") ;;
            full)
                groups=("common" "essentials" "minimal" "dev" "server" "desktop" "wm" "media" "fonts") ;;
            *)
                print_error "Unknown profile: $profile"
                return 1
                ;;
        esac
    fi

    printf '%s\n' "${groups[@]}"
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

    # Get package groups to install based on profile
    local groups
    mapfile -t groups < <(get_profile_package_groups "$packages_file" "$profile")

    if [[ ${#groups[@]} -eq 0 ]]; then
        print_error "No package groups found for profile: $profile"
        return 1
    fi

    print_info "Installing package groups for $profile: ${groups[*]}"

    # Install packages from each group
    for group in "${groups[@]}"; do
        print_info "Installing packages from group: $group"

        local packages
        mapfile -t packages < <(parse_packages_from_yaml "$packages_file" "$group")

        if [[ ${#packages[@]} -eq 0 ]]; then
            print_info "No packages found in group: $group"
            continue
        fi

        print_info "Found ${#packages[@]} packages in group $group: ${packages[*]}"

        for package in "${packages[@]}"; do
            [[ -z "$package" ]] && continue

            if install_single_package "$package" "$group" "$packages_file"; then
                print_success "Installed: $package"
                ((installed_count++))
            else
                print_error "Failed to install: $package"
                failed_packages+=("$package")
            fi
        done
    done

    # Handle development environment setup
    if yq eval ".profiles.$profile.enable_development" "$packages_file" 2>/dev/null | grep -q "true"; then
        setup_development_environment "$packages_file"
    fi

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

check_existing_config_command() {
    print_info "Checking for existing config command..."

    # Known function files where config might already be defined
    local function_files=(
        "$HOME/.config/zsh/user/functions.zsh"
        "$HOME/.config/zsh/.zshrc"
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.profile"
    )

    # Check if config command is already available in current shell
    if type config >/dev/null 2>&1; then
        CONFIG_COMMAND_AVAILABLE=true
        print_success "Config command already available in current shell"
        return 0
    fi

    # Check files for existing config function definition
    for f in "${function_files[@]}"; do
        if [[ -f "$f" ]]; then
            if grep -q '^\s*config\s*()' "$f" || grep -q '# Dotfiles Management System' "$f"; then
                CONFIG_COMMAND_AVAILABLE=true
                CONFIG_COMMAND_FILE="$f"
                print_success "Config command found in: $f"
                return 0
            fi
        fi
    done

    CONFIG_COMMAND_AVAILABLE=false
    print_info "No existing config command found"
    return 1
}

install_config_command() {
    print_section "Installing Config Command"

    if check_existing_config_command; then
        if [[ "$FORCE_MODE" == true ]]; then
            print_info "Force mode: reinstalling config command"
        else
            return 0
        fi
    fi

    # Determine current shell and profile file
    local current_shell
    current_shell=$(basename "$SHELL")

    local profile_file=""
    case "$current_shell" in
        bash)
            if [[ -f "$HOME/.bashrc" ]]; then
                profile_file="$HOME/.bashrc"
            else
                profile_file="$HOME/.bashrc"
                touch "$profile_file"
            fi
            ;;
        zsh)
            if [[ -f "$HOME/.config/zsh/user/functions.zsh" ]]; then
                profile_file="$HOME/.config/zsh/user/functions.zsh"
            elif [[ -f "$HOME/.config/zsh/.zshrc" ]]; then
                profile_file="$HOME/.config/zsh/.zshrc"
            elif [[ -f "$HOME/.zshrc" ]]; then
                profile_file="$HOME/.zshrc"
            else
                profile_file="$HOME/.zshrc"
                touch "$profile_file"
            fi
            ;;
        *)
            if [[ -f "$HOME/.profile" ]]; then
                profile_file="$HOME/.profile"
            else
                profile_file="$HOME/.profile"
                touch "$profile_file"
            fi
            ;;
    esac

    if [[ ! -w "$profile_file" ]]; then
        print_error "Cannot write to profile file: $profile_file"
        return 1
    fi

    # Check if config function already exists in the target file
    if grep -q "# Dotfiles Management System" "$profile_file" 2>/dev/null; then
        print_info "Config function already exists in $profile_file"
        CONFIG_COMMAND_AVAILABLE=true
        CONFIG_COMMAND_FILE="$profile_file"
        return 0
    fi

    print_info "Adding config function to: $profile_file"

    # Add the config function
    cat >> "$profile_file" << 'EOF'

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
EOF

    if [[ $? -eq 0 ]]; then
        print_success "Config command added to: $profile_file"
        CONFIG_COMMAND_AVAILABLE=true
        CONFIG_COMMAND_FILE="$profile_file"

        # Source the file to make config command available immediately
        # shellcheck disable=SC1090
        source "$profile_file" 2>/dev/null || print_warning "Failed to source $profile_file"

        return 0
    else
        print_error "Failed to add config command to $profile_file"
        return 1
    fi
}

deploy_config() {
    print_section "Deploying Configuration"
    save_state "deploy_config" "started"

    # Ensure config command is available
    if [[ "$CONFIG_COMMAND_AVAILABLE" != true ]]; then
        install_config_command || {
            print_error "Failed to install config command"
            mark_step_failed "deploy_config"
            return 1
        }
    fi

    # Deploy dotfiles from repository to system
    if [[ -d "$DOTFILES_DIR" ]]; then
        print_info "Checking out dotfiles from repository..."

        # First, checkout files from the bare repository to restore directory structure
        if [[ "$DRY_RUN" == true ]]; then
            print_dry_run "config checkout"
        else
            # Source the config function if available
            if type config >/dev/null 2>&1; then
                print_info "Using config command to checkout files..."
                if config checkout; then
                    print_success "Files checked out from repository"
                else
                    print_warning "Some files may have failed to checkout, trying force checkout..."
                    config checkout -f || print_warning "Force checkout also had issues"
                fi
            else
                # Fallback: use git directly
                print_info "Using git directly to checkout files..."
                # IMPORTANT: use $HOME/.cfg as work-tree, never the bare repo path
                if git --git-dir="$DOTFILES_DIR" --work-tree="$HOME/.cfg" checkout HEAD -- . 2>/dev/null; then
                    print_success "Files checked out using git directly"
                else
                    print_warning "Git checkout had issues, continuing anyway..."
                fi
            fi
        fi

        # Backup existing files prior to deployment (prompt, allow skip)
        if [[ "$DRY_RUN" == true ]]; then
            print_dry_run "Backup existing dotfiles prior to deployment"
        else
            if [[ "$FORCE_MODE" == true ]]; then
                # In force mode, perform backup without prompting
                backup_existing_dotfiles || print_warning "Backup encountered issues (continuing)"
            else
                if prompt_user "Backup existing dotfiles before deployment?"; then
                    backup_existing_dotfiles || print_warning "Backup encountered issues (continuing)"
                else
                    print_skip "User chose to skip backup before deployment"
                fi
            fi
        fi

        print_info "Deploying dotfiles from repository to system locations..."

        # Verify config command is working
        if ! verify_config_command; then
            print_warning "Config command not working properly, using manual deployment"
            manual_deploy_dotfiles
        else
            print_info "Config command available, deploying files..."

            if [[ "$DRY_RUN" == true ]]; then
                print_dry_run "config deploy"
            else
                # Use the config function to deploy files
                if config deploy; then
                    print_success "Dotfiles deployed successfully"
                else
                    print_warning "Some files may have failed to deploy"
                fi
            fi
        fi

        # Set appropriate permissions
        set_dotfile_permissions

    else
        print_warning "Dotfiles directory not found, skipping deployment"
    fi

    mark_step_completed "deploy_config"
}

verify_config_command() {
    # Always verify the function is actually available in this shell
    if type config >/dev/null 2>&1; then
        CONFIG_COMMAND_AVAILABLE=true
        print_success "Config command is available and working"
        return 0
    fi
    # Try sourcing the detected profile file if known
    if [[ -n "$CONFIG_COMMAND_FILE" && -f "$CONFIG_COMMAND_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$CONFIG_COMMAND_FILE" 2>/dev/null || true
        if type config >/dev/null 2>&1; then
            CONFIG_COMMAND_AVAILABLE=true
            print_success "Config command is available and working"
            return 0
        fi
    fi
    print_warning "Config command not available"
    return 1
}

# Manual deployment function (fallback when config command not available)
manual_deploy_dotfiles() {
    print_info "Using manual deployment method..."

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        print_error "Dotfiles directory not found: $DOTFILES_DIR"
        return 1
    fi

    # Source locations are always within the checked-out work-tree ($HOME/.cfg)
    local os_dir="$HOME/.cfg/$CFG_OS"
    local common_dir="$HOME/.cfg/common"

    deploy_file() {
        local repo_file="$1"
        local rel_path sys_file sys_dir base

        # Determine destination based on repo path
        rel_path="${repo_file#$DOTFILES_DIR/}"

        # OS-specific files outside home
        if [[ "$rel_path" == "$CFG_OS/"* && "$rel_path" != */home/* ]]; then
            sys_file="/${rel_path#$CFG_OS/}"
        else
            case "$rel_path" in
                common/config/*)
                    case "$CFG_OS" in
                        linux)
                            base="${XDG_CONFIG_HOME:-$HOME/.config}"
                            sys_file="$base/${rel_path#common/config/}"
                            ;;
                        macos)
                            sys_file="$HOME/Library/Application Support/${rel_path#common/config/}"
                            ;;
                        windows)
                            sys_file="$LOCALAPPDATA\\${rel_path#common/config/}"
                            ;;
                        *)
                            sys_file="$HOME/.config/${rel_path#common/config/}"
                            ;;
                    esac
                    ;;
                common/assets/*)
                    # Assets are repo-internal; do not deploy to filesystem
                    return 0
                    ;;
                common/*)
                    sys_file="$HOME/${rel_path#common/}"
                    ;;
                */home/*)
                    sys_file="$HOME/${rel_path#*/home/}"
                    ;;
                profile/*|README.md)
                    sys_file="$HOME/.cfg/$rel_path"
                    ;;
                *)
                    sys_file="$HOME/.cfg/$rel_path"
                    ;;
            esac
        fi

        sys_dir="$(dirname "$sys_file")"
        mkdir -p "$sys_dir"

        # Avoid copying if source and destination resolve to the same file
        local src_real dst_real
        src_real=$(readlink -f -- "$repo_file" 2>/dev/null || echo "$repo_file")
        dst_real=$(readlink -f -- "$sys_file" 2>/dev/null || echo "$sys_file")
        if [[ -n "$dst_real" && "$src_real" == "$dst_real" ]]; then
            print_skip "Skipping self-copy: $rel_path"
            return 0
        fi

        # Copy with privilege if path is system (/etc, /usr, etc.)
        if [[ "$sys_file" == /* ]]; then
            # If we lack a privilege tool and are not root, skip with clear message
            if [[ -z "$PRIVILEGE_TOOL" && "$EUID" -ne 0 ]]; then
                print_skip "Skipping privileged deploy (no sudo/doas): $rel_path -> $sys_file"
            else
                execute_with_privilege "cp -a '$repo_file' '$sys_file'" \
                    && print_info "Deployed (privileged): $rel_path" \
                    || print_error "Failed to deploy (privileged): $rel_path"
            fi
        else
            cp -a "$repo_file" "$sys_file" \
                && print_info "Deployed: $rel_path" \
                || print_error "Failed to deploy: $rel_path"
        fi
    }

    # Deploy all files in OS dir
    if [[ -d "$os_dir" ]]; then
        find "$os_dir" -type f | while read -r f; do
            deploy_file "$f"
        done
    fi

    # Deploy all files in common dir
    if [[ -d "$common_dir" ]]; then
        find "$common_dir" -type f | while read -r f; do
            deploy_file "$f"
        done
    fi
}

# Set appropriate file permissions
set_dotfile_permissions() {
    print_info "Setting appropriate file permissions..."

    # SSH directory permissions
    if [[ -d "$HOME/.ssh" ]]; then
        chmod 700 "$HOME/.ssh"
        find "$HOME/.ssh" -name "id_*" -not -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true
        find "$HOME/.ssh" -name "*.pub" -exec chmod 644 {} \; 2>/dev/null || true
        find "$HOME/.ssh" -name "config" -exec chmod 600 {} \; 2>/dev/null || true
        print_info "SSH permissions set"
    fi

    # GPG directory permissions
    if [[ -d "$HOME/.gnupg" ]]; then
        chmod 700 "$HOME/.gnupg"
        find "$HOME/.gnupg" -type f -exec chmod 600 {} \; 2>/dev/null || true
        print_info "GPG permissions set"
    fi

    # Make scripts executable
    if [[ -d "$HOME/.local/bin" ]]; then
        find "$HOME/.local/bin" -type f -exec chmod +x {} \; 2>/dev/null || true
        print_info "Script permissions set"
    fi

    if [[ -d "$HOME/.scripts" ]]; then
        find "$HOME/.scripts" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
        print_info "Shell script permissions set"
    fi
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
            # Detect ahead/behind before pulling to avoid unexpected fast-forwards
            execute_command "git --git-dir='$DOTFILES_DIR' fetch origin main" || true
            local ahead behind ab_line
            ahead=0; behind=0
            ab_line=$(git --git-dir="$DOTFILES_DIR" rev-list --left-right --count HEAD...origin/main 2>/dev/null || true)
            # Expected format: "<ahead>\t<behind>"; parse safely
            if [[ "$ab_line" =~ ^([0-9]+)[[:space:]]+([0-9]+)$ ]]; then
                ahead="${BASH_REMATCH[1]}"
                behind="${BASH_REMATCH[2]}"
            fi
            if [[ ${ahead:-0} -gt 0 && ${behind:-0} -eq 0 ]]; then
                print_warning "Your local dotfiles are ahead of origin/main by $ahead commit(s)."
                while true; do
                    echo
                    print_color "$YELLOW" "Choose an action for local-ahead state:"
                    echo "  [k] Keep local (skip pull)"
                    echo "  [p] Push local commits"
                    echo "  [c] Commit new changes and push"
                    echo "  [s] Stash uncommitted changes (if any) and pull"
                    echo "  [a] Abort"
                    printf "%b%s%b" "$YELLOW" "Enter choice [k/p/c/s/a]: " "$NOCOLOR"
                    read -r choice
                    case "${choice,,}" in
                        k)
                            print_warning "Keeping local commits; skipping pull"
                            break
                            ;;
                        p)
                            if execute_command "git --git-dir='$DOTFILES_DIR' --work-tree='$HOME/.cfg' push origin HEAD:main"; then
                                print_success "Pushed local commits"
                            else
                                print_error "Push failed"
                            fi
                            break
                            ;;
                        c)
                            print_info "Committing changes before push..."
                            printf "%b%s%b" "$YELLOW" "Commit message (default: 'WIP local changes via installer'): " "$NOCOLOR"
                            read -r commit_msg
                            [[ -z "$commit_msg" ]] && commit_msg="WIP local changes via installer"
                            if execute_command "git --git-dir='$DOTFILES_DIR' --work-tree='$HOME/.cfg' add -A" \
                               && execute_command "git --git-dir='$DOTFILES_DIR' --work-tree='$HOME/.cfg' commit -m \"$commit_msg\"" \
                               && execute_command "git --git-dir='$DOTFILES_DIR' --work-tree='$HOME/.cfg' push origin HEAD:main"; then
                                print_success "Committed and pushed"
                            else
                                print_error "Commit/push failed"
                            fi
                            break
                            ;;
                        s)
                            print_info "Stashing local (including untracked) before pull..."
                            if execute_command "git --git-dir='$DOTFILES_DIR' --work-tree='$HOME/.cfg' stash push -u -m 'installer-stash'"; then
                                print_success "Stashed local changes"
                            else
                                print_error "Stash failed"
                            fi
                            break
                            ;;
                        a)
                            print_error "Aborted by user"
                            mark_step_failed "install_dotfiles"
                            return 1
                            ;;
                        *)
                            print_warning "Invalid choice. Please enter k/p/c/s/a."
                            ;;
                    esac
                done
            fi
            # If remote is ahead (fast-forward), ask the user before pulling
            if [[ ${behind:-0} -gt 0 && ${ahead:-0} -eq 0 ]]; then
                print_warning "Origin/main is ahead by $behind commit(s)."
                if ! prompt_user "Fast-forward to origin/main now?"; then
                    print_skip "User chose not to fast-forward; skipping pull"
                    # Skip pull entirely
                    goto_after_pull=true
                fi
            fi
            if [[ "${goto_after_pull:-false}" == true ]] || execute_command "git --git-dir='$DOTFILES_DIR' --work-tree='$HOME/.cfg' pull origin main"; then
                update=true
                print_success "Dotfiles updated successfully"
            else
                print_error "Failed to pull updates"
                # Interactive resolution for local changes
                while true; do
                    echo
                    print_color "$YELLOW" "Local changes detected. Choose an action:"
                    echo "  [c] Commit local changes"
                    echo "  [s] Stash local changes"
                    echo "  [k] Keep local changes (skip pulling)"
                    echo "  [a] Abort"
                    printf "%b%s%b" "$YELLOW" "Enter choice [c/s/k/a]: " "$NOCOLOR"
                    read -r choice
                    case "${choice,,}" in
                        c)
                            print_info "Committing local changes..."
                            printf "%b%s%b" "$YELLOW" "Commit message (default: 'WIP local changes via installer'): " "$NOCOLOR"
                            read -r commit_msg
                            [[ -z "$commit_msg" ]] && commit_msg="WIP local changes via installer"
                            if execute_command "git --git-dir='$DOTFILES_DIR' --work-tree='$HOME/.cfg' add -A" \
                               && execute_command "git --git-dir='$DOTFILES_DIR' --work-tree='$HOME/.cfg' commit -m \"$commit_msg\""; then
                                print_success "Committed local changes"
                                print_info "Retrying pull..."
                                if execute_command "git --git-dir='$DOTFILES_DIR' --work-tree='$HOME/.cfg' pull origin main"; then
                                    update=true; print_success "Dotfiles updated successfully"; break
                                else
                                    print_error "Pull failed again after commit. You may resolve manually or choose another option."
                                fi
                            else
                                print_error "Commit failed. Try another option."
                            fi
                            ;;
                        s)
                            print_info "Stashing local changes..."
                            if execute_command "git --git-dir='$DOTFILES_DIR' --work-tree='$HOME/.cfg' stash push -u -m 'installer-stash'"; then
                                print_success "Stashed local changes"
                                print_info "Retrying pull..."
                                if execute_command "git --git-dir='$DOTFILES_DIR' --work-tree='$HOME/.cfg' pull origin main"; then
                                    update=true; print_success "Dotfiles updated successfully"; break
                                else
                                    print_error "Pull failed again after stash. You may resolve manually or choose another option."
                                fi
                            else
                                print_error "Stash failed. Try another option."
                            fi
                            ;;
                        k)
                            print_warning "Keeping local changes and skipping pull"
                            break
                            ;;
                        a)
                            print_error "Aborted by user"
                            mark_step_failed "install_dotfiles"
                            return 1
                            ;;
                        *)
                            print_warning "Invalid choice. Please enter c/s/k/a."
                            ;;
                    esac
                done
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

    # Set up XDG directories (ensure existence; no deletions)
    if command_exists xdg-user-dirs-update; then
        # Suppress tool output to avoid misleading terms like "removed"; we only ensure presence.
        execute_command "xdg-user-dirs-update >/dev/null 2>&1 || true"
        print_success "Ensured XDG user directories exist"
    fi

    mark_step_completed "setup_user_dirs"
}

setup_passwords() {
    print_section "Setting Up Passwords (Optional)"
    save_state "setup_passwords" "started"

    # FORCE_MODE → change passwords directly (no prompt_user)
    if [[ "$FORCE_MODE" == true ]]; then
        print_info "FORCE mode: changing passwords without prompt confirmation"

        # Change current user password
        print_color "$YELLOW" "Enter new password for $USER: "
        read -rs __pw_user; echo
        print_color "$YELLOW" "Confirm new password for $USER: "
        read -rs __pw_user2; echo
        if [[ "$__pw_user" == "$__pw_user2" && -n "$__pw_user" ]]; then
            if execute_with_privilege "bash -lc 'echo \"$USER:$__pw_user\" | chpasswd'"; then
                print_success "Password updated for $USER"
            else
                print_error "Failed to update password for $USER"
            fi
        else
            print_warning "Passwords did not match; skipping $USER"
        fi
        unset __pw_user __pw_user2

        # Change root password
        print_color "$YELLOW" "Enter new password for root: "
        read -rs __pw_root; echo
        print_color "$YELLOW" "Confirm new password for root: "
        read -rs __pw_root2; echo
        if [[ "$__pw_root" == "$__pw_root2" && -n "$__pw_root" ]]; then
            if execute_with_privilege "bash -lc 'echo \"root:$__pw_root\" | chpasswd'"; then
                print_success "Password updated for root"
            else
                print_error "Failed to update password for root"
            fi
        else
            print_warning "Passwords did not match; skipping root"
        fi
        unset __pw_root __pw_root2

        mark_step_completed "setup_passwords"
        return 0
    fi

    # Always ask if not in FORCE_MODE
    if prompt_user "Change password for user '$USER'?" "N"; then
        print_color "$YELLOW" "Enter new password for $USER: "
        read -rs __pw_user; echo
        print_color "$YELLOW" "Confirm new password for $USER: "
        read -rs __pw_user2; echo
        if [[ "$__pw_user" == "$__pw_user2" && -n "$__pw_user" ]]; then
            if execute_with_privilege "bash -lc 'echo \"$USER:$__pw_user\" | chpasswd'"; then
                print_success "Password updated for $USER"
            else
                print_error "Failed to update password for $USER"
            fi
        else
            print_warning "Passwords did not match; skipping $USER"
        fi
        unset __pw_user __pw_user2
    else
        print_skip "User password change (skipped)"
    fi

    if prompt_user "Change password for 'root'?" "N"; then
        print_color "$YELLOW" "Enter new password for root: "
        read -rs __pw_root; echo
        print_color "$YELLOW" "Confirm new password for root: "
        read -rs __pw_root2; echo
        if [[ "$__pw_root" == "$__pw_root2" && -n "$__pw_root" ]]; then
            if execute_with_privilege "bash -lc 'echo \"root:$__pw_root\" | chpasswd'"; then
                print_success "Password updated for root"
            else
                print_error "Failed to update password for root"
            fi
        else
            print_warning "Passwords did not match; skipping root"
        fi
        unset __pw_root __pw_root2
    else
        print_skip "Root password change (skipped)"
    fi

    mark_step_completed "setup_passwords"
}

# Safely sync a system file with backup. Usage: sync_system_file_with_backup /etc/target /path/to/source
sync_system_file_with_backup() {
    local target="$1" src="$2"
    if [[ -z "$target" || -z "$src" ]]; then
        print_error "sync_system_file_with_backup: missing arguments"
        return 1
    fi
    if [[ ! -f "$src" ]]; then
        print_error "Source file not found: $src"
        return 1
    fi
    local backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
    run_privileged "mkdir -p '$(dirname "$target")'" || return 1
    if run_privileged "test -f '$target'"; then
        run_privileged "cp -a '$target' '$backup'" || return 1
        print_info "Backed up $target to $backup"
    fi
    run_privileged "install -m 644 '$src' '$target'" && print_success "Updated $target"
}

# Pre-install essentials (git, curl) early if missing
preinstall_essentials() {
    local need_any=false
    command_exists git || need_any=true
    command_exists curl || need_any=true
    if [[ "$need_any" != true ]]; then
        return 0
    fi
    detect_os
    detect_package_manager || return 1
    update_package_database || true
    local ok=true
    command_exists git  || install_single_package git dependency || ok=false
    command_exists curl || install_single_package curl dependency || ok=false
    [[ "$ok" == true ]]
}

## Privileged file helpers (Utility)
# Ensure a line exists in a file (exact match). Creates file and parent dir if needed. Uses privilege.
ensure_line_in_file_privileged() {
    local file="$1"
    local line="$2"

    # Create parent dir if needed
    local dir
    dir="$(dirname "$file")"
    run_privileged "mkdir -p '$dir'" || return 1

    # Create file if missing
    run_privileged "touch '$file'" || return 1

    # Check exact line presence
    if run_privileged "grep -Fqx -- '$(printf %s "$line" | sed "s/'/'\\''/g")' '$file'"; then
        return 0
    fi

    # Append safely
    run_privileged "printf '%s\n' '$(printf %s "$line" | sed "s/'/'\\''/g")' >> '$file'"
}

install_essentials() {
    print_section "Installing Essential Tools"
    save_state "install_essentials" "started"

    # Fast-path: determine if any package tools are actually missing
    local missing_tools=()
    for tool in "${PACKAGE_TOOLS[@]}"; do
        if [[ "$tool" == "yq" ]]; then
            if command_exists yq || [[ -x "$HOME/.local/bin/yq" ]]; then
                continue
            fi
        elif [[ "$tool" == "jq" ]]; then
            if command_exists jq || is_package_installed jq; then
                continue
            fi
        fi
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -eq 0 ]]; then
        print_skip "All essential tools are already installed"
        mark_step_completed "install_essentials"
        return 0
    fi

    # Install package processing tools first
    for tool in "${PACKAGE_TOOLS[@]}"; do
        if [[ "$tool" == "yq" ]]; then
            if command_exists yq || [[ -x "$HOME/.local/bin/yq" ]]; then
                print_info "Package tool already available: yq"
                continue
            fi
        elif [[ "$tool" == "jq" ]]; then
            if command_exists jq || is_package_installed jq; then
                print_info "Package tool already available: jq"
                continue
            fi
        fi

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
                    if command_exists jq || is_package_installed jq; then
                        print_info "Package tool already available: jq"
                    elif install_single_package "jq" "essential"; then
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
        # Handle custom installs first
        handle_custom_installs "$found_packages_file"

        # Install packages
        if install_packages_from_yaml "$found_packages_file" "$INSTALL_MODE"; then
            mark_step_completed "install_packages"
        else
            print_warning "Some packages failed to install, but continuing..."
            mark_step_completed "install_packages"
        fi
    else
        print_warning "packages.yml not found, attempting to download from GitHub..."

        # Derive raw URL from DOTFILES_URL
        # Supports formats like:
        #   https://github.com/<owner>/<repo>.git
        #   git@github.com:<owner>/<repo>.git
        #   https://github.com/<owner>/<repo>
        local owner repo branch
        branch="main"
        case "$DOTFILES_URL" in
            git@github.com:*)
                owner="${DOTFILES_URL#git@github.com:}"
                owner="${owner%.git}"
                repo="${owner#*/}"
                owner="${owner%%/*}"
                ;;
            https://github.com/*)
                owner="${DOTFILES_URL#https://github.com/}"
                owner="${owner%.git}"
                repo="${owner#*/}"
                owner="${owner%%/*}"
                ;;
            *)
                owner=""
                repo=""
                ;;
        esac

        local packages_url=""
        if [[ -n "$owner" && -n "$repo" ]]; then
            packages_url="https://raw.githubusercontent.com/$owner/$repo/$branch/common/packages.yml"
        fi
        local temp_packages="/tmp/packages.yml"

        if command_exists curl && [[ -n "$packages_url" ]]; then
            if curl -fsSL "$packages_url" -o "$temp_packages" 2>/dev/null; then
                # Create common directory if it doesn't exist
                mkdir -p "$HOME/.cfg/common" 2>/dev/null || mkdir -p "$HOME/common" 2>/dev/null

                # Move to appropriate location
                if [[ -d "$HOME/.cfg/common" ]]; then
                    mv "$temp_packages" "$HOME/.cfg/common/packages.yml"
                    found_packages_file="$HOME/.cfg/common/packages.yml"
                elif [[ -d "$HOME/common" ]]; then
                    mv "$temp_packages" "$HOME/common/packages.yml"
                    found_packages_file="$HOME/common/packages.yml"
                else
                    mv "$temp_packages" "$HOME/packages.yml"
                    found_packages_file="$HOME/packages.yml"
                fi

                print_success "Downloaded packages.yml from GitHub"

                # Now install packages with the downloaded file
                handle_custom_installs "$found_packages_file"
                if install_packages_from_yaml "$found_packages_file" "$INSTALL_MODE"; then
                    mark_step_completed "install_packages"
                else
                    print_warning "Some packages failed to install, but continuing..."
                    mark_step_completed "install_packages"
                fi
            else
                print_warning "Failed to download packages.yml, skipping package installation"
                mark_step_completed "install_packages"
            fi
        else
            print_warning "curl not available and packages.yml not found, skipping package installation"
            mark_step_completed "install_packages"
        fi
    fi

    cd "$original_dir" 2>/dev/null || true
}

setup_shell() {
    print_section "Setting Up Shell Environment"
    save_state "setup_shell" "started"

    # Ensure config command is available before changing shells
    if [[ "$CONFIG_COMMAND_AVAILABLE" != true ]]; then
        print_warning "Config command not available, installing it first..."
        install_config_command || {
            print_error "Failed to install config command before shell setup"
            mark_step_failed "setup_shell"
            return 1
        }
    fi

    if command_exists zsh; then
        zsh_path="$(command -v zsh)"

        if [[ "$FORCE_MODE" == true ]]; then
            print_info "FORCE mode: changing default shell to Zsh without prompting"
            if execute_with_privilege "chsh -s '$zsh_path' '$USER'"; then
                print_success "Default shell changed to Zsh"
                print_warning "Please log out and log back in to apply changes"
            else
                print_error "Failed to change default shell"
            fi
        else
            # Always ask if not in FORCE mode
            if prompt_user "Change default shell to Zsh?" "N"; then
                if execute_with_privilege "chsh -s '$zsh_path' '$USER'"; then
                    print_success "Default shell changed to Zsh"
                    print_warning "Please log out and log back in to apply changes"
                else
                    print_error "Failed to change default shell"
                fi
            else
                print_skip "Default shell change (user chose No)"
            fi
        fi
    else
        print_warning "Zsh not installed, skipping shell setup"
    fi

        # Zsh plugins are managed via packages.yml custom_installs (zsh_plugins)
        # No direct plugin installation here to avoid duplication.

        mark_step_completed "setup_shell"
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
    # use numeric success code: 0=success, 1=failure
    local success=1

    case "$init_system" in
        systemd)
            # Resolve common generic service names to distro-specific systemd unit names
            local svc_candidates=()
            local lower_service
            lower_service="${service,,}"
            case "$lower_service" in
                networkmanager)
                    svc_candidates+=("NetworkManager" "NetworkManager.service" "network-manager")
                    ;;
                sshd)
                    # Debian uses 'ssh' service, others commonly use 'sshd'
                    svc_candidates+=("sshd" "ssh" "sshd.service" "ssh.service")
                    ;;
                *)
                    svc_candidates+=("$service")
                    ;;
            esac

            local tried=false
            local rc=1
            for svc in "${svc_candidates[@]}"; do
                tried=true
                if [ "$action" == "enable" ]; then
                    # Prefer enabling and starting in one go when possible
                    if ! execute_command "$PRIVILEGE_TOOL systemctl enable --now '$svc'"; then
                        execute_command "$PRIVILEGE_TOOL systemctl enable '$svc'"
                    fi
                    rc=$?
                elif [ "$action" == "start" ]; then
                    execute_command "$PRIVILEGE_TOOL systemctl start '$svc'"
                    rc=$?
                else
                    rc=1
                fi
                if [[ $rc -eq 0 ]]; then
                    success=0
                    break
                fi
                print_warning "Failed to $action service candidate: $svc"
            done
            # If we didn't have a special mapping, fall back to original name once
            if [[ "$tried" == false ]]; then
                if [ "$action" == "enable" ]; then
                    execute_command "$PRIVILEGE_TOOL systemctl enable '$service'"
                    rc=$?
                elif [ "$action" == "start" ]; then
                    execute_command "$PRIVILEGE_TOOL systemctl start '$service'"
                    rc=$?
                fi
                [[ $rc -eq 0 ]] && success=0
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

    return $success
}

#======================================
# Service Management Functions
#======================================

configure_services_from_yaml() {
    local packages_file="$1"
    local profile="$2"

    print_section "Configuring System Services"
    save_state "configure_services" "started"

    if [[ "$CFG_OS" != "linux" ]]; then
        print_skip "Service configuration (not supported on $CFG_OS)"
        mark_step_completed "configure_services"
        return 0
    fi

    if [[ ! -f "$packages_file" ]]; then
        print_warning "Package file not found, skipping service configuration"
        mark_step_completed "configure_services"
        return 0
    fi

    # Detect the init system
    local INIT_SYSTEM=$(detect_init_system)
    print_info "Detected Init System: $INIT_SYSTEM"

    # Get services to enable for all profiles
    local services_all
    mapfile -t services_all < <(yq eval ".services.enable.all[]" "$packages_file" 2>/dev/null | grep -v "^null$" || true)

    # Get services to enable for specific profile
    local services_profile
    mapfile -t services_profile < <(yq eval ".services.enable.$profile[]" "$packages_file" 2>/dev/null | grep -v "^null$" || true)

    # Get services to disable for specific profile
    local services_disable
    mapfile -t services_disable < <(yq eval ".services.disable.$profile[]" "$packages_file" 2>/dev/null | grep -v "^null$" || true)

    # Enable services
    for service in "${services_all[@]}" "${services_profile[@]}"; do
        [[ -z "$service" ]] && continue
        if [[ "$FORCE_MODE" == true ]] || prompt_user "Enable $service service?"; then
            if manage_service "enable" "$service" "$INIT_SYSTEM"; then
                manage_service "start" "$service" "$INIT_SYSTEM"
                print_success "Enabled and started $service"
            else
                print_error "Failed to enable $service"
            fi
        fi
    done

    # Disable services
    for service in "${services_disable[@]}"; do
        [[ -z "$service" ]] && continue
        if [[ "$FORCE_MODE" == true ]] || prompt_user "Disable $service service?"; then
            if manage_service "stop" "$service" "$INIT_SYSTEM"; then
                manage_service "disable" "$service" "$INIT_SYSTEM"
                print_success "Stopped and disabled $service"
            else
                print_error "Failed to disable $service"
            fi
        fi
    done

    mark_step_completed "configure_services"
}

configure_services() {
    # Change to home directory to find packages.yml
    local original_dir="$PWD"
    cd "$HOME" 2>/dev/null || true

    local packages_files=("$PACKAGES_FILE" "common/$PACKAGES_FILE" ".cfg/common/$PACKAGES_FILE")
    local found_packages_file=""

    for pf in "${packages_files[@]}"; do
        if [[ -f "$pf" ]]; then
            found_packages_file="$pf"
            break
        fi
    done

    if [[ -n "$found_packages_file" ]]; then
        configure_services_from_yaml "$found_packages_file" "$INSTALL_MODE"
    else
        # Fallback to original configure_services logic
        print_section "Configuring System Services"
        save_state "configure_services" "started"

        if [[ "$CFG_OS" != "linux" ]]; then
            print_skip "Service configuration (not supported on $CFG_OS)"
            mark_step_completed "configure_services"
            return 0
        fi

        # Original service configuration logic here...
        mark_step_completed "configure_services"
    fi

    cd "$original_dir" 2>/dev/null || true
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

#======================================
# Development Environment Setup
#======================================

setup_development_environment() {
    # Accept optional packages_file argument. If missing, try to locate a default.
    local packages_file="${1:-}"
    if [[ -z "$packages_file" ]]; then
        local candidates=("$HOME/$PACKAGES_FILE" "$HOME/common/$PACKAGES_FILE" "$HOME/.cfg/common/$PACKAGES_FILE")
        for pf in "${candidates[@]}"; do
            if [[ -f "$pf" ]]; then
                packages_file="$pf"
                break
            fi
        done
    fi

    print_info "Setting up development environment"

    if [[ -z "$packages_file" || ! -f "$packages_file" ]]; then
        print_warning "Package file not found, skipping development setup"
        return 0
    fi

    # Apply git configuration
    local git_configs
    if command_exists yq; then
        mapfile -t git_configs < <(yq eval ".development.git_config[]" "$packages_file" 2>/dev/null | grep -v "^null$" || true)
    else
        git_configs=()
    fi

    if [[ ${#git_configs[@]} -gt 0 ]] && command_exists git; then
        print_info "Applying git configuration"
        for config in "${git_configs[@]}"; do
            [[ -z "$config" ]] && continue
            print_info "Running: $config"
            execute_command "$config"
        done
    fi
}

# Backup existing files that will be affected by deployment
backup_existing_dotfiles() {
    local backup_root="$BACKUP_DIR/pre-deploy"
    local os_dir="$DOTFILES_DIR/$CFG_OS"
    local common_dir="$DOTFILES_DIR/common"

    print_info "Creating backup at: $backup_root"
    mkdir -p "$backup_root" 2>/dev/null || true

    # Helper to compute destination path similar to manual_deploy_dotfiles
    _compute_dest_path() {
        local repo_file="$1"
        local rel_path sys_file base
        rel_path="${repo_file#$DOTFILES_DIR/}"

        if [[ "$rel_path" == "$CFG_OS/"* && "$rel_path" != */home/* ]]; then
            sys_file="/${rel_path#$CFG_OS/}"
        else
            case "$rel_path" in
                common/config/*)
                    case "$CFG_OS" in
                        linux)
                            base="${XDG_CONFIG_HOME:-$HOME/.config}"
                            sys_file="$base/${rel_path#common/config/}"
                            ;;
                        macos)
                            sys_file="$HOME/Library/Application Support/${rel_path#common/config/}"
                            ;;
                        windows)
                            sys_file="$LOCALAPPDATA\\${rel_path#common/config/}"
                            ;;
                        *)
                            sys_file="$HOME/.config/${rel_path#common/config/}"
                            ;;
                    esac
                    ;;
                common/assets/*)
                    sys_file="$HOME/.cfg/$rel_path"
                    ;;
                common/*)
                    sys_file="$HOME/${rel_path#common/}"
                    ;;
                */home/*)
                    sys_file="$HOME/${rel_path#*/home/}"
                    ;;
                profile/*|README.md)
                    sys_file="$HOME/.cfg/$rel_path"
                    ;;
                *)
                    sys_file="$HOME/.cfg/$rel_path"
                    ;;
            esac
        fi

        echo "$sys_file"
    }

    _backup_one() {
        local repo_file="$1"
        local dest
        dest=$(_compute_dest_path "$repo_file")
        [[ -z "$dest" ]] && return 0

        if [[ -e "$dest" ]]; then
            local rel_path="${repo_file#$DOTFILES_DIR/}"
            local backup_path="$backup_root/$rel_path"
            local backup_dir
            backup_dir="$(dirname "$backup_path")"
            mkdir -p "$backup_dir" 2>/dev/null || true

            if [[ "$dest" == /* ]]; then
                execute_with_privilege "cp -a '$dest' '$backup_path'" \
                    && print_info "Backed up (privileged): $rel_path" \
                    || print_warning "Failed to backup (privileged): $rel_path"
            else
                cp -a "$dest" "$backup_path" \
                    && print_info "Backed up: $rel_path" \
                    || print_warning "Failed to backup: $rel_path"
            fi
        fi
    }

    # Backup files from OS dir
    if [[ -d "$os_dir" ]]; then
        find "$os_dir" -type f | while read -r f; do
            _backup_one "$f"
        done
    fi

    # Backup files from common dir
    if [[ -d "$common_dir" ]]; then
        find "$common_dir" -type f | while read -r f; do
            _backup_one "$f"
        done
    fi

    print_success "Backup completed at: $backup_root"
}

install_rust_development() {
    local packages_file="$1"

    if ! command_exists rustc; then
        install_rust
    fi

    if command_exists cargo; then
        print_info "Installing Rust components"
        local components
        mapfile -t components < <(yq eval ".development.rust.components[]" "$packages_file" 2>/dev/null | grep -v "^null$" || true)

        for component in "${components[@]}"; do
            [[ -z "$component" ]] && continue
            execute_command "rustup component add $component"
        done
    fi
}

install_nodejs_development() {
    local packages_file="$1"

    if ! command_exists node; then
        install_nvm
        install_node
    fi

    if command_exists npm; then
        print_info "Installing global Node.js packages"
        local packages
        mapfile -t packages < <(yq eval ".development.nodejs.global_packages[]" "$packages_file" 2>/dev/null | grep -v "^null$" || true)

        for package in "${packages[@]}"; do
            [[ -z "$package" ]] && continue
            execute_command "npm install -g $package"
        done
    fi
}

install_python_development() {
    local packages_file="$1"

    if command_exists pip || command_exists pip3; then
        print_info "Installing global Python packages"
        local packages
        mapfile -t packages < <(yq eval ".development.python.global_packages[]" "$packages_file" 2>/dev/null | grep -v "^null$" || true)

        local pip_cmd="pip3"
        command_exists pip3 || pip_cmd="pip"

        for package in "${packages[@]}"; do
            [[ -z "$package" ]] && continue
            execute_command "$pip_cmd install --user $package"
        done
    fi
}

get_git_email_guess() {
    local email_guess=""

    # Try to get email from existing git config
    if command_exists git; then
        email_guess=$(git config --global user.email 2>/dev/null || echo "")
        if [[ -n "$email_guess" ]]; then
            echo "$email_guess"
            return 0
        fi
    fi

    # Try to extract from common email-related environment variables
    for var in EMAIL MAIL USER_EMAIL GIT_AUTHOR_EMAIL GIT_COMMITTER_EMAIL; do
        if [[ -n "${!var:-}" ]]; then
            echo "${!var}"
            return 0
        fi
    done

    # Check for email in /etc/passwd gecos field
    if [[ -f /etc/passwd ]]; then
        local gecos
        gecos=$(getent passwd "$USER" 2>/dev/null | cut -d: -f5 | cut -d, -f1)
        if [[ "$gecos" == *@* ]]; then
            echo "$gecos"
            return 0
        fi
    fi

    # Try to guess based on common patterns
    local domain=""

    # Check if we can determine domain from hostname
    if command_exists hostname; then
        local fqdn
        fqdn=$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo "")
        if [[ "$fqdn" == *.* ]]; then
            domain="${fqdn#*.}"
        fi
    fi

    # Fallback domain guessing
    if [[ -z "$domain" ]]; then
        if [[ -f /etc/mailname ]]; then
            domain=$(cat /etc/mailname 2>/dev/null || echo "")
        elif [[ -f /etc/hostname ]]; then
            local hostname_file
            hostname_file=$(cat /etc/hostname 2>/dev/null || echo "")
            if [[ "$hostname_file" == *.* ]]; then
                domain="${hostname_file#*.}"
            fi
        fi
    fi

    # Final fallback
    if [[ -z "$domain" ]]; then
        domain="localhost"
    fi

    echo "${USER}@${domain}"
}

configure_git() {
    local git_name="${USER}"
    local git_email
    git_email=$(get_git_email_guess)

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

#======================================
# System Tweaks Functions
#======================================

apply_system_tweaks() {
    local packages_file="$1"

    print_section "Applying System Tweaks"

    if [[ ! -f "$packages_file" ]]; then
        print_warning "Package file not found, skipping system tweaks"
        return 0
    fi

    # Detect desktop environment and apply appropriate tweaks
    local desktop_env=""
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || command_exists gnome-shell; then
        desktop_env="gnome"
    elif [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] || command_exists plasmashell; then
        desktop_env="kde"
    fi

    if [[ -n "$desktop_env" ]]; then
        print_info "Applying $desktop_env tweaks"

        # Get tweak commands for the desktop environment
        local tweaks
        mapfile -t tweaks < <(yq eval ".system_tweaks.$desktop_env[]" "$packages_file" 2>/dev/null | grep -v "^null$" || true)

        for tweak in "${tweaks[@]}"; do
            [[ -z "$tweak" ]] && continue
            print_info "Applying tweak: $tweak"
            if execute_command "$tweak"; then
                print_success "Applied: $tweak"
            else
                print_warning "Failed to apply: $tweak"
            fi
        done
    else
        print_info "No supported desktop environment detected for tweaks"
    fi

}

apply_tweaks() {
    print_section "Applying System Tweaks"
    save_state "apply_tweaks" "started"

    # Change to home directory to find packages.yml
    local original_dir="$PWD"
    cd "$HOME" 2>/dev/null || true

    local packages_files=("$PACKAGES_FILE" "common/$PACKAGES_FILE" ".cfg/common/$PACKAGES_FILE")
    local found_packages_file=""

    for pf in "${packages_files[@]}"; do
        if [[ -f "$pf" ]]; then
            found_packages_file="$pf"
            break
        fi
    done

    if [[ -n "$found_packages_file" ]]; then
        apply_system_tweaks "$found_packages_file"
    else
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
    fi

    cd "$original_dir" 2>/dev/null || true
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

    # Desktop environment tweaks should be declared in packages.yml under system_tweaks.
    print_info "Linux system tweaks applied (core). Desktop tweaks come from packages.yml."
}

apply_macos_tweaks() {
    print_info "macOS system tweaks applied (placeholder)"
}

#======================================
# Custom Installation Functions
#======================================

handle_custom_installs() {
    local packages_file="$1"

    if [[ ! -f "$packages_file" ]] || ! command_exists yq; then
        return 0
    fi

    print_info "Processing custom installations..."

    # Get custom install commands
    local custom_installs
    mapfile -t custom_installs < <(yq eval ".custom_installs | keys | .[]" "$packages_file" 2>/dev/null | grep -v "^null$" || true)

    for install_name in "${custom_installs[@]}"; do
        [[ -z "$install_name" ]] && continue

        # Check condition
        local condition
        condition=$(yq eval ".custom_installs.$install_name.condition" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")

        if [[ -n "$condition" ]]; then
            # Evaluate condition safely even under set -u (nounset)
            local -i _had_nounset=0
            if set -o | grep -q "nounset\s*on"; then
                _had_nounset=1
                set +u
            fi
            if ! eval "$condition" 2>/dev/null; then
                if [[ $_had_nounset -eq 1 ]]; then set -u; fi
                print_info "Skipping $install_name (condition not met)"
                continue
            fi
            if [[ $_had_nounset -eq 1 ]]; then set -u; fi
        fi

        # Get OS-specific command
        local install_cmd=""
        case "$CFG_OS" in
            linux)
                install_cmd=$(yq eval ".custom_installs.$install_name.linux" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")
                ;;
            macos)
                install_cmd=$(yq eval ".custom_installs.$install_name.macos" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")
                ;;
            windows)
                install_cmd=$(yq eval ".custom_installs.$install_name.windows" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")
                ;;
        esac

        # Fallback to generic command
        if [[ -z "$install_cmd" ]]; then
            install_cmd=$(yq eval ".custom_installs.$install_name.command" "$packages_file" 2>/dev/null | grep -v "^null$" || echo "")
        fi

        if [[ -n "$install_cmd" ]]; then
            print_info "Running custom install: $install_name"
            if execute_command "$install_cmd"; then
                print_success "Custom install completed: $install_name"
                # If yq was installed into ~/.local/bin via custom install, ensure PATH includes it for current session
                if [[ "$install_name" == "yq" && -x "$HOME/.local/bin/yq" ]]; then
                    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                        export PATH="$HOME/.local/bin:$PATH"
                        print_info "Added $HOME/.local/bin to PATH for current session"
                    fi
                fi
            else
                print_error "Custom install failed: $install_name"
            fi
        else
            print_warning "No install command found for $install_name on $CFG_OS"
        fi
    done
}

#======================================
# Installation Mode Selection
#======================================


detect_installation_mode() {
    if [[ "$INSTALL_MODE" != "ask" ]]; then
        return 0  # Mode already set via command line
    fi

    # Check if this is a re-run
    if [[ -d "$DOTFILES_DIR" && ! "$UPDATE_MODE" == true ]]; then
        print_section "Existing Installation Detected"
        print_info "Dotfiles repository already exists at: $DOTFILES_DIR"

        if [[ "$FORCE_MODE" == true ]]; then
            print_info "Force mode: proceeding with update"
            UPDATE_MODE=true
            INSTALL_MODE="essentials"  # Default to essentials for updates
        else
            while true; do
                print_color "$YELLOW" "What would you like to do?"
                print_color "$CYAN" "1. Update existing dotfiles and system"
                print_color "$CYAN" "2. Full reinstallation"
                print_color "$CYAN" "3. Exit"
                print_color "$YELLOW" "Select option [1-3]: "
                read -r response

                case "$response" in
                    1)
                        UPDATE_MODE=true
                        INSTALL_MODE="essentials"
                        print_success "Update mode selected"
                        break
                        ;;
                    2)
                        print_warning "This will backup and reinstall everything"
                        if prompt_user "Continue with full reinstallation?"; then
                            # Backup existing installation
                            local backup_timestamp=$(date +%Y%m%d-%H%M%S)
                            local backup_location="$HOME/.dotfiles-backup-$backup_timestamp"
                            print_info "Backing up existing installation to: $backup_location"
                            cp -r "$DOTFILES_DIR" "$backup_location" 2>/dev/null || true
                            break
                        else
                            continue
                        fi
                        ;;
                    3)
                        print_info "Installation cancelled by user"
                        exit 0
                        ;;
                    *)
                        print_warning "Invalid selection. Please enter 1-3"
                        ;;
                esac
            done
        fi
    fi

    # If still asking, show installation mode selection
    if [[ "$INSTALL_MODE" == "ask" ]]; then
        select_installation_mode
    fi
}

select_installation_mode() {
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
# Ask Mode Implementation
#======================================

should_run_step() {
    local step="$1"
    local description="${INSTALLATION_STEPS[$step]}"

    # Respect explicit skip list
    if is_step_skipped "$step"; then
        return 1
    fi

    # Run-only and run-from controls
    if [[ -n "$RUN_ONLY_STEP" && "$step" != "$RUN_ONLY_STEP" ]]; then
        return 1
    fi
    if [[ -n "$RUN_FROM_STEP" && "$__RUN_FROM_STARTED" != true ]]; then
        if [[ "$step" == "$RUN_FROM_STEP" ]]; then
            __RUN_FROM_STARTED=true
        else
            return 1
        fi
    fi

    # Skip already completed steps unless forced
    if is_step_completed "$step" && [[ "$FORCE_MODE" != true ]]; then
        return 1
    fi

    # Ask mode prompt
    if [[ "$ASK_MODE" == true ]]; then
        prompt_user "Run step: $description?" && return 0 || return 1
    fi

    # Interactive skip even when not in ask mode (non-essential steps)
    if [[ "$INTERACTIVE_SKIP" == true ]]; then
        local is_essential=false
        for es in "${ESSENTIAL_STEPS[@]}"; do [[ "$es" == "$step" ]] && is_essential=true && break; done
        if [[ "$is_essential" != true ]]; then
            if ! prompt_user "Proceed with: $description? (Choose No to skip)"; then
                return 1
            fi
        fi
    fi

    return 0
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
    -a, --ask               Ask before running each step
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
    $0 --ask --mode minimal # Ask before each step in minimal mode

NOTES:
    • Running without arguments on an existing installation will default to update mode
    • Use --force to override existing installations
    • Use --ask to have control over each installation step
    • Configuration files are backed up before modification

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
            -a|--ask)
                ASK_MODE=true
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

    if [[ "$ASK_MODE" == true ]]; then
        print_warning "ASK MODE - You will be prompted for each step"
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

    # Detect installation mode (handles re-runs and updates)
    detect_installation_mode

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
    if [[ "$FORCE_MODE" != true ]] && [[ "$DRY_RUN" != true ]] && [[ "$ASK_MODE" != true ]]; then
        if ! prompt_user "Continue with installation?"; then
            print_info "Installation cancelled by user"
            exit 0
        fi
    fi

    # Execute installation steps
    local failed_steps=()
    local step_number=1
    local total_steps=${#STEP_ORDER[@]}

    for step in "${STEP_ORDER[@]}"; do
        echo
        print_color "$CYAN$BOLD" "[$step_number/$total_steps] ${INSTALLATION_STEPS[$step]}"

        # Check if we should run this step (ask mode)
        if ! should_run_step "$step"; then
            print_skip "${INSTALLATION_STEPS[$step]} (user choice)"
            step_number=$((step_number + 1))
            continue
        fi

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
        print_color "$CYAN" "• Test the config command: config status"

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
if [[ "${BASH_SOURCE[0]-}" == "$0" ]]; then
    # Ensure basic requirements (attempt auto-install if possible)
    if ! command_exists git || ! command_exists curl; then
        print_warning "git/curl missing; attempting to install prerequisites"
        preinstall_essentials || {
            print_error "Required tools git/curl are not installed and could not be auto-installed"
            exit 1
        }
    fi

    main "$@"
fi
