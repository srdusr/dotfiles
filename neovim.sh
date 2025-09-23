#!/bin/bash

# Created By: srdusr
# Created On: Sat 12 Aug 2023 13:11:39 CAT
# Project: Install/update/uninstall/change version Neovim script, primarily for Linux but may work in other platforms

# Dependencies: wget/curl, fuse, jq

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Handle errors
handle_error() {
    local message="$1"
    printf "${RED}Error: $message${NC}\n"
}

# Check if necessary dependencies are installed
check_dependencies() {
    if [ -x "$(command -v wget)" ]; then
        DOWNLOAD_COMMAND="wget"
    elif [ -x "$(command -v curl)" ]; then
        DOWNLOAD_COMMAND="curl"
    else
        printf "${RED}Error: Neither wget nor curl found. Please install one of them to continue!${NC}\n"
        exit 1
    fi
    if ! command -v jq >/dev/null 2>&1; then
        printf "${RED}Error: jq is required for specific version downloads. Please install jq!${NC}\n"
        exit 1
    fi
}

# Check for privilege escalation tools
check_privilege_tools() {
    if [ -x "$(command -v sudo)" ]; then
        PRIVILEGE_TOOL="sudo"
    elif [ -x "$(command -v doas)" ]; then
        PRIVILEGE_TOOL="doas"
    elif [ -x "$(command -v pkexec)" ]; then
        PRIVILEGE_TOOL="pkexec"
    elif [ -x "$(command -v dzdo)" ]; then
        PRIVILEGE_TOOL="dzdo"
    elif [ "$(id -u)" -eq 0 ]; then
        PRIVILEGE_TOOL="" # root
    else
        PRIVILEGE_TOOL="" # No privilege escalation mechanism found
        printf "\n${RED}Error: No privilege escalation tool (sudo, doas, pkexec, dzdo, or root privileges) found. You may not have sufficient permissions to run this script.${NC}\n"
        printf "\nAttempt to continue Installation (might fail without a privilege escalation tool)? [yes/no] "
        read continue_choice
        case $continue_choice in
        [Yy] | [Yy][Ee][Ss]) ;;
        [Nn] | [Nn][Oo]) exit ;;
        *) handle_error "Invalid choice. Exiting..." && exit ;;
        esac
    fi
}

# Check if Neovim is already installed
check_neovim_installed() {
    if [ -x "$(command -v nvim)" ]; then
        return 0 # Neovim is installed
    else
        return 1 # Neovim is not installed
    fi
}

# Nightly version
nightly_version() {
    local url="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage"
    install_neovim "$url"
    local version_output=$(nvim --version)
    version_id="Nightly $(echo "$version_output" | grep -oP 'NVIM \d+\.\d+\.\d+')"
}

# Stable version
stable_version() {
    #local url="https://github.com/neovim/neovim/releases/download/stable/nvim.appimage"
    local url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
    install_neovim "$url"
    local version_output=$(nvim --version)
    version_id="Stable $(echo "$version_output" | grep -oP 'NVIM \d+\.\d+')"
}

# Specific version
specific_version() {
    local version="$1"
    filename=$(download_specific_version "$version")
    echo "Installing Neovim $version..."
    if [ -x "$(command -v fusermount)" ]; then
        chmod u+x "$filename"
        $PRIVILEGE_TOOL cp "$filename" /usr/local/bin/nvim
        $PRIVILEGE_TOOL chmod +x /usr/local/bin/nvim
        echo "Installed Neovim to /usr/local/bin/nvim"
    else
        chmod u+x "$filename"
        ./$filename --appimage-extract
        $PRIVILEGE_TOOL cp squashfs-root/usr/bin/nvim /usr/local/bin
        $PRIVILEGE_TOOL chmod +x /usr/local/bin/nvim
        echo "Installed Neovim to /usr/local/bin/nvim"
    fi
}

# Download a file using wget or curl
download_file() {
    local url="$1"
    local output="$2"

    if [ "$DOWNLOAD_COMMAND" = "wget" ]; then
        if ! "$DOWNLOAD_COMMAND" -q --show-progress -O "$output" "$url"; then
            handle_error "Download failed. Exiting..."
            exit 1
        fi
    elif [ "$DOWNLOAD_COMMAND" = "curl" ]; then
        if ! "$DOWNLOAD_COMMAND" --progress-bar -# -o "$output" "$url"; then
            handle_error "Download failed. Exiting..."
            exit 1
        fi
    else
        echo "Unsupported download command: $DOWNLOAD_COMMAND"
        exit 1
    fi
}

# Download the correct asset for a specific version using GitHub API and jq
download_specific_version() {
    local version="$1"
    if [[ $version != v* ]]; then
        version="v$version"
    fi
    local api_url="https://api.github.com/repos/neovim/neovim/releases/tags/$version"
    local json=$(curl -sSL "$api_url")
    local os_name=$(uname -s)
    local arch=$(uname -m)
    local asset=""
    local asset_name=""
    local asset_candidates=()

    # Build candidate asset names based on platform/arch
    if [[ "$os_name" == "Linux" ]]; then
        if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
            asset_candidates=("nvim-linux-arm64.tar.gz" "nvim-linux64.tar.gz" "nvim.appimage")
        elif [[ "$arch" == "armv7l" ]]; then
            asset_candidates=("nvim-linux-arm.tar.gz" "nvim.appimage")
        else
            asset_candidates=("nvim-linux-x86_64.appimage" "nvim-linux64.appimage" "nvim.appimage" "nvim-linux64.tar.gz")
        fi
    elif [[ "$os_name" == "Darwin" ]]; then
        if [[ "$arch" == "arm64" ]]; then
            asset_candidates=("nvim-macos-arm64.tar.gz" "nvim-macos.tar.gz")
        else
            asset_candidates=("nvim-macos.tar.gz" "nvim-macos-x86_64.tar.gz")
        fi
    elif [[ "$os_name" =~ MINGW|MSYS|CYGWIN ]]; then
        asset_candidates=("nvim-win64.zip" "nvim-win64.msi")
    fi

    # Find the first matching asset
    for name in "${asset_candidates[@]}"; do
        asset=$(echo "$json" | jq -r ".assets[] | select(.name==\"$name\") | .browser_download_url")
        [[ -n "$asset" && "$asset" != "null" ]] && { asset_name="$name"; break; }
    done

    if [[ -z "$asset" || "$asset" == "null" ]]; then
        echo "No suitable asset found for your platform/arch in this release." >&2
        echo "Available assets:" >&2
        echo "$json" | jq -r '.assets[].name' >&2
        exit 1
    fi

    echo "DEBUG: Downloading asset: $asset_name from $asset" >&2
    download_file "$asset" "$asset_name"

    # Download checksum if available
    checksum_url=$(echo "$json" | jq -r ".assets[] | select(.name==\"$asset_name.sha256sum\" or .name==\"$asset_name.sha256\") | .browser_download_url")
    if [[ -n "$checksum_url" && "$checksum_url" != "null" ]]; then
        checksum_file="${asset_name}.sha256sum"
        echo "DEBUG: Downloading checksum: $checksum_file from $checksum_url" >&2
        download_file "$checksum_url" "$checksum_file"
        echo "DEBUG: Contents of $checksum_file:" >&2
        cat "$checksum_file" >&2
        echo "Verifying checksum..." >&2
        # Try to handle both formats: with and without filename
        if grep -q "$asset_name" "$checksum_file"; then
            if command -v sha256sum >/dev/null 2>&1; then
                sha256sum -c "$checksum_file" --ignore-missing >&2
            elif command -v shasum >/dev/null 2>&1; then
                shasum -a 256 -c "$checksum_file" >&2
            else
                echo "Warning: No sha256sum or shasum found, cannot verify checksum." >&2
            fi
        else
            # If the checksum file contains only the hash, not the filename
            hash=$(head -n1 "$checksum_file" | awk '{print $1}')
            if command -v sha256sum >/dev/null 2>&1; then
                echo "$hash  $asset_name" | sha256sum -c - >&2
            elif command -v shasum >/dev/null 2>&1; then
                echo "$hash  $asset_name" | shasum -a 256 -c - >&2
            else
                echo "Warning: No sha256sum or shasum found, cannot verify checksum." >&2
            fi
        fi
    else
        echo "Warning: No checksum file found for $asset_name." >&2
    fi

    echo "$asset_name"
}

# Check if a specific version of Neovim exists
version_exists() {
    local version="$1"

    # Add 'v' prefix if not present
    if [[ $version != v* ]]; then
        version="v$version"
    fi

    # Fetch all the release tags from GitHub
    ALL_TAGS=$(curl -s "https://api.github.com/repos/neovim/neovim/tags" | grep '"name":' | cut -d '"' -f 4)

    # Check if the desired version is in the list of release tags
    if echo "$ALL_TAGS" | grep -q "$version"; then
        return 0 # Version exists
    else
        return 1 # Version does not exist
    fi
}

# Update Neovim to the latest version (nightly/stable)
update_version() {
    valid_choice=false
    while [ "$valid_choice" = false ]; do
        # Determine which version to update to (nightly/stable)
        printf "Select version to install/update to:\n"
        printf "  1. Nightly\n"
        printf "  2. Stable\n"
        printf "  3. Choose specific version by tag\n"
        printf "Enter the number corresponding to your choice (1/2/3): "
        read update_choice

        case $update_choice in
        1)
            version="Nightly"
            nightly_version
            valid_choice=true
            ;;
        2)
            version="Stable"
            stable_version
            valid_choice=true
            ;;
        3)
            # Ask user for specific version
            read -p "Enter the specific version (e.g., v0.1.0): " version
            filename=$(download_specific_version "$version")
            echo "Installing Neovim $version..."
            if [ -x "$(command -v fusermount)" ]; then
                chmod u+x "$filename"
                $PRIVILEGE_TOOL cp "$filename" /usr/local/bin/nvim
                $PRIVILEGE_TOOL chmod +x /usr/local/bin/nvim
                echo "Installed Neovim to /usr/local/bin/nvim"
            else
                chmod u+x "$filename"
                ./$filename --appimage-extract
                $PRIVILEGE_TOOL cp squashfs-root/usr/bin/nvim /usr/local/bin
                $PRIVILEGE_TOOL chmod +x /usr/local/bin/nvim
                echo "Installed Neovim to /usr/local/bin/nvim"
            fi
            valid_choice=true
            ;;
        *)
            handle_error "Invalid choice. Please enter a valid option (1, 2 or 3)."
            ;;
        esac
    done
}

# Install Neovim
install_neovim() {
    local url="$1"
    local install_action="$3"

    if [ "$install_action" = "installed" ]; then
        printf "Downloading and installing Neovim $version...\n"
    else
        printf "${GREEN}Updating Neovim to the latest version ($version)...${NC}\n"
    fi

    # Determine the platform-specific installation steps
    case "$(uname -s)" in
    Linux)
        printf "Detected Linux OS.\n"
        if [ -x "$(command -v fusermount)" ]; then
            printf "FUSE is available. Downloading and running the AppImage...\n"
            download_file "$url" "nvim.appimage"
            chmod u+x nvim.appimage
            "$PRIVILEGE_TOOL" cp nvim.appimage /usr/local/bin/nvim
            "$PRIVILEGE_TOOL" mv nvim.appimage /usr/bin/nvim
        else
            printf "FUSE is not available. Downloading and extracting the AppImage...\n"
            download_file "$url" "nvim.appimage"
            chmod u+x nvim.appimage
            ./nvim.appimage --appimage-extract
            "$PRIVILEGE_TOOL" cp squashfs-root/usr/bin/nvim /usr/local/bin
            "$PRIVILEGE_TOOL" mv squashfs-root/usr/bin/nvim /usr/bin
        fi
        ;;

    Darwin)
        printf "Detected macOS.\n"
        download_file "$url" "nvim-macos.tar.gz"
        xattr -c ./nvim-macos.tar.gz
        tar xzvf nvim-macos.tar.gz
        "$PRIVILEGE_TOOL" cp nvim-macos/bin/nvim /usr/local/bin
        "$PRIVILEGE_TOOL" mv nvim-macos/bin/nvim /usr/bin/nvim
        ;;

    MINGW*)
        printf "Detected Windows.\n"
        download_file "$url" "nvim.appimage"
        chmod +x nvim.appimage
        if [ "$PRIVILEGE_TOOL" = "sudo" ]; then
            "$PRIVILEGE_TOOL" cp nvim.appimage /usr/local/bin/nvim
            "$PRIVILEGE_TOOL" mv /usr/local/bin/nvim /usr/bin
        elif [ "$PRIVILEGE_TOOL" = "" ]; then
            cp nvim.appimage /usr/local/bin/nvim
            mv /usr/local/bin/nvim /usr/bin
        else
            printf "No privilege escalation tool found. Cannot install Neovim on Windows.\n"
        fi
        ;;

    *)
        printf "Unsupported operating system.\n"
        exit 1
        ;;
    esac
    # Check if the installation was successful
    if [ $? -eq 0 ]; then
        if [ "$install_action" = "installed" ]; then
            printf "${GREEN}Neovim $version has been installed successfully!${NC}\n"
        else
            printf "${GREEN}Neovim has been updated successfully to $version!${NC}\n"
        fi
    else
        printf "${RED}Error: Neovim installation/update failed.${NC}\n"
        exit 1
    fi
}

# Uninstall Neovim
uninstall_neovim() {
    printf "${RED}Uninstalling Neovim...${NC}\n"

    # Detect the operating system to determine the appropriate uninstallation method
    case "$(uname -s)" in
    Linux)
        printf "Detected Linux OS.\n"
        "$PRIVILEGE_TOOL" rm /usr/local/bin/nvim
        "$PRIVILEGE_TOOL" rm /usr/bin/nvim
        ;;

    Darwin)
        printf "Detected macOS.\n"
        "$PRIVILEGE_TOOL" rm /usr/local/bin/nvim
        "$PRIVILEGE_TOOL" rm /usr/bin/nvim
        ;;

    MINGW*)
        printf "Detected Windows.\n"
        if [ "$PRIVILEGE_TOOL" = "sudo" ]; then
            "$PRIVILEGE_TOOL" rm /usr/local/bin/nvim
            "$PRIVILEGE_TOOL" rm /usr/bin/nvim
        else
            [ "$PRIVILEGE_TOOL" = "" ]
            rm /usr/local/bin/nvim
            rm /usr/bin/nvim
        fi
        ;;
    *)
        printf "Unsupported operating system.\n"
        ;;
    esac

    printf "${GREEN}Neovim has been uninstalled successfully!${NC}\n"
}

# Check if Neovim is running
check_neovim_running() {
    if pgrep nvim >/dev/null; then
        printf "${RED}Error: Neovim is currently running. Please close Neovim before proceeding.${NC}\n"
        read -p "Do you want to forcefully terminate Neovim and continue? [yes/no] " terminate_choice

        case $terminate_choice in
        [Yy] | [Yy][Ee][Ss])
            pkill nvim # Forcefully terminate Neovim
            ;;
        [Nn] | [Nn][Oo])
            echo "Exiting..."
            exit 1
            ;;
        *)
            handle_error "Invalid choice."
            ;;
        esac
    fi
}

check_neovim_running

# Define the variable to control the prompt
SHOW_PROMPT=1

# Check if necessary dependencies are installed
check_dependencies

# Check for privilege escalation tools
check_privilege_tools

# Check if Neovim is already installed and ask the user if want to install it
if check_neovim_installed; then
    printf "${GREEN}Neovim is already installed!${NC}\n"
else
    printf "${RED}Neovim is not installed.${NC}\n"
    read -p "Install Neovim? (y/n): " install_choice

    case $install_choice in
    [Yy])
        update_version
        ;;
    [Nn])
        echo "Exiting..."
        exit
        ;;
    *)
        handle_error "Invalid choice. Please enter 'y' for yes or 'n' for no."
        ;;
    esac
fi

# Check for updates and display breaking changes
check_version_updates() {
    local latest_version_url="https://api.github.com/repos/neovim/neovim/releases/latest"
    local latest_version=""

    if [ -x "$(command -v curl)" ]; then
        latest_version=$(curl -sSL "$latest_version_url" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    elif [ -x "$(command -v wget)" ]; then
        latest_version=$(wget -qO - "$latest_version_url" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    else
        printf "${RED}Error: Neither curl nor wget found. Please install one of them to continue!${NC}\n"
        exit 1
    fi

    if version_exists "$latest_version"; then
        printf "${GREEN}An update is available!${NC}\n"
        display_breaking_changes "$latest_version"
    else
        printf "You have the latest version of Neovim.\n"
    fi
}

# To display breaking changes for a specific version
display_breaking_changes() {
    local version="$1"
    local changelog_url="https://github.com/neovim/neovim/releases/tag/$version"
    local changelog=""

    if [ -x "$(command -v curl)" ]; then
        changelog=$(curl -sSL "$changelog_url" | grep -oE '<h1>Breaking Changes.*?</ul>' | sed 's/<[^>]*>//g')
    elif [ -x "$(command -v wget)" ]; then
        changelog=$(wget -qO - "$changelog_url" | grep -oE '<h1>Breaking Changes.*?</ul>' | sed 's/<[^>]*>//g')
    else
        printf "${RED}Error: Neither curl nor wget found. Please install one of them to continue!${NC}\n"
        exit 1
    fi

    printf "\nBreaking Changes in Neovim $version:\n"
    printf "$changelog\n"
}

# Main loop
while [ "$SHOW_PROMPT" -gt 0 ]; do
    printf "Select an option:\n"
    printf "  1. Install/update Neovim\n"
    printf "  2. Check for updates\n"
    printf "  3. Uninstall Neovim\n"
    printf "  4. Run Neovim\n"
    printf "  5. Quit\n"
    read -p "Enter a number or press 'q' to quit: " choice

    case $choice in
    1)
        update_version
        ;;
    2)
        check_version_updates
        ;;
    3)
        uninstall_neovim
        ;;
    4)
        nvim
        ;;
    5 | [Qq])
        echo "Exiting..."
        exit
        ;;
    *)
        handle_error "Invalid choice. Please choose a valid option by entering the corresponding number or press 'q' to 'quit'."
        ;;
    esac
done
