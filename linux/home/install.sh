#!/usr/bin/env bash

# Dotfiles Installation Script
#=========================================================

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
STATE_FILE="$HOME/.local/share/dotfiles_install_state"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

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

# Installation steps configuration
declare -A INSTALLATION_STEPS=(
    ["install_dotfiles"]="Install dotfiles repository"
    ["setup_user_dirs"]="Setup user directories"
    ["install_packages"]="Install system packages"
    ["setup_shell"]="Setup shell environment"
    ["setup_ssh"]="Setup SSH configuration"
    ["configure_services"]="Configure system services"
    ["setup_development"]="Setup development environment"
    ["apply_tweaks"]="Apply system tweaks"
)

# Step order (important for dependencies)
STEP_ORDER=(
    "install_dotfiles"
    "setup_user_dirs"
    "install_packages"
    "setup_shell"
    "setup_ssh"
    "configure_services"
    "setup_development"
    "apply_tweaks"
)

#======================================
# State Management Functions
#======================================

# Save current state
save_state() {
    local current_step="$1"
    local status="$2"  # started, completed, failed

    mkdir -p "$(dirname "$STATE_FILE")"

    {
        echo "LAST_STEP=$current_step"
        echo "STEP_STATUS=$status"
        echo "TIMESTAMP=$(date +%s)"
        echo "RESUME_AVAILABLE=true"

        # Save completed steps
        echo "COMPLETED_STEPS=(${COMPLETED_STEPS[*]})"

        # Save environment info
        echo "CFG_OS=$CFG_OS"
        echo "DISTRO=${DISTRO:-}"
        echo "PRIVILEGE_TOOL=${PRIVILEGE_TOOL:-}"

    } > "$STATE_FILE"
}

# Load previous state
load_state() {
    if [[ -f "$STATE_FILE" ]]; then
        source "$STATE_FILE"
        return 0
    else
        return 1
    fi
}

# Clear state file
clear_state() {
    [[ -f "$STATE_FILE" ]] && rm -f "$STATE_FILE"
}

# Check if step was completed
is_step_completed() {
    local step="$1"
    [[ " ${COMPLETED_STEPS[*]} " =~ " ${step} " ]]
}

# Mark step as completed
mark_step_completed() {
    local step="$1"
    if ! is_step_completed "$step"; then
        COMPLETED_STEPS+=("$step")
    fi
    save_state "$step" "completed"
}

# Mark step as failed
mark_step_failed() {
    local step="$1"
    save_state "$step" "failed"
}

#======================================
# Command Line Argument Parsing
#======================================

show_help() {
    cat << EOF
Enhanced Dotfiles Installation Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -r, --resume        Resume from last failed step
    -u, --update        Update existing dotfiles and packages
    -v, --verbose       Enable verbose output
    -n, --dry-run       Show what would be done without executing
    -f, --force         Force reinstallation of components
    --step STEP         Run only specific step
    --skip STEP         Skip specific step
    --list-steps        List all available steps
    --status            Show current installation status
    --clean             Clean up state and backup files

STEPS:
EOF

    for step in "${STEP_ORDER[@]}"; do
        printf "    %-20s %s\n" "$step" "${INSTALLATION_STEPS[$step]}"
    done

    cat << EOF

EXAMPLES:
    $0                          # Full installation
    $0 --resume                 # Resume from last failed step
    $0 --update                 # Update existing installation
    $0 --step install_packages  # Run only package installation
    $0 --skip setup_ssh         # Skip SSH setup
    $0 --dry-run                # Preview what would be done

EOF
}

parse_arguments() {
    local specific_steps=()
    local skip_steps=()

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
            --step)
                if [[ -n "${2:-}" ]]; then
                    specific_steps+=("$2")
                    shift 2
                else
                    print_error "Option --step requires a step name"
                    exit 1
                fi
                ;;
            --skip)
                if [[ -n "${2:-}" ]]; then
                    skip_steps+=("$2")
                    shift 2
                else
                    print_error "Option --skip requires a step name"
                    exit 1
                fi
                ;;
            --list-steps)
                echo "Available installation steps:"
                for step in "${STEP_ORDER[@]}"; do
                    printf "  %-20s %s\n" "$step" "${INSTALLATION_STEPS[$step]}"
                done
                exit 0
                ;;
            --status)
                show_status
                exit 0
                ;;
            --clean)
                cleanup_files
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Apply step filters
    if [[ ${#specific_steps[@]} -gt 0 ]]; then
        STEP_ORDER=("${specific_steps[@]}")
    fi

    if [[ ${#skip_steps[@]} -gt 0 ]]; then
        local filtered_steps=()
        for step in "${STEP_ORDER[@]}"; do
            if [[ ! " ${skip_steps[*]} " =~ " ${step} " ]]; then
                filtered_steps+=("$step")
            fi
        done
        STEP_ORDER=("${filtered_steps[@]}")
    fi
}

#======================================
# Status and Cleanup Functions
#======================================

show_status() {
    print_header "Installation Status"

    if [[ -f "$STATE_FILE" ]]; then
        load_state

        print_section "Current State"
        print_info "Last step: ${LAST_STEP:-unknown}"
        print_info "Step status: ${STEP_STATUS:-unknown}"
        print_info "Timestamp: $(date -d "@${TIMESTAMP:-0}" 2>/dev/null || echo "unknown")"

        print_section "Completed Steps"
        if [[ ${#COMPLETED_STEPS[@]} -gt 0 ]]; then
            for step in "${COMPLETED_STEPS[@]}"; do
                print_success "$step: ${INSTALLATION_STEPS[$step]:-unknown}"
            done
        else
            print_info "No steps completed yet"
        fi

        print_section "Remaining Steps"
        local remaining_steps=()
        for step in "${STEP_ORDER[@]}"; do
            if ! is_step_completed "$step"; then
                remaining_steps+=("$step")
            fi
        done

        if [[ ${#remaining_steps[@]} -gt 0 ]]; then
            for step in "${remaining_steps[@]}"; do
                print_warning "$step: ${INSTALLATION_STEPS[$step]:-unknown}"
            done
            echo
            print_info "Run with --resume to continue from where you left off"
        else
            print_success "All steps completed!"
        fi
    else
        print_info "No installation state found"
        print_info "Run the script to start a new installation"
    fi
}

cleanup_files() {
    print_header "Cleanup"

    local files_to_clean=(
        "$STATE_FILE"
        "$LOG_FILE"
    )

    # Find backup directories
    mapfile -t backup_dirs < <(find "$HOME" -maxdepth 1 -name ".dotfiles-backup-*" -type d 2>/dev/null || true)

    if [[ ${#backup_dirs[@]} -gt 0 ]]; then
        print_section "Backup Directories Found"
        for dir in "${backup_dirs[@]}"; do
            print_info "$(basename "$dir") - $(ls -la "$dir" 2>/dev/null | wc -l) files"
        done

        if prompt_user "Remove backup directories?"; then
            for dir in "${backup_dirs[@]}"; do
                rm -rf "$dir" && print_success "Removed $(basename "$dir")"
            done
        fi
    fi

    print_section "State and Log Files"
    for file in "${files_to_clean[@]}"; do
        if [[ -f "$file" ]]; then
            print_info "Found: $file"
            if prompt_user "Remove $(basename "$file")?"; then
                rm -f "$file" && print_success "Removed $(basename "$file")"
            fi
        fi
    done

    print_success "Cleanup completed"
}

#======================================
# UI Functions (keeping existing ones and adding new)
#======================================

# Print colorized output
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NOCOLOR}"

    # Log to file if logging is setup
    if [[ -n "${LOG_FILE:-}" && -f "$LOG_FILE" ]]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
    fi
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
    if [[ "$VERBOSE_MODE" == true ]] || [[ "${2:-}" == "always" ]]; then
        print_color "$CYAN" "ℹ $message"
    fi
}

# Print skip message
print_skip() {
    local message="$1"
    print_color "$YELLOW" "⏭ $message"
    SKIPPED_ITEMS+=("⏭ $message")
}

# Print dry run message
print_dry_run() {
    local message="$1"
    print_color "$MAGENTA" "[DRY RUN] $message"
}

#======================================
# Logging Functions (enhanced)
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

    # Archive old log file if it exists
    if [[ -f "$LOG_FILE" ]]; then
        local archived_log="$TRASH_DIR/dotfiles_install_$(date +%Y%m%d_%H%M%S).log"
        mv "$LOG_FILE" "$archived_log"
        print_info "Archived previous log to: $archived_log" "always"
    fi

    # Initialize log file
    {
        echo "======================================="
        echo "Enhanced Dotfiles Installation Log"
        echo "Date: $(date)"
        echo "User: $USER"
        echo "Host: $HOSTNAME"
        echo "OS: $(uname -s)"
        echo "Args: $*"
        echo "Resume Mode: $RESUME_MODE"
        echo "Update Mode: $UPDATE_MODE"
        echo "Verbose Mode: $VERBOSE_MODE"
        echo "Dry Run: $DRY_RUN"
        echo "Force Mode: $FORCE_MODE"
        echo "======================================="
        echo
    } > "$LOG_FILE"

    print_info "Log file initialized: $LOG_FILE" "always"
}

# Enhanced log function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp="$(date +'%Y-%m-%d %H:%M:%S')"
    echo "[$level] $timestamp - $message" >> "$LOG_FILE"

    if [[ "$VERBOSE_MODE" == true ]]; then
        case "$level" in
            ERROR) print_color "$RED" "[$level] $message" ;;
            WARN)  print_color "$YELLOW" "[$level] $message" ;;
            INFO)  print_color "$CYAN" "[$level] $message" ;;
            *)     echo "[$level] $message" ;;
        esac
    fi
}

#======================================
# User Interaction Functions (enhanced)
#======================================

# Enhanced prompt function
prompt_user() {
    local question="$1"
    local default="${2:-Y}"
    local response
    local timeout="${3:-0}"

    # Skip prompts in non-interactive mode or when forcing
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

        if [[ "$timeout" -gt 0 ]]; then
            if ! read -t "$timeout" -r response; then
                print_info "Timed out, using default: $default"
                response="$default"
            fi
        else
            read -r response
        fi

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

# Progress indicator
show_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))

    printf "\r"
    print_color "$BLUE" "[$current/$total] "
    printf "%s" "$(printf '█%.0s' $(seq 1 $filled))"
    printf "%s" "$(printf '░%.0s' $(seq 1 $empty))"
    print_color "$BLUE" " ${percent}%% - $message"
}

#======================================
# System Detection Functions (keeping existing)
#======================================

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Linux)   CFG_OS="linux" ;;
        Darwin)  CFG_OS="macos" ;;
        MINGW*|MSYS*|CYGWIN*) CFG_OS="windows" ;;
        *)       CFG_OS="unknown" ;;
    esac

    print_info "Detected OS: $CFG_OS" "always"
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
# Enhanced Utility Functions
#======================================

# Check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Execute with dry run support
execute_command() {
    local cmd="$*"
    log_message "INFO" "Executing: $cmd"

    if [[ "$DRY_RUN" == true ]]; then
        print_warning "DRY RUN MODE - No changes will be made"
        echo
    fi

    print_info "Starting installation for user: $USER" "always"
    print_info "Log file: $LOG_FILE" "always"
    print_info "Mode: $(
        [[ "$RESUME_MODE" == true ]] && echo "Resume" ||
        [[ "$UPDATE_MODE" == true ]] && echo "Update" ||
        echo "Fresh Install"
    )" "always"

    # Handle resume mode
    if [[ "$RESUME_MODE" == true ]]; then
        if load_state; then
            print_info "Resuming from previous installation..." "always"
            print_info "Last step: ${LAST_STEP:-unknown}" "always"
            print_info "Step status: ${STEP_STATUS:-unknown}" "always"

            # Load completed steps from state
            if [[ -n "${COMPLETED_STEPS:-}" ]]; then
                eval "COMPLETED_STEPS=(${COMPLETED_STEPS})"
            fi
        else
            print_warning "No previous installation state found"
            print_info "Starting fresh installation..."
            RESUME_MODE=false
        fi
    fi

    # Pre-flight checks
    detect_os
    detect_privilege_tools

    if [[ "$CFG_OS" == "linux" ]]; then
        detect_linux_distro || {
            print_error "Failed to detect Linux distribution"
            exit 1
        }
    fi

    # Show installation plan
    echo
    print_color "$YELLOW$BOLD" "Installation Plan:"
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
    if [[ "$FORCE_MODE" != true ]] && ! prompt_user "Continue with installation?"; then
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
            log_message "INFO" "Step completed successfully: $step"
        else
            failed_steps+=("$step")
            log_message "ERROR" "Step failed: $step"

            # Ask if user wants to continue
            if [[ "$FORCE_MODE" != true ]]; then
                echo
                if ! prompt_user "Step '$step' failed. Continue with remaining steps?" "Y"; then
                    print_info "Installation stopped by user"
                    break
                fi
            fi
        fi

        step_number=$((step_number + 1))
    done

    # Post-installation tasks
    if [[ ${#failed_steps[@]} -eq 0 ]]; then
        print_success "All installation steps completed successfully!"
        clear_state
    else
        print_warning "${#failed_steps[@]} steps failed: ${failed_steps[*]}"
        save_state "${failed_steps[-1]}" "failed"
    fi

    # Show summary
    print_installation_summary

    log_message "INFO" "Installation process completed"

    # Exit with appropriate code
    [[ ${#failed_steps[@]} -eq 0 ]] && exit 0 || exit 1
}

#======================================
# Error Handling and Cleanup
#======================================

# Trap for cleanup on exit
cleanup_on_exit() {
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        print_error "Installation interrupted (exit code: $exit_code)"
        log_message "ERROR" "Installation interrupted with exit code: $exit_code"

        # Save state for resume
        if [[ -n "${current_step:-}" ]]; then
            save_state "$current_step" "interrupted"
            print_info "State saved. Run with --resume to continue from where you left off"
        fi
    fi

    # Cleanup temporary files if any
    if [[ -n "${TEMP_DIR:-}" ]] && [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Trap for handling interruptions
handle_interrupt() {
    print_warning "Installation interrupted by user"
    log_message "WARN" "Installation interrupted by user (SIGINT)"
    exit 130
}

# Set up traps
trap cleanup_on_exit EXIT
trap handle_interrupt INT

#======================================
# MacOS and Windows Support Stubs
#======================================

# Install macOS packages (placeholder)
install_macos_packages() {
    local packages_file="$1"

    print_info "macOS package installation"

    if ! command_exists brew; then
        print_info "Installing Homebrew..."
        if execute_command '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'; then
            print_success "Homebrew installed"
        else
            print_error "Failed to install Homebrew"
            return 1
        fi
    fi

    # Install packages from YAML
    local packages=()
    if [[ "$DRY_RUN" != true ]]; then
        mapfile -t packages < <(yq e '.packages.macos[]' "$packages_file" 2>/dev/null | grep -v "^null$" || true)
    fi

    if [[ ${#packages[@]} -gt 0 ]]; then
        for package in "${packages[@]}"; do
            if execute_command "brew install '$package'"; then
                print_success "Installed $package"
            else
                print_error "Failed to install $package"
            fi
        done
    fi
}

# Install Windows packages (placeholder)
install_windows_packages() {
    local packages_file="$1"

    print_info "Windows package installation"
    print_warning "Windows package installation not fully implemented"

    # Could implement with Chocolatey, Scoop, or winget
    if command_exists choco; then
        print_info "Using Chocolatey for package management"
        # Implementation would go here
    elif command_exists scoop; then
        print_info "Using Scoop for package management"
        # Implementation would go here
    elif command_exists winget; then
        print_info "Using Windows Package Manager (winget)"
        # Implementation would go here
    else
        print_warning "No package manager found for Windows"
        return 1
    fi
}

#======================================
# Additional Utility Functions
#======================================

# Check system requirements
check_system_requirements() {
    local requirements_met=true

    # Check for required commands
    local required_commands=("git" "curl")
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            print_error "Required command not found: $cmd"
            requirements_met=false
        fi
    done

    # Check disk space (require at least 1GB free)
    local available_space
    available_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    if [[ "$available_space" -lt 1048576 ]]; then  # 1GB in KB
        print_warning "Low disk space available: $(($available_space / 1024))MB"
    fi

    # Check internet connectivity
    if ! curl -s --head --request GET https://github.com >/dev/null; then
        print_warning "No internet connectivity detected"
        print_info "Some features may not work properly"
    fi

    return $(($requirements_met ? 0 : 1))
}

# Validate configuration files
validate_config() {
    local config_dir="$HOME/.config"
    local issues_found=false

    # Check for common configuration issues
    if [[ -f "$config_dir/packages.yml" ]]; then
        if ! yq e '.' "$config_dir/packages.yml" >/dev/null 2>&1; then
            print_error "Invalid YAML syntax in packages.yml"
            issues_found=true
        fi
    fi

    # Check for conflicting dotfiles
    local common_conflicts=(".bashrc" ".zshrc" ".vimrc" ".gitconfig")
    for file in "${common_conflicts[@]}"; do
        if [[ -f "$HOME/$file" ]] && [[ ! -L "$HOME/$file" ]]; then
            print_warning "Potential conflict: $HOME/$file exists and is not a symlink"
        fi
    done

    return $(($issues_found ? 1 : 0))
}

#======================================
# Script Entry Point
#======================================

# Execute the main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Check system requirements first
    if ! check_system_requirements; then
        print_error "System requirements not met"
        exit 1
    fi

    # Run main installation
    main "$@"
fi
        print_dry_run "$cmd"
        return 0
    fi

    if [[ "$VERBOSE_MODE" == true ]]; then
        print_info "Running: $cmd"
    fi

    eval "$cmd"
}

# Download file with progress
download_file() {
    local url="$1"
    local output="$2"

    if [[ "$DRY_RUN" == true ]]; then
        print_dry_run "Download: $url -> $output"
        return 0
    fi

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

# Backup existing files
backup_file() {
    local file="$1"
    local backup_path="$BACKUP_DIR/$(dirname "${file#$HOME/}")"

    if [[ "$DRY_RUN" == true ]]; then
        print_dry_run "Backup: $file -> $backup_path"
        return 0
    fi

    if [[ -e "$file" ]]; then
        mkdir -p "$backup_path"
        cp -a "$file" "$backup_path/"
        print_info "Backed up: $file"
        return 0
    fi
    return 1
}

#======================================
# Git Configuration Functions (keeping existing)
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

# Dotfiles Management System (keeping existing config function)
if [[ -d "$HOME/.cfg" && -d "$HOME/.cfg/refs" ]]; then
    # Core git wrapper with repository as work-tree
    _config() {
        git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"
    }

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
                echo ""
                return
                ;;
            "common/"*)
                echo "$f"
                return
                ;;
            "$CFG_OS/"*)
                echo "$f"
                return
                ;;
            *)
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
                file_path="${repo_path#common/config/}"
                if [[ "$CFG_OS" == "windows" ]]; then
                    echo "$HOME/AppData/Local/$file_path"
                else
                    echo "$HOME/.config/$file_path"
                fi
                ;;
            common/bin/*)
                file_path="${repo_path#common/bin/}"
                if [[ "$CFG_OS" == "windows" ]]; then
                    echo "$HOME/bin/$file_path"
                else
                    echo "$HOME/.local/bin/$file_path"
                fi
                ;;
            common/*)
                file_path="${repo_path#common/}"
                echo "$HOME/$file_path"
                ;;
            */home/*)
                file_path="${repo_path#*/home/}"
                echo "$HOME/$file_path"
                ;;
            */root/*)
                file_path="${repo_path#*/root/}"
                echo "/$file_path"
                ;;
            *)
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

    # Enhanced config command
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
                local rm_opts=""
                local file_path_list=()

                # Separate options from file paths
                for arg in "$@"; do
                    if [[ "$arg" == "-"* ]]; then
                        rm_opts+=" $arg"
                    else
                        file_path_list+=("$arg")
                    fi
                done

                for file_path in "${file_path_list[@]}"; do
                    local repo_path="$(_repo_path "$file_path")"

                    # Use a dummy run of `git rm` to handle the recursive flag
                    if [[ "$rm_opts" == *"-r"* ]]; then
                        _config rm --cached -r "$repo_path"
                    else
                        _config rm --cached "$repo_path"
                    fi

                    # Remove from the filesystem, passing the collected options
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
                        if [[ -e "$sys_file" && -n "$(diff "$full_repo_path" "$sys_file" 2>/dev/null || true)" ]]; then
                            cp -a "$sys_file" "$full_repo_path"
                            echo "Synced to repo: $sys_file"
                        fi
                    elif [[ "$direction" == "from-repo" ]]; then
                        if [[ -e "$full_repo_path" && -n "$(diff "$full_repo_path" "$sys_file" 2>/dev/null || true)" ]]; then
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

#======================================
# Enhanced Installation Functions
#======================================

# Install dotfiles
install_dotfiles() {
    print_section "Installing Dotfiles"
    save_state "install_dotfiles" "started"

    local update=false

    if [[ -d "$DOTFILES_DIR" ]]; then
        if [[ "$UPDATE_MODE" == true ]] || prompt_user "Dotfiles repository already exists. Update it?"; then
            print_info "Updating existing dotfiles..."
            if execute_command "config pull origin main"; then
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

    # Check for conflicts only if not updating
    if [[ "$update" != true ]]; then
        local conflicts
        conflicts=$(config checkout 2>&1 | grep -E "^\s+" | awk '{print $1}' || true)

        if [[ -n "$conflicts" ]]; then
            print_warning "The following files will be overwritten:"
            echo "$conflicts"

            if [[ "$FORCE_MODE" == true ]] || prompt_user "Continue and backup/overwrite these files?"; then
                # Backup conflicting files
                create_dir "$BACKUP_DIR"
                print_info "Backing up conflicting files to: $BACKUP_DIR"

                while IFS= read -r file; do
                    [[ -z "$file" ]] && continue
                    backup_file "$HOME/$file"
                done <<< "$conflicts"

                print_info "Backed up conflicting files to: $BACKUP_DIR"
            else
                print_error "Installation cancelled by user"
                mark_step_failed "install_dotfiles"
                return 1
            fi
        fi

        # Checkout files
        if execute_command "config checkout -f"; then
            print_success "Dotfiles checked out successfully"
        else
            print_error "Failed to checkout dotfiles"
            mark_step_failed "install_dotfiles"
            return 1
        fi
    fi

    # Configure repository
    execute_command "config config status.showUntrackedFiles no"

    mark_step_completed "install_dotfiles"
    print_success "Dotfiles installed successfully"
}

# Create user directories
setup_user_dirs() {
    print_section "Setting Up User Directories"
    save_state "setup_user_dirs" "started"

    local directories=('.cache' '.config' '.local/bin' '.local/share' '.scripts')

    for dir in "${directories[@]}"; do
        create_dir "$HOME/$dir"
    done

    # Handle XDG user directories
    if [[ -f "$HOME/.config/user-dirs.dirs" ]]; then
        if [[ "$FORCE_MODE" == true ]] || prompt_user "Configure XDG user directories?"; then
            if [[ "$DRY_RUN" != true ]]; then
                source "$HOME/.config/user-dirs.dirs"
            fi

            # Create XDG directories
            for var in XDG_DESKTOP_DIR XDG_DOWNLOAD_DIR XDG_TEMPLATES_DIR XDG_PUBLICSHARE_DIR \
                      XDG_DOCUMENTS_DIR XDG_MUSIC_DIR XDG_PICTURES_DIR XDG_VIDEOS_DIR; do
                local dir_path="${!var:-}"
                [[ -n "$dir_path" ]] && create_dir "$dir_path"
            done

            print_success "XDG user directories configured"
        fi
    fi

    mark_step_completed "setup_user_dirs"
}

# Enhanced yq installation
install_yq() {
    local bin_dir="$HOME/.local/bin"
    local yq_path="$bin_dir/yq"

    if command_exists yq && [[ "$FORCE_MODE" != true ]]; then
        print_info "yq already available"
        return 0
    fi

    local yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"

    case "$CFG_OS" in
        linux)
            case "$(uname -m)" in
                x86_64) yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" ;;
                aarch64) yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_arm64" ;;
                *) print_error "Unsupported architecture for yq installation"; return 1 ;;
            esac
            ;;
        macos)
            yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_darwin_amd64"
            ;;
        *)
            print_error "yq installation not supported for $CFG_OS"
            return 1
            ;;
    esac

    print_info "Installing yq..."

    create_dir "$bin_dir"
    download_file "$yq_url" "$yq_path" || return 1
    execute_command "chmod +x '$yq_path'" || return 1

    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        export PATH="$bin_dir:$PATH"
        if [[ "$DRY_RUN" != true ]]; then
            echo "export PATH=\"$bin_dir:\$PATH\"" >> "$HOME/.bashrc"
        fi
    fi

    print_success "yq installed successfully"
}

# Enhanced package installation
install_packages() {
    print_section "Installing Packages"
    save_state "install_packages" "started"

    local packages_file="$HOME/.config/packages.yml"

    # Check if yq is available for YAML parsing
    if ! command_exists yq; then
        if [[ "$FORCE_MODE" == true ]] || prompt_user "yq (YAML parser) is required. Install it?"; then
            install_yq || {
                print_error "Failed to install yq"
                mark_step_failed "install_packages"
                return 1
            }
        else
            print_skip "Package installation (requires yq)"
            mark_step_completed "install_packages"
            return 0
        fi
    fi

    if [[ ! -f "$packages_file" ]]; then
        print_warning "packages.yml not found at $packages_file, checking current directory..."
        if [[ -f "packages.yml" ]]; then
            packages_file="packages.yml"
        else
            print_warning "packages.yml not found, skipping package installation"
            mark_step_completed "install_packages"
            return 0
        fi
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

    mark_step_completed "install_packages"
}

# Enhanced Linux package installation
install_linux_packages() {
    local packages_file="$1"
    local failed_packages=()
    local installed_packages=()
    local skipped_packages=()

    # Get package lists
    local base_packages=()
    local distro_packages=()

    if [[ "$DRY_RUN" != true ]]; then
        mapfile -t base_packages < <(yq e '.packages.base[]' "$packages_file" 2>/dev/null | grep -v "^null$" || true)

        case "$DISTRO" in
            PACMAN)
                mapfile -t distro_packages < <(yq e '.packages.arch[]' "$packages_file" 2>/dev/null | grep -v "^null$" || true)
                ;;
            APT)
                mapfile -t distro_packages < <(yq e '.packages.debian[]' "$packages_file" 2>/dev/null | grep -v "^null$" || true)
                ;;
            DNF)
                mapfile -t distro_packages < <(yq e '.packages.fedora[]' "$packages_file" 2>/dev/null | grep -v "^null$" || true)
                ;;
        esac
    fi

    # Combine package lists
    local all_packages=("${base_packages[@]}" "${distro_packages[@]}")

    if [[ ${#all_packages[@]} -eq 0 ]]; then
        print_warning "No packages found in configuration"
        return 0
    fi

    print_info "Found ${#all_packages[@]} packages to install"

    # Update package database first
    if [[ "$UPDATE_MODE" == true ]] || [[ "$FORCE_MODE" == true ]] || prompt_user "Update package database before installing?" "Y" 30; then
        print_info "Updating package database..."
        case "$DISTRO" in
            PACMAN) execute_command "$PRIVILEGE_TOOL pacman -Sy" ;;
            APT) execute_command "$PRIVILEGE_TOOL apt update" ;;
            DNF) execute_command "$PRIVILEGE_TOOL dnf check-update || true" ;;
            ZYPPER) execute_command "$PRIVILEGE_TOOL zypper refresh" ;;
            PORTAGE) execute_command "$PRIVILEGE_TOOL emerge --sync" ;;
        esac
    fi

    # Install packages with progress indicator
    local current=0
    for package in "${all_packages[@]}"; do
        [[ -z "$package" ]] && continue

        current=$((current + 1))
        show_progress "$current" "${#all_packages[@]}" "$package"

        # Check if package is already installed
        local already_installed=false
        case "$DISTRO" in
            PACMAN)
                if pacman -Q "$package" &>/dev/null; then
                    already_installed=true
                fi
                ;;
            APT)
                if dpkg -l "$package" 2>/dev/null | grep -q "^ii"; then
                    already_installed=true
                fi
                ;;
            DNF)
                if rpm -q "$package" &>/dev/null; then
                    already_installed=true
                fi
                ;;
        esac

        if [[ "$already_installed" == true ]] && [[ "$FORCE_MODE" != true ]]; then
            skipped_packages+=("$package")
            continue
        fi

        # Install package
        local install_cmd=""
        case "$DISTRO" in
            PACMAN)
                install_cmd="$PRIVILEGE_TOOL pacman -S --noconfirm '$package'"
                ;;
            APT)
                install_cmd="$PRIVILEGE_TOOL apt install -y '$package'"
                ;;
            DNF)
                install_cmd="$PRIVILEGE_TOOL dnf install -y '$package'"
                ;;
        esac

        if execute_command "$install_cmd"; then
            installed_packages+=("$package")
        else
            failed_packages+=("$package")
        fi
    done

    echo # Clear progress line

    # Report results
    if [[ ${#installed_packages[@]} -gt 0 ]]; then
        print_success "Successfully installed ${#installed_packages[@]} packages"
    fi

    if [[ ${#skipped_packages[@]} -gt 0 ]]; then
        print_info "Skipped ${#skipped_packages[@]} already installed packages"
    fi

    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        print_error "Failed to install ${#failed_packages[@]} packages: ${failed_packages[*]}"
        return 1
    fi

    return 0
}

# Enhanced shell setup
setup_shell() {
    print_section "Setting Up Shell Environment"
    save_state "setup_shell" "started"

    # Install Zsh if requested
    if [[ "$FORCE_MODE" == true ]] || prompt_user "Install and configure Zsh?"; then
        if ! command_exists zsh; then
            print_info "Installing Zsh..."
            case "$DISTRO" in
                PACMAN) execute_command "$PRIVILEGE_TOOL pacman -S --noconfirm zsh zsh-completions" ;;
                APT) execute_command "$PRIVILEGE_TOOL apt install -y zsh zsh-autosuggestions zsh-syntax-highlighting" ;;
                DNF) execute_command "$PRIVILEGE_TOOL dnf install -y zsh zsh-autosuggestions zsh-syntax-highlighting" ;;
            esac
        fi

        if command_exists zsh || [[ "$DRY_RUN" == true ]]; then
            if [[ "$FORCE_MODE" == true ]] || prompt_user "Change default shell to Zsh?"; then
                local zsh_path
                zsh_path="$(which zsh 2>/dev/null || echo "/usr/bin/zsh")"
                if execute_command "chsh -s '$zsh_path'"; then
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
            mark_step_failed "setup_shell"
            return 1
        fi
    else
        print_skip "Zsh setup"
    fi

    mark_step_completed "setup_shell"
}

# Enhanced Zsh plugin installation
install_zsh_plugins() {
    local plugins_dir="$HOME/.config/zsh/plugins"
    local plugins=(
        "zsh-you-should-use:https://github.com/MichaelAquilina/zsh-you-should-use.git"
        "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting.git"
        "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions.git"
        "powerlevel10k:https://github.com/romkatv/powerlevel10k.git"
    )

    create_dir "$plugins_dir"

    local current=0
    for plugin_info in "${plugins[@]}"; do
        local plugin_name="${plugin_info%%:*}"
        local plugin_url="${plugin_info##*:}"
        local plugin_path="$plugins_dir/$plugin_name"

        current=$((current + 1))
        show_progress "$current" "${#plugins[@]}" "$plugin_name"

        if [[ -d "$plugin_path" ]]; then
            if [[ "$UPDATE_MODE" == true ]] || [[ "$FORCE_MODE" == true ]] || prompt_user "Update $plugin_name?" "Y" 10; then
                if execute_command "(cd '$plugin_path' && git pull)"; then
                    print_success "Updated $plugin_name"
                else
                    print_error "Failed to update $plugin_name"
                fi
            else
                print_skip "Update for $plugin_name"
            fi
        else
            print_info "Installing $plugin_name..."
            if execute_command "git clone --depth=1 '$plugin_url' '$plugin_path'"; then
                print_success "Installed $plugin_name"
            else
                print_error "Failed to install $plugin_name"
            fi
        fi
    done
    echo # Clear progress line
}

# Setup SSH
setup_ssh() {
    print_section "Setting Up SSH"
    save_state "setup_ssh" "started"

    local ssh_dir="$HOME/.ssh"

    if [[ ! -f "$ssh_dir/id_rsa" && ! -f "$ssh_dir/id_ed25519" ]]; then
        if [[ "$FORCE_MODE" == true ]] || prompt_user "Generate SSH key pair?"; then
            create_dir "$ssh_dir" 700

            local email
            if [[ "$FORCE_MODE" != true ]]; then
                print_color "$YELLOW" "Enter email for SSH key (or press Enter for $USER@$HOSTNAME): "
                read -r email
            fi
            email="${email:-$USER@$HOSTNAME}"

            # Use Ed25519 for better security
            local key_type="ed25519"
            local key_file="$ssh_dir/id_ed25519"

            if execute_command "ssh-keygen -t '$key_type' -f '$key_file' -N '' -C '$email'"; then
                print_success "SSH key pair generated (Ed25519)"
                execute_command "cat '$key_file.pub' >> '$ssh_dir/authorized_keys'"
                execute_command "chmod 600 '$ssh_dir/authorized_keys'"
                print_info "Public key added to authorized_keys"

                # Display public key
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

# Configure system services
configure_services() {
    print_section "Configuring System Services"
    save_state "configure_services" "started"

    if [[ "$CFG_OS" != "linux" ]]; then
        print_skip "Service configuration (not supported on $CFG_OS)"
        mark_step_completed "configure_services"
        return 0
    fi

    # Enable TLP for laptop power management
    if command_exists tlp; then
        print_info "TLP is installed"
        if [[ "$FORCE_MODE" == true ]] || prompt_user "Enable TLP power management service?"; then
            if execute_command "$PRIVILEGE_TOOL systemctl enable tlp"; then
                execute_command "$PRIVILEGE_TOOL systemctl start tlp"
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
            execute_command "$PRIVILEGE_TOOL systemctl enable tlp"
            execute_command "$PRIVILEGE_TOOL systemctl start tlp"
            print_success "TLP installed, enabled and started"
        fi
    fi

    # Configure other useful services
    local services_to_enable=()

    # Check for and configure common services
    if command_exists docker && ! systemctl is-enabled docker &>/dev/null; then
        if [[ "$FORCE_MODE" == true ]] || prompt_user "Enable Docker service?"; then
            services_to_enable+=("docker")
        fi
    fi

    if command_exists bluetooth && ! systemctl is-enabled bluetooth &>/dev/null; then
        if [[ "$FORCE_MODE" == true ]] || prompt_user "Enable Bluetooth service?"; then
            services_to_enable+=("bluetooth")
        fi
    fi

    # Enable selected services
    for service in "${services_to_enable[@]}"; do
        if execute_command "$PRIVILEGE_TOOL systemctl enable '$service'"; then
            execute_command "$PRIVILEGE_TOOL systemctl start '$service'"
            print_success "Enabled and started $service"
        else
            print_error "Failed to enable $service"
        fi
    done

    mark_step_completed "configure_services"
}

# Setup development environment
setup_development() {
    print_section "Setting Up Development Environment"
    save_state "setup_development" "started"

    # Install development tools
    local dev_tools=()

    case "$DISTRO" in
        PACMAN) dev_tools=("base-devel" "git" "vim" "neovim" "code") ;;
        APT) dev_tools=("build-essential" "git" "vim" "neovim" "curl" "wget") ;;
        DNF) dev_tools=("@development-tools" "git" "vim" "neovim" "curl" "wget") ;;
    esac

    if [[ ${#dev_tools[@]} -gt 0 ]]; then
        if [[ "$FORCE_MODE" == true ]] || prompt_user "Install development tools?"; then
            local failed_dev_tools=()
            for tool in "${dev_tools[@]}"; do
                case "$DISTRO" in
                    PACMAN)
                        if ! execute_command "$PRIVILEGE_TOOL pacman -S --noconfirm '$tool'"; then
                            failed_dev_tools+=("$tool")
                        fi
                        ;;
                    APT)
                        if ! execute_command "$PRIVILEGE_TOOL apt install -y '$tool'"; then
                            failed_dev_tools+=("$tool")
                        fi
                        ;;
                    DNF)
                        if ! execute_command "$PRIVILEGE_TOOL dnf install -y '$tool'"; then
                            failed_dev_tools+=("$tool")
                        fi
                        ;;
                esac
            done

            if [[ ${#failed_dev_tools[@]} -eq 0 ]]; then
                print_success "Development tools installed"
            else
                print_warning "Some development tools failed to install: ${failed_dev_tools[*]}"
            fi
        fi
    fi

    # Setup Git configuration
    if command_exists git; then
        if [[ "$FORCE_MODE" == true ]] || prompt_user "Configure Git global settings?"; then
            local git_name git_email

            if [[ "$FORCE_MODE" != true ]]; then
                print_color "$YELLOW" "Enter your Git username: "
                read -r git_name
                print_color "$YELLOW" "Enter your Git email: "
                read -r git_email
            else
                git_name="${USER}"
                git_email="${USER}@$(hostname)"
            fi

            if [[ -n "$git_name" && -n "$git_email" ]]; then
                execute_command "git config --global user.name '$git_name'"
                execute_command "git config --global user.email '$git_email'"
                execute_command "git config --global init.defaultBranch main"
                execute_command "git config --global pull.rebase false"
                print_success "Git configured with name: $git_name, email: $git_email"
            fi
        fi
    fi

    mark_step_completed "setup_development"
}

# Apply system tweaks
apply_tweaks() {
    print_section "Applying System Tweaks"
    save_state "apply_tweaks" "started"

    if [[ "$CFG_OS" != "linux" ]]; then
        print_skip "System tweaks (not supported on $CFG_OS)"
        mark_step_completed "apply_tweaks"
        return 0
    fi

    # Improve system responsiveness
    if [[ "$FORCE_MODE" == true ]] || prompt_user "Apply system performance tweaks?"; then
        local tweaks_applied=()

        # Swappiness adjustment
        if execute_command "echo 'vm.swappiness=10' | $PRIVILEGE_TOOL tee -a /etc/sysctl.conf"; then
            tweaks_applied+=("Reduced swappiness to 10")
        fi

        # File descriptor limits
        if execute_command "echo '$USER soft nofile 65536' | $PRIVILEGE_TOOL tee -a /etc/security/limits.conf"; then
            execute_command "echo '$USER hard nofile 65536' | $PRIVILEGE_TOOL tee -a /etc/security/limits.conf"
            tweaks_applied+=("Increased file descriptor limits")
        fi

        # Apply tweaks immediately where possible
        if [[ "$DRY_RUN" != true ]]; then
            execute_command "$PRIVILEGE_TOOL sysctl vm.swappiness=10" || true
        fi

        if [[ ${#tweaks_applied[@]} -gt 0 ]]; then
            print_success "Applied system tweaks:"
            for tweak in "${tweaks_applied[@]}"; do
                print_info "  - $tweak"
            done
            print_warning "Some tweaks require a reboot to take effect"
        fi
    fi

    mark_step_completed "apply_tweaks"
}

#======================================
# Enhanced Summary and Cleanup
#======================================

# Print installation summary
print_installation_summary() {
    print_header "Installation Summary"

    # Show progress overview
    local total_steps=${#STEP_ORDER[@]}
    local completed_count=${#COMPLETED_STEPS[@]}
    local failed_count=${#FAILED_ITEMS[@]}

    print_section "Progress Overview"
    print_color "$CYAN" "Total Steps: $total_steps"
    print_color "$GREEN" "Completed: $completed_count"
    print_color "$RED" "Failed: $failed_count"

    local completion_percent=$((completed_count * 100 / total_steps))
    print_color "$BLUE" "Completion: ${completion_percent}%"

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
        print_info "Run with --resume to continue from where you left off"
    else
        clear_state
    fi

    echo
    print_color "$GREEN$BOLD" "Installation completed!"
    print_info "Log file: $LOG_FILE" "always"

    if [[ ${#FAILED_ITEMS[@]} -eq 0 ]]; then
        print_color "$GREEN" "🎉 All operations completed successfully!"
    else
        print_color "$YELLOW" "⚠️  Installation completed with ${#FAILED_ITEMS[@]} issues"
    fi

    echo
    print_section "Next Steps"
    print_color "$CYAN" "• Restart your shell or run: exec \$SHELL"
    print_color "$CYAN" "• Review configuration files in: $DOTFILES_DIR"
    print_color "$CYAN" "• Use 'config status' to manage dotfiles"

    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        print_color "$YELLOW" "• Run '$0 --resume' to retry failed steps"
    fi

    if [[ -d "$BACKUP_DIR" ]] && [[ "$DRY_RUN" != true ]]; then
        print_color "$CYAN" "• Backup files saved to: $BACKUP_DIR"
    fi
    echo
}

#======================================
# Enhanced Main Installation Flow
#======================================

# Execute installation step with error handling
execute_step() {
    local step_name="$1"
    local step_desc="${INSTALLATION_STEPS[$step_name]}"

    print_section "$step_desc"
    save_state "$step_name" "started"

    # Skip if already completed and not in force mode
    if is_step_completed "$step_name" && [[ "$FORCE_MODE" != true ]]; then
        print_success "$step_desc (already completed)"
        return 0
    fi

    # Execute the step function
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

# Main installation function
main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Initialize
    setup_logging "$@"

    print_header "Enhanced Dotfiles Installation"

    if [[ "$DRY_RUN" == true ]]; then
        print_warning "DRY RUN MODE - No changes will be made"
        echo
    fi

    print_info "Starting installation for user: $USER" "always"
    print_info "Log file: $LOG_FILE" "always"
    print_info "Mode: $(
        [[ "$RESUME_MODE" == true ]] && echo "Resume" ||
        [[ "$UPDATE_MODE" == true ]] && echo "Update" ||
        echo "Fresh Install"
    )" "always"

    # Handle resume mode
    if [[ "$RESUME_MODE" == true ]]; then
        if load_state; then
            print_info "Resuming from previous installation..." "always"
            print_info "Last step: ${LAST_STEP:-unknown}" "always"
            print_info "Step status: ${STEP_STATUS:-unknown}" "always"

            # Load completed steps from state
            if [[ -n "${COMPLETED_STEPS:-}" ]]; then
                eval "COMPLETED_STEPS=(${COMPLETED_STEPS})"
            fi
        else
            print_warning "No previous installation state found"
            print_info "Starting fresh installation..."
            RESUME_MODE=false
        fi
    fi

    # Pre-flight checks
    detect_os
    detect_privilege_tools

    if [[ "$CFG_OS" == "linux" ]]; then
        detect_linux_distro || {
            print_error "Failed to detect Linux distribution"
            exit 1
        }
    fi

    # System requirements and validation
    if ! check_system_requirements; then
        if [[ "$FORCE_MODE" != true ]]; then
            print_error "System requirements not met"
            if ! prompt_user "Continue anyway? (Some features may not work)"; then
                exit 1
            fi
        fi
    fi

    validate_config || print_warning "Configuration validation found issues"

    # Show installation plan
    echo
    print_color "$YELLOW$BOLD" "Installation Plan:"
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
            log_message "INFO" "Step completed successfully: $step"
        else
            failed_steps+=("$step")
            log_message "ERROR" "Step failed: $step"

            # Ask if user wants to continue
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

    # Post-installation tasks
    if [[ ${#failed_steps[@]} -eq 0 ]]; then
        print_success "All installation steps completed successfully!"
        clear_state
    else
        print_warning "${#failed_steps[@]} steps failed: ${failed_steps[*]}"
        if [[ "${failed_steps[-1]:-}" != "" ]]; then
            save_state "${failed_steps[-1]}" "failed"
        fi
    fi

    # Show summary
    print_installation_summary

    log_message "INFO" "Installation process completed"

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

        if [[ -d "$BACKUP_DIR" ]]; then
            print_color "$CYAN" "• Your original files have been backed up to: $BACKUP_DIR"
        fi

        echo
        print_color "$GREEN$BOLD" "Thank you for using the Enhanced Dotfiles Installation Script!"
    fi

    # Exit with appropriate code
    [[ ${#failed_steps[@]} -eq 0 ]] && exit 0 || exit 1
}

main "$@"
