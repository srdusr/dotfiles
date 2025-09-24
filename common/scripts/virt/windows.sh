#!/usr/bin/env bash

# Windows VM Creation Script
# Description: Creates and manages Windows virtual machines using QEMU/KVM
# Features:
#   - Supports Windows 10, 11, and Server
#   - Automatic dependency checking
#   - Multiple VM instance support
#   - Cache management
#   - Unattended installation
#   - SMB sharing support
#   - Network control

# Usage: ./windows.sh [VERSION] [OPTIONS]
# Versions:
#   10              Windows 10
#   11              Windows 11 (default)
#   server          Windows Server 2022
#   server2019      Windows Server 2019
#   server2016      Windows Server 2016

# Options:
#   --help              Show this help message
#   --clean             Clean dependency cache
#   --check-deps       Only check dependencies and exit
#   --download-iso     Download Windows ISO and exit
#   --name NAME        Set custom VM name
#   --ram SIZE         Set RAM size (default: 8G)
#   --cpu NUM          Set number of CPUs (default: 6)
#   --disk SIZE        Set disk size (default: 80G)
#   --enable-smb       Enable SMB sharing (default: disabled)
#   --disable-net      Disable network connectivity (default: enabled)

# Parse command line arguments
WINDOWS_VERSION="11"
CLEAN_CACHE=false
CHECK_DEPS_ONLY=false
DOWNLOAD_ISO_ONLY=false
VM_NAME="windows-11"
VM_RAM="8G"
VM_CPU="6"
VM_SIZE="80G"
ENABLE_SMB=false
DISABLE_NET=false

# Handle version argument if it's the first argument
if [[ $# -gt 0 && ! $1 =~ ^-- ]]; then
    case "$1" in
    "10")
        WINDOWS_VERSION="10"
        VM_NAME="windows-10"
        ;;
    "server" | "server2022")
        WINDOWS_VERSION="server2022"
        VM_NAME="windows-server-2022"
        ;;
    "server2019")
        WINDOWS_VERSION="server2019"
        VM_NAME="windows-server-2019"
        ;;
    "server2016")
        WINDOWS_VERSION="server2016"
        VM_NAME="windows-server-2016"
        ;;
    *)
        echo "Unknown Windows version: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
    shift
fi

while [[ $# -gt 0 ]]; do
    case $1 in
    --help)
        echo "Windows VM Creation Script"
        echo "Usage: $0 [VERSION] [OPTIONS]"
        echo
        echo "Versions:"
        echo "  10              Windows 10"
        echo "  11              Windows 11 (default)"
        echo "  server          Windows Server 2022"
        echo "  server2019      Windows Server 2019"
        echo "  server2016      Windows Server 2016"
        echo
        echo "Options:"
        echo "  --help              Show this help message"
        echo "  --clean             Clean dependency cache"
        echo "  --check-deps       Only check dependencies and exit"
        echo "  --download-iso     Download Windows ISO and exit"
        echo "  --name NAME        Set custom VM name"
        echo "  --ram SIZE         Set RAM size (default: 8G)"
        echo "  --cpu NUM          Set number of CPUs (default: 6)"
        echo "  --disk SIZE        Set disk size (default: 80G)"
        echo "  --enable-smb       Enable SMB sharing (default: disabled)"
        echo "  --disable-net      Disable network connectivity (default: enabled)"
        exit 0
        ;;
    --clean)
        CLEAN_CACHE=true
        shift
        ;;
    --check-deps)
        CHECK_DEPS_ONLY=true
        shift
        ;;
    --download-iso)
        DOWNLOAD_ISO_ONLY=true
        shift
        ;;
    --name)
        VM_NAME="$2"
        shift 2
        ;;
    --ram)
        VM_RAM="$2"
        shift 2
        ;;
    --cpu)
        VM_CPU="$2"
        shift 2
        ;;
    --disk)
        VM_SIZE="$2"
        shift 2
        ;;
    --enable-smb)
        ENABLE_SMB=true
        shift
        ;;
    --disable-net)
        DISABLE_NET=true
        shift
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
done

# Set variables
HOST_DIR="$HOME/virt-new-new"
VM_DIR="$HOST_DIR/machines"
IMAGE_DIR="$HOST_DIR/images"
WIN_ISO_DIR="${IMAGE_DIR}/${VM_NAME}" # Directory for Windows ISO
SOCKET_DIR="$VM_DIR"
SHARED_DIR="${HOST_DIR}/shared"
FIRMWARE_DIR="${HOST_DIR}/firmware"
TPM_DIR="$WIN_ISO_DIR"
TPM_SOCKET="${WIN_ISO_DIR}/${VM_NAME}.swtpm-sock"
GUEST_PORT=22
QCOW2_FILE="${VM_DIR}/${VM_NAME}.qcow2"

# Try to find an available host port starting from 22220
HOST_PORT_START=22220
HOST_PORT_END=22300

for ((port = HOST_PORT_START; port <= HOST_PORT_END; port++)); do
    if ! ss -tuln | grep -q ":$port\b"; then
        HOST_PORT=$port
        echo "Using available port: $HOST_PORT"
        break
    fi
done

if [[ $port -gt $HOST_PORT_END ]]; then
    echo "Error: No available ports found between $HOST_PORT_START and $HOST_PORT_END" >&2
    exit 1
fi

# Set SMP configuration
CORES=$((VM_CPU / 2))
THREADS_PER_CORE=2
SOCKETS=1
SMP_CONFIG="cores=$CORES,threads=$THREADS_PER_CORE,sockets=$SOCKETS"

# Create necessary directories
mkdir -p "${HOME}/${HOST_DIR}"
mkdir -p "$IMAGE_DIR" "$SHARED_DIR" "$FIRMWARE_DIR"
mkdir -p "$WIN_ISO_DIR" "$VM_DIR"
mkdir -p "${WIN_ISO_DIR}/unattended"

# Define ISO paths and URLs
ISO_VIRTIO="${WIN_ISO_DIR}/virtio-win.iso"
ISO_UNATTENDED="${WIN_ISO_DIR}/unattended.iso"

# Find Windows ISO with flexible pattern matching
find_windows_iso() {
    # Check if directory exists
    if [[ ! -d "$WIN_ISO_DIR" ]]; then
        mkdir -p "$WIN_ISO_DIR"
    fi

    # Try to find any Windows ISO using case-insensitive patterns
    local found_iso
    found_iso=$(find "$WIN_ISO_DIR" -maxdepth 1 -type f \( \
        -iname "*win11*.iso" -o \
        -iname "*win*11*.iso" -o \
        -iname "Win*.iso" -o \
        -iname "Win11*.iso" -o \
        -iname "Win*11*.iso" -o \
        -iname "*windows*11*.iso" -o \
        -iname "*windows11*.iso" \
        \) -exec stat --format="%Y %n" {} \; | sort -n | tail -n 1 | cut -d' ' -f2-)

    if [[ -n "$found_iso" && -f "$found_iso" ]]; then
        echo "$found_iso"
        return 0
    fi

    return 1
}

# Define download URLs
VIRTIO_ISO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
SPICE_WEBDAVD_URL="https://www.spice-space.org/download/windows/spice-webdavd/spice-webdavd-x64-latest.msi"
SPICE_VDAGENT_URL="https://www.spice-space.org/download/windows/spice-vdagent/spice-vdagent-x64-latest.msi"
SPICE_VDAGENT_FALLBACK_URL="https://www.spice-space.org/download/windows/spice-vdagent/spice-vdagent-x64-0.10.0.msi"
USBDK_URL="https://www.spice-space.org/download/windows/usbdk/UsbDk_1.0.22_x64.msi"

# Fido download URL (Windows ISO downloader)
#FIDO_URL="https://github.com/pbatard/Fido/raw/master/Fido.ps1"
#FIDO_PATH="$WIN_DIR/Fido.ps1"

# Print colored messages
print_info() { echo -e "\033[1;34m[INFO]\033[0m $1" >&2; }
print_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1" >&2; }
print_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1" >&2; }
print_error() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; }

# Helper: verify file integrity
verify_file() {
    local file="$1"
    local expected_sha256="$2"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    if [[ -n "$expected_sha256" ]]; then
        local actual_sha256
        actual_sha256=$(sha256sum "$file" | cut -d' ' -f1)
        if [[ "$actual_sha256" != "$expected_sha256" ]]; then
            print_error "File integrity check failed for $file"
            return 1
        fi
    fi

    return 0
}

# Helper: download file with verification
download_file() {
    local url="$1"
    local dest="$2"
    local expected_sha256="$3"
    local allow_failure="$4"

    # Check if file exists and is valid
    if [[ -f "$dest" ]]; then
        if verify_file "$dest" "$expected_sha256"; then
            print_info "File $dest already exists and verified."
            return 0
        else
            print_warning "File $dest exists but failed verification. Redownloading..."
            rm -f "$dest"
        fi
    fi

    print_info "Downloading $url..."
    if ! curl -fL --progress-bar -o "$dest" "$url"; then
        print_error "Failed to download $url."
        if [[ "$allow_failure" != "true" ]]; then
            return 1
        fi
    else
        # Verify downloaded file
        if ! verify_file "$dest" "$expected_sha256"; then
            print_error "Downloaded file failed verification"
            rm -f "$dest"
            return 1
        fi
        print_success "Successfully downloaded and verified $dest"
    fi

    return 0
}

# Download Windows 11 ISO using Microsoft's API
download_windows_iso() {
    local windows_version="11"               # Default to Windows 11
    local language="English (United States)" # Default language

    # Parse arguments if provided
    if [[ -n "$1" ]]; then
        windows_version="$1"
    fi

    print_info "Attempting to download Windows $windows_version ISO from Microsoft..."

    # Set required variables
    local user_agent="Mozilla/5.0 (X11; Linux x86_64; rv:100.0) Gecko/20100101 Firefox/100.0"
    local session_id="$(uuidgen)"
    local profile="606624d44113"
    local url="https://www.microsoft.com/en-us/software-download/windows$windows_version"

    # Add ISO to URL for Windows 10
    case "$windows_version" in
    10) url="${url}ISO" ;;
    esac

    # Step 1: Get download page HTML
    print_info "Fetching download page: $url"
    local iso_download_page_html
    iso_download_page_html="$(curl --disable --silent --user-agent "$user_agent" --header "Accept:" --max-filesize 1M --fail --proto =https --tlsv1.2 --http1.1 -- "$url")" || {
        handle_curl_error $?
        print_error "Failed to fetch the download page. Please download Windows $windows_version ISO manually from $url"
        return 1
    }

    # Step 2: Extract Product Edition ID
    print_info "Getting Product Edition ID..."
    local product_edition_id
    product_edition_id="$(echo "$iso_download_page_html" | grep -Eo '<option value="[0-9]+">Windows' | cut -d '"' -f 2 | head -n 1 | tr -cd '0-9' | head -c 16)"

    if [[ -z "$product_edition_id" ]]; then
        print_error "Failed to extract product edition ID."
        print_error "Please download Windows $windows_version ISO manually from $url"
        return 1
    fi

    print_success "Product Edition ID: $product_edition_id"

    # Step 3: Register session ID
    print_info "Registering session ID: $session_id"
    curl --disable --silent --output /dev/null --user-agent "$user_agent" \
        --header "Accept:" --max-filesize 100K --fail --proto =https --tlsv1.2 \
        --http1.1 -- "https://vlscppe.microsoft.com/tags?org_id=y6jn8c31&session_id=$session_id" || {
        print_error "Failed to register session ID."
        return 1
    }

    # Step 4: Get language SKU ID
    print_info "Getting language SKU ID..."
    local language_skuid_table_json
    language_skuid_table_json="$(curl --disable -s --fail --max-filesize 100K --proto =https --tlsv1.2 --http1.1 \
        "https://www.microsoft.com/software-download-connector/api/getskuinformationbyproductedition?profile=${profile}&ProductEditionId=${product_edition_id}&SKU=undefined&friendlyFileName=undefined&Locale=en-US&sessionID=${session_id}")" || {
        handle_curl_error $?
        print_error "Failed to get language SKU information."
        return 1
    }

    # Extract SKU ID for selected language
    local sku_id

    # Try with jq if available (more reliable)
    if command -v jq >/dev/null 2>&1; then
        sku_id="$(echo "$language_skuid_table_json" | jq -r '.Skus[] | select(.LocalizedLanguage=="'"$language"'" or .Language=="'"$language"'").Id')"
    else
        # Fallback to grep/cut if jq not available
        sku_id="$(echo "$language_skuid_table_json" | grep -o '"Id":"[^"]*","Language":"'"$language"'"' | cut -d'"' -f4)"

        if [[ -z "$sku_id" ]]; then
            # Try alternative extraction method
            sku_id="$(echo "$language_skuid_table_json" | grep -o '"LocalizedLanguage":"'"$language"'","Id":"[^"]*"' | cut -d'"' -f6)"
        fi
    fi

    if [[ -z "$sku_id" ]]; then
        print_error "Failed to extract SKU ID for $language."
        return 1
    fi

    print_success "SKU ID: $sku_id"

    # Step 5: Get ISO download link
    print_info "Getting ISO download link..."
    local iso_download_link_json
    iso_download_link_json="$(curl --disable -s --fail --referer "$url" \
        "https://www.microsoft.com/software-download-connector/api/GetProductDownloadLinksBySku?profile=${profile}&productEditionId=undefined&SKU=${sku_id}&friendlyFileName=undefined&Locale=en-US&sessionID=${session_id}")"

    local failed=0

    if [[ -z "$iso_download_link_json" ]]; then
        print_error "Microsoft servers gave an empty response to the download request."
        failed=1
    fi

    if echo "$iso_download_link_json" | grep -q "Sentinel marked this request as rejected."; then
        print_error "Microsoft blocked the automated download request based on your IP address."
        failed=1
    fi

    if [[ "$failed" -eq 1 ]]; then
        print_warning "Please manually download the Windows $windows_version ISO using a web browser from: $url"
        print_warning "Save the downloaded ISO to: $WIN_ISO_DIR"
        return 1
    fi

    # Extract 64-bit ISO download URL
    local iso_download_link

    # Try with jq if available
    if command -v jq >/dev/null 2>&1; then
        iso_download_link="$(echo "$iso_download_link_json" | jq -r '.ProductDownloadOptions[].Uri' | grep x64 | head -n 1)"
    else
        # Fallback to grep/cut if jq not available
        iso_download_link="$(echo "$iso_download_link_json" | grep -o '"Uri":"[^"]*x64[^"]*"' | cut -d'"' -f4 | head -n 1)"
    fi

    if [[ -z "$iso_download_link" ]]; then
        print_error "Failed to extract the download link from Microsoft's response."
        print_warning "Manually download the Windows $windows_version ISO using a web browser from: $url"
        return 1
    fi

    print_success "Got download link: ${iso_download_link%%\?*}"

    # Extract filename from URL
    local file_name="$(echo "$iso_download_link" | cut -d'?' -f1 | rev | cut -d'/' -f1 | rev)"

    # If filename couldn't be extracted, use default
    if [[ -z "$file_name" || "$file_name" == "$iso_download_link" ]]; then
        file_name="windows-$windows_version.iso"
    fi

    # Step 6: Download the ISO
    print_info "Downloading Windows $windows_version ISO to $WIN_ISO_DIR/$file_name. This may take a while..."

    # Check which download function to use
    if type web_get >/dev/null 2>&1; then
        web_get "$iso_download_link" "$WIN_ISO_DIR" "$file_name"
    else
        # Fallback to direct curl download
        curl --disable --progress-bar --fail --location --proto '=https' --tlsv1.2 --http1.1 \
            --retry 3 --retry-delay 3 --connect-timeout 30 \
            --output "$WIN_ISO_DIR/$file_name" "$iso_download_link" || {
            handle_curl_error $?
            return 1
        }
    fi

    if [[ $? -ne 0 ]]; then
        print_error "Failed to download the Windows $windows_version ISO."
        return 1
    fi

    print_success "Successfully downloaded Windows $windows_version ISO to $WIN_ISO_DIR/$file_name"

    # Return the downloaded filename so calling code can use it
    echo "$file_name"
    return 0
}

# Create unattended installation ISO
create_unattended_iso() {
    print_info "Creating unattended installation ISO..."

    # Create basic autounattend.xml if it doesn't exist
    if [ ! -f "$WIN_ISO_DIR/unattended/autounattend.xml" ]; then
        print_info "Creating autounattend.xml..."
        cat >"$WIN_ISO_DIR/unattended/autounattend.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <SetupUILanguage>
                <UILanguage>en-US</UILanguage>
            </SetupUILanguage>
            <InputLocale>0409:00000409</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <ImageInstall>
                <OSImage>
                    <Compact>false</Compact>
                    <InstallTo>
                        <DiskID>0</DiskID>
                        <PartitionID>3</PartitionID>
                    </InstallTo>
                </OSImage>
            </ImageInstall>
            <UserData>
                <AcceptEula>true</AcceptEula>
            </UserData>
            <UseConfigurationSet>false</UseConfigurationSet>
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Path>cmd.exe /c "&gt;&gt;"X:\diskpart.txt" (echo SELECT DISK=0&amp;echo CLEAN&amp;echo CONVERT GPT&amp;echo CREATE PARTITION EFI SIZE=300&amp;echo FORMAT QUICK FS=FAT32 LABEL="System"&amp;echo CREATE PARTITION MSR SIZE=16)"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <Path>cmd.exe /c "&gt;&gt;"X:\diskpart.txt" (echo CREATE PARTITION PRIMARY&amp;echo SHRINK MINIMUM=1000&amp;echo FORMAT QUICK FS=NTFS LABEL="Windows"&amp;echo CREATE PARTITION PRIMARY&amp;echo FORMAT QUICK FS=NTFS LABEL="Recovery")"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>3</Order>
                    <Path>cmd.exe /c "&gt;&gt;"X:\diskpart.txt" (echo SET ID="de94bba4-06d1-4d40-a16a-bfd50179d6ac"&amp;echo GPT ATTRIBUTES=0x8000000000000001)"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>4</Order>
                    <Path>cmd.exe /c "diskpart.exe /s "X:\diskpart.txt" &gt;&gt;"X:\diskpart.log" || ( type "X:\diskpart.log" &amp; echo diskpart encountered an error. &amp; pause &amp; exit /b 1 )"</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <ComputerName>Win11-VM</ComputerName>
            <TimeZone>UTC</TimeZone>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <InputLocale>0409:00000409</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Name>Admin</Name>
                        <DisplayName></DisplayName>
                        <Group>Administrators</Group>
                        <Password>
                            <Value>password</Value>
                            <PlainText>true</PlainText>
                        </Password>
                    </LocalAccount>
                    <LocalAccount wcm:action="add">
                        <Name>User</Name>
                        <DisplayName></DisplayName>
                        <Group>Users</Group>
                        <Password>
                            <Value>password</Value>
                            <PlainText>true</PlainText>
                        </Password>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
            <AutoLogon>
                <Username>Admin</Username>
                <Enabled>true</Enabled>
                <LogonCount>1</LogonCount>
                <Password>
                    <Value>password</Value>
                    <PlainText>true</PlainText>
                </Password>
            </AutoLogon>
            <OOBE>
                <ProtectYourPC>3</ProtectYourPC>
                <HideEULAPage>true</HideEULAPage>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <SkipMachineOOBE>true</SkipMachineOOBE>
                <SkipUserOOBE>true</SkipUserOOBE>
            </OOBE>
        </component>
    </settings>
</unattend>
EOF
    fi

    # Create the unattended ISO
    local iso_tool=""

    if command -v genisoimage >/dev/null 2>&1; then
        iso_tool="genisoimage"
    elif command -v mkisofs >/dev/null 2>&1; then
        iso_tool="mkisofs"
    elif command -v xorriso >/dev/null 2>&1; then
        iso_tool="xorriso"
    fi

    if [ "$iso_tool" != "" ]; then
        print_info "Creating unattended ISO using $iso_tool..."

        if [ "$iso_tool" = "xorriso" ]; then
            xorriso -as genisoimage -J -r -o "$WIN_ISO_DIR/unattended.iso" "$WIN_ISO_DIR/unattended"
        else
            "$iso_tool" -J -r -o "$WIN_ISO_DIR/unattended.iso" "$WIN_ISO_DIR/unattended"
        fi

        return $?
    else
        print_warning "No ISO creation tool found (genisoimage, mkisofs, or xorriso)"
        print_warning "Creating empty ISO file as fallback"
        touch "$WIN_ISO_DIR/unattended.iso"
        return 1
    fi
}

# Download or locate essential files
prepare_files() {
    # Find Windows ISO
    WINDOWS_ISO_PATH=$(find_windows_iso | tail -n 1 | xargs)
    local iso_found=false

    # Check if we found a valid ISO
    if [[ -n "$WINDOWS_ISO_PATH" && -f "$WINDOWS_ISO_PATH" ]]; then
        print_success "Using Windows ISO: $WINDOWS_ISO_PATH"
        iso_found=true
    else
        print_warning "Windows ISO not found, attempting to download..."
        if download_windows_iso; then
            # Check again after download attempt
            WINDOWS_ISO_PATH=$(find_windows_iso | tail -n 1 | xargs)
            if [[ -n "$WINDOWS_ISO_PATH" && -f "$WINDOWS_ISO_PATH" ]]; then
                print_success "Using downloaded Windows ISO: $WINDOWS_ISO_PATH"
                iso_found=true
            fi
        fi
    fi

    # If we still don't have an ISO, exit
    if [[ "$iso_found" != "true" ]]; then
        print_error "Could not find or download Windows ISO"
        print_info "Please place your Windows ISO file in: $WIN_ISO_DIR"
        exit 1
    fi

    # Download VirtIO drivers if missing
    if [[ ! -f "$ISO_VIRTIO" ]]; then
        print_info "VirtIO drivers ISO not found, downloading..."
        download_file "$VIRTIO_ISO_URL" "$ISO_VIRTIO"
    else
        print_success "VirtIO drivers ISO already exists: $ISO_VIRTIO"
    fi

    # Define the directory containing the MSI files
    UNATTENDED_DIR="$WIN_ISO_DIR/unattended"
    mkdir -p "$UNATTENDED_DIR"

    # Find the latest Spice WebDAVD MSI
    SPICE_WEBDAVD_MSI=$(find "$UNATTENDED_DIR" -type f -iname "spice-webdavd-x64*.msi" -exec stat --format="%Y %n" {} \; | sort -n | tail -n 1 | cut -d' ' -f2-)

    # Find the latest Spice VD Agent MSI
    SPICE_VDAGENT_MSI=$(find "$UNATTENDED_DIR" -type f -iname "spice-vdagent-x64*.msi" -exec stat --format="%Y %n" {} \; | sort -n | tail -n 1 | cut -d' ' -f2-)

    # Find the latest UsbDk MSI
    USBDK_MSI=$(find "$UNATTENDED_DIR" -type f -iname "UsbDk_*_x64.msi" -exec stat --format="%Y %n" {} \; | sort -n | tail -n 1 | cut -d' ' -f2-)

    # Spice Guest Tools + UsbDk (only if missing)
    if [[ ! -f "$SPICE_WEBDAVD_MSI" ]]; then
        print_info "Downloading Spice WebDAVD..."
        curl -L -o "$UNATTENDED_DIR/spice-webdavd-x64-latest.msi" "$SPICE_WEBDAVD_URL" || {
            print_error "Failed to download Spice WebDAVD"
            return 1
        }
    else
        print_success "Spice WebDAVD MSI already exists: $SPICE_WEBDAVD_MSI"
    fi

    if [[ ! -f "$SPICE_VDAGENT_MSI" ]]; then
        print_info "Downloading Spice VD Agent..."
        # Try multiple mirrors for spice-vdagent
        local spice_mirrors=(
            "https://www.spice-space.org/download/windows/spice-vdagent/spice-vdagent-x64-latest.msi"
            "https://www.spice-space.org/download/windows/spice-vdagent/spice-vdagent-x64-0.10.0.msi"
            "https://www.spice-space.org/download/windows/spice-vdagent/spice-vdagent-x64-0.9.0.msi"
            "https://www.spice-space.org/download/windows/spice-vdagent/spice-vdagent-x64-0.8.0.msi"
            "https://www.spice-space.org/download/windows/spice-vdagent/spice-vdagent-x64-0.7.0.msi"
        )

        local download_success=false
        for mirror in "${spice_mirrors[@]}"; do
            print_info "Trying mirror: $mirror"
            if curl -L -o "$UNATTENDED_DIR/spice-vdagent-x64-latest.msi" "$mirror"; then
                # Verify the downloaded file
                if [[ -s "$UNATTENDED_DIR/spice-vdagent-x64-latest.msi" ]]; then
                    download_success=true
                    break
                else
                    print_warning "Downloaded file is empty, trying next mirror..."
                    rm -f "$UNATTENDED_DIR/spice-vdagent-x64-latest.msi"
                fi
            fi
        done

        if [[ "$download_success" == "false" ]]; then
            print_error "Failed to download Spice VD Agent from all mirrors"
            return 1
        fi
    else
        print_success "Spice VD Agent MSI already exists: $SPICE_VDAGENT_MSI"
    fi

    if [[ ! -f "$USBDK_MSI" ]]; then
        print_info "Downloading UsbDk..."
        curl -L -o "$UNATTENDED_DIR/UsbDk_1.0.22_x64.msi" "$USBDK_URL" || {
            print_error "Failed to download UsbDk"
            return 1
        }
    else
        print_success "UsbDk MSI already exists: $USBDK_MSI"
    fi

    # Create unattended ISO if it doesn't exist
    if [[ ! -f "$ISO_UNATTENDED" ]]; then
        create_unattended_iso
    else
        print_success "Unattended ISO already exists: $ISO_UNATTENDED"
    fi
}

# Locate OVMF firmware files
locate_ovmf() {
    OVMF_DIRS=(
        "/usr/share/OVMF"
        "/usr/share/qemu"
        "/usr/lib/qemu"
        "/usr/share/edk2"
        "/usr/lib/edk2"
        "/usr/share/edk2/ovmf"
        "/usr/share/edk2-ovmf"
    )

    OVMF_CODE=""
    OVMF_VARS=""

    for dir in "${OVMF_DIRS[@]}"; do
        [[ -z "$OVMF_CODE" ]] && OVMF_CODE=$(find "$dir" -type f -name "OVMF_CODE.fd" -o -name "edk2-x86_64-code.fd" 2>/dev/null | head -n 1)
        [[ -z "$OVMF_VARS" ]] && OVMF_VARS=$(find "$dir" -type f -name "OVMF_VARS.fd" 2>/dev/null | head -n 1)
        [[ -n "$OVMF_CODE" && -n "$OVMF_VARS" ]] && break
    done

    # Ensure a writable copy of OVMF_VARS.fd
    local original_ovmf_vars="$OVMF_VARS"
    OVMF_VARS="$FIRMWARE_DIR/OVMF_VARS.fd"

    if [[ ! -f "$OVMF_VARS" && -f "$original_ovmf_vars" ]]; then
        print_info "Copying OVMF_VARS.fd to $OVMF_VARS"
        cp "$original_ovmf_vars" "$OVMF_VARS" 2>/dev/null || {
            print_error "Failed to copy OVMF_VARS.fd!"
            exit 1
        }
    fi

    # Check if required files exist
    if [[ -z "$OVMF_CODE" || ! -f "$OVMF_CODE" ]]; then
        print_error "OVMF_CODE.fd not found!"
        exit 1
    fi
    if [[ ! -f "$OVMF_VARS" ]]; then
        print_error "OVMF_VARS.fd not found or could not be copied!"
        exit 1
    fi
    #}
}

# Create VM disk image
create_disk() {
    # Check if the qcow2 image file exists; if not, create it
    if [[ ! -f "$QCOW2_FILE" ]]; then
        print_info "Creating $QCOW2_FILE with a size of $VM_SIZE"
        qemu-img create -f qcow2 "$QCOW2_FILE" "$VM_SIZE" || {
            print_error "Failed to create qcow2 image!"
            exit 1
        }
    else
        print_success "VM disk image already exists: $QCOW2_FILE"
    fi
}

# Generate unique PID file for this instance
generate_pid_file() {
    local base_pid_file="$VM_DIR/$VM_NAME.pid"
    local pid_file="$base_pid_file"
    local counter=1

    # If the base PID file exists, try to find an available number
    while [[ -f "$pid_file" ]]; do
        pid_file="${base_pid_file%.pid}-${counter}.pid"
        ((counter++))
    done

    echo "$pid_file"
}

# Start the VM
start_vm() {
    # Verify that we have a Windows ISO
    if [[ -z "$WINDOWS_ISO_PATH" || ! -f "$WINDOWS_ISO_PATH" ]]; then
        print_error "Windows ISO file not found. Cannot start VM."
        print_info "Please download Windows 11 ISO and save it to: $WIN_ISO_DIR"
        exit 1
    fi

    # Start swtpm
    print_info "Starting TPM emulator..."
    /sbin/swtpm socket \
        --ctrl type=unixio,path="$TPM_SOCKET" \
        --terminate \
        --tpmstate dir="$TPM_DIR" \
        --tpm2 &

    # Wait for swtpm socket
    sleep 1

    print_info "Starting Windows 11 VM..."
    print_info "Using Windows ISO: $WINDOWS_ISO_PATH"

    # Build network options
    local network_opts=()
    if [[ "$DISABLE_NET" == "true" ]]; then
        network_opts=(
            "-netdev" "none,id=nic"
            "-device" "virtio-net,netdev=nic"
        )
    else
        if [[ "$ENABLE_SMB" == "true" ]]; then
            network_opts=(
                "-netdev" "user,id=nic,hostname=$VM_NAME,hostfwd=tcp::$HOST_PORT-:$GUEST_PORT,smb=$SHARED_DIR"
                "-device" "virtio-net,netdev=nic"
            )
        else
            network_opts=(
                "-netdev" "user,id=nic,hostname=$VM_NAME,hostfwd=tcp::$HOST_PORT-:$GUEST_PORT"
                "-device" "virtio-net,netdev=nic"
            )
        fi
    fi

    # Run QEMU
    /sbin/qemu-system-x86_64 \
        -name "$VM_NAME",process="$VM_NAME" \
        -machine q35,hpet=off,smm=on,vmport=off,accel=kvm \
        -global kvm-pit.lost_tick_policy=discard \
        -global ICH9-LPC.disable_s3=1 \
        -cpu host,+hypervisor,+invtsc,l3-cache=on,migratable=no,hv_passthrough \
        -smp "$SMP_CONFIG" \
        -m "$VM_RAM" \
        -device virtio-balloon \
        -pidfile "$PID_FILE" \
        -rtc base=localtime,clock=host,driftfix=slew \
        -vga none \
        -device virtio-vga-gl,xres=1280,yres=800 \
        -display sdl,gl=on \
        -boot menu=on,splash-time=0,order=d,reboot-timeout=5000 \
        -device virtio-rng-pci,rng=rng0 \
        -object rng-random,id=rng0,filename=/dev/urandom \
        -device qemu-xhci,id=spicepass \
        -chardev spicevmc,id=usbredirchardev1,name=usbredir \
        -device usb-redir,chardev=usbredirchardev1,id=usbredirdev1 \
        -chardev spicevmc,id=usbredirchardev2,name=usbredir \
        -device usb-redir,chardev=usbredirchardev2,id=usbredirdev2 \
        -chardev spicevmc,id=usbredirchardev3,name=usbredir \
        -device usb-redir,chardev=usbredirchardev3,id=usbredirdev3 \
        -device pci-ohci,id=smartpass \
        -device usb-ccid \
        -chardev spicevmc,id=ccid,name=smartcard \
        -device ccid-card-passthru,chardev=ccid \
        -device usb-ehci,id=input \
        -device usb-kbd,bus=input.0 \
        -k en-us \
        -device usb-tablet,bus=input.0 \
        -audiodev pipewire,id=audio0 \
        -device intel-hda \
        -device hda-micro,audiodev=audio0 \
        "${network_opts[@]}" \
        -global driver=cfi.pflash01,property=secure,value=on \
        -drive if=pflash,format=raw,unit=0,file="$OVMF_CODE",readonly=on \
        -drive if=pflash,format=raw,unit=1,file="$OVMF_VARS" \
        -drive media=cdrom,index=1,file="$ISO_UNATTENDED" \
        -drive media=cdrom,index=0,file="$WINDOWS_ISO_PATH" \
        -drive media=cdrom,index=2,file="$ISO_VIRTIO" \
        -device virtio-blk-pci,drive=SystemDisk \
        -drive id=SystemDisk,if=none,format=qcow2,file="$QCOW2_FILE" \
        -chardev socket,id=chrtpm,path="$TPM_SOCKET" \
        -tpmdev emulator,id=tpm0,chardev=chrtpm \
        -device tpm-tis,tpmdev=tpm0 \
        -monitor unix:"$SOCKET_DIR/$VM_NAME-monitor.socket",server,nowait \
        -serial unix:"$SOCKET_DIR/$VM_NAME-serial.socket",server,nowait
}

# Check dependencies
check_dependencies() {
    # Cache file for dependency checks and VM configuration
    local cache_name="windows-vm-${VM_NAME}-${VM_RAM}-${VM_CPU}-${VM_SIZE}"
    local cache_file="${HOME}/.cache/${cache_name}.cache"
    local cache_dir=$(dirname "$cache_file")
    local cache_valid=false
    local missing_deps=()
    local pkg_manager=""
    local pkg_install_cmd=""
    local privilege_cmd=""

    # Clean cache if requested
    if [[ "$CLEAN_CACHE" == "true" ]]; then
        print_info "Cleaning dependency cache..."
        rm -f "$cache_file"
    fi

    # Create cache directory if it doesn't exist
    mkdir -p "$cache_dir"

    # Check if cache is valid (less than 24 hours old)
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt 86400 ]]; then # 24 hours in seconds
            # Read cached configuration
            local cached_config
            cached_config=$(head -n 1 "$cache_file" 2>/dev/null)
            # Compare with current configuration
            if [[ "$cached_config" == "${VM_NAME}-${VM_RAM}-${VM_CPU}-${VM_SIZE}" ]]; then
                cache_valid=true
            else
                print_info "VM configuration changed, invalidating cache..."
                rm -f "$cache_file"
            fi
        fi
    fi

    # Check KVM group membership
    if ! groups | grep -q -E 'kvm|qemu'; then
        print_warning "User is not a member of kvm or qemu group"
        print_info "You may need to add your user to the kvm group:"
        print_info "sudo usermod -aG kvm $USER"
    fi

    # Detect package manager and privilege command
    if command -v emerge >/dev/null 2>&1; then
        pkg_manager="emerge"
        pkg_install_cmd="emerge --ask --noreplace"
        privilege_cmd="sudo"
        # Gentoo package mapping
        declare -A pkg_map=(
            ["qemu-system-x86_64"]="app-emulation/qemu"
            ["qemu-img"]="app-emulation/qemu"
            ["swtpm"]="app-crypt/swtpm"
            ["genisoimage"]="app-cdr/cdrtools"
            ["curl"]="net-misc/curl"
            ["uuidgen"]="sys-apps/util-linux"
            ["jq"]="app-misc/jq"
            ["glxinfo"]="x11-apps/mesa-progs"
            ["lspci"]="sys-apps/pciutils"
            ["ps"]="sys-process/procps"
            ["python3"]="dev-lang/python"
            ["mkisofs"]="app-cdr/cdrtools"
            ["lsusb"]="sys-apps/usbutils"
            ["socat"]="net-misc/socat"
            ["spicy"]="app-emulation/spice"
            ["xrandr"]="x11-apps/xrandr"
            ["zsync"]="net-misc/zsync"
            ["unzip"]="app-arch/unzip"
        )
    elif command -v apt-get >/dev/null 2>&1; then
        pkg_manager="apt-get"
        pkg_install_cmd="apt-get install -y"
        privilege_cmd="sudo"
        # Debian/Ubuntu package mapping
        declare -A pkg_map=(
            ["qemu-system-x86_64"]="qemu-system-x86"
            ["qemu-img"]="qemu-utils"
            ["swtpm"]="swtpm-tools"
            ["genisoimage"]="genisoimage"
            ["curl"]="curl"
            ["uuidgen"]="uuid-runtime"
            ["jq"]="jq"
            ["glxinfo"]="mesa-utils"
            ["lspci"]="pciutils"
            ["ps"]="procps"
            ["python3"]="python3"
            ["mkisofs"]="genisoimage"
            ["lsusb"]="usbutils"
            ["socat"]="socat"
            ["spicy"]="spice-client-gtk"
            ["xrandr"]="x11-xserver-utils"
            ["zsync"]="zsync"
            ["unzip"]="unzip"
        )
    elif command -v dnf >/dev/null 2>&1; then
        pkg_manager="dnf"
        pkg_install_cmd="dnf install -y"
        privilege_cmd="sudo"
        # Fedora package mapping
        declare -A pkg_map=(
            ["qemu-system-x86_64"]="qemu-system-x86"
            ["qemu-img"]="qemu-img"
            ["swtpm"]="swtpm"
            ["genisoimage"]="genisoimage"
            ["curl"]="curl"
            ["uuidgen"]="util-linux"
            ["jq"]="jq"
            ["glxinfo"]="mesa-demos"
            ["lspci"]="pciutils"
            ["ps"]="procps-ng"
            ["python3"]="python3"
            ["mkisofs"]="genisoimage"
            ["lsusb"]="usbutils"
            ["socat"]="socat"
            ["spicy"]="spice-gtk-tools"
            ["xrandr"]="xorg-x11-server-utils"
            ["zsync"]="zsync"
            ["unzip"]="unzip"
        )
    elif command -v pacman >/dev/null 2>&1; then
        pkg_manager="pacman"
        pkg_install_cmd="pacman -S --noconfirm"
        privilege_cmd="sudo"
        # Arch package mapping
        declare -A pkg_map=(
            ["qemu-system-x86_64"]="qemu"
            ["qemu-img"]="qemu"
            ["swtpm"]="swtpm"
            ["genisoimage"]="cdrtools"
            ["curl"]="curl"
            ["uuidgen"]="util-linux"
            ["jq"]="jq"
            ["glxinfo"]="mesa-utils"
            ["lspci"]="pciutils"
            ["ps"]="procps-ng"
            ["python3"]="python"
            ["mkisofs"]="cdrtools"
            ["lsusb"]="usbutils"
            ["socat"]="socat"
            ["spicy"]="spice-gtk"
            ["xrandr"]="xorg-xrandr"
            ["zsync"]="zsync"
            ["unzip"]="unzip"
        )
    fi

    # List of required commands and their package names
    local deps=(
        "qemu-system-x86_64"
        "qemu-img"
        "swtpm"
        "genisoimage"
        "curl"
        "uuidgen"
        "jq"
        "glxinfo"
        "lspci"
        "ps"
        "python3"
        "mkisofs"
        "lsusb"
        "socat"
        "spicy"
        "xrandr"
        "zsync"
        "unzip"
    )

    # If cache is valid, read from it
    if [[ "$cache_valid" == "true" ]]; then
        print_info "Using cached dependency information..."
        # Skip the first line (configuration) and read dependencies
        tail -n +2 "$cache_file" | while IFS= read -r dep; do
            if ! command -v "$dep" >/dev/null 2>&1; then
                missing_deps+=("$dep")
            fi
        done
    else
        # Check each dependency and cache the results
        print_info "Checking dependencies..."

        # Clear cache file and write current configuration
        echo "${VM_NAME}-${VM_RAM}-${VM_CPU}-${VM_SIZE}" >"$cache_file"

        for dep in "${deps[@]}"; do
            # Special case for genisoimage/mkisofs
            if [[ "$dep" == "genisoimage" ]]; then
                if ! command -v genisoimage >/dev/null 2>&1 && ! command -v mkisofs >/dev/null 2>&1; then
                    missing_deps+=("$dep")
                    echo "$dep" >>"$cache_file"
                fi
            # Special case for xdg-user-dirs
            elif [[ "$dep" == "xdg-user-dirs" ]]; then
                if ! pkg-config --exists xdg-user-dirs; then
                    missing_deps+=("$dep")
                    echo "$dep" >>"$cache_file"
                fi
            # Normal case for other dependencies
            elif ! command -v "$dep" >/dev/null 2>&1; then
                missing_deps+=("$dep")
                echo "$dep" >>"$cache_file"
            fi
        done
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_warning "Missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            if [[ -n "${pkg_map[$dep]}" ]]; then
                print_warning "- $dep (package: ${pkg_map[$dep]})"
            else
                print_warning "- $dep"
            fi
        done

        if [[ -n "$pkg_manager" ]]; then
            print_info "Detected package manager: $pkg_manager"
            read -p "Would you like to install the missing dependencies? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Check for privilege command
                if ! command -v "$privilege_cmd" >/dev/null 2>&1; then
                    print_error "Privilege command ($privilege_cmd) not found"
                    print_info "Please install the missing packages manually"
                else
                    # Install missing packages
                    print_info "Installing missing dependencies..."
                    local pkgs_to_install=()
                    for dep in "${missing_deps[@]}"; do
                        if [[ -n "${pkg_map[$dep]}" ]]; then
                            pkgs_to_install+=("${pkg_map[$dep]}")
                        fi
                    done
                    "$privilege_cmd" "$pkg_install_cmd" "${pkgs_to_install[@]}"

                    # Clear cache after installation
                    rm -f "$cache_file"
                fi
            else
                print_warning "Continuing without installing dependencies. Some features may not work correctly."
            fi
        else
            print_warning "No supported package manager found"
            print_info "Please install the missing packages manually"
        fi
    else
        print_success "All required dependencies are installed"
    fi
}

# Main execution
check_dependencies

if [[ "$CHECK_DEPS_ONLY" == "true" ]]; then
    exit 0
fi

if [[ "$DOWNLOAD_ISO_ONLY" == "true" ]]; then
    download_windows_iso "$WINDOWS_VERSION"
    exit 0
fi

# Generate unique PID file for this instance
PID_FILE=$(generate_pid_file)
print_info "Using PID file: $PID_FILE"

prepare_files
locate_ovmf
create_disk
start_vm
