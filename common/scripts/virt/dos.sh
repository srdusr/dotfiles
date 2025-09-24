#!/usr/bin/env bash

# Set variables
HOST_DIR="virt"
VM_NAME="dos"
VM_SIZE="80G" # Disk size in GB
VM_RAM="8G"   # RAM size
VM_CPU="6"    # Number of virtual CPUs
CORES=$((VM_CPU / 2))
THREADS_PER_CORE=2
SOCKETS=1

VM_DIR="$HOST_DIR/machines"
IMAGE_DIR="$HOST_DIR/images"
WIN_ISO_DIR="${IMAGE_DIR}/${VM_NAME}" # Directory for Windows ISO
VM_DIR="$WIN_ISO_DIR"
SOCKET_DIR="$VM_DIR"
SHARED_DIR="${HOST_DIR}/shared"
FIRMWARE_DIR="${HOST_DIR}/firmware"
TPM_DIR="$WIN_ISO_DIR"
TPM_SOCKET="${WIN_ISO_DIR}/${VM_NAME}.swtpm-sock"
GUEST_PORT=22
QCOW2_FILE="${VM_DIR}/${VM_NAME}.qcow2"
RAW_FILE="${VM_DIR}/${VM_NAME}.raw"

# Anti-detection: Generate realistic hardware identifiers
REAL_MAC="00:1A:2B:3C:4D:5E"  # Example Dell MAC - replace with your choice
REAL_SERIAL="$(openssl rand -hex 8 | tr '[:lower:]' '[:upper:]')"
REAL_UUID="$(uuidgen)"
REAL_VENDOR="Dell Inc."
REAL_PRODUCT="OptiPlex 7090"
REAL_VERSION="01"
REAL_FAMILY="OptiPlex"

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

# Handle curl errors
handle_curl_error() {
    local exit_code=$1
    case $exit_code in
        6) print_error "Couldn't resolve host" ;;
        7) print_error "Failed to connect to host" ;;
        22) print_error "HTTP page not retrieved (404, etc.)" ;;
        28) print_error "Operation timeout" ;;
        *) print_error "Curl failed with exit code $exit_code" ;;
    esac
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

    # Direct curl download
    curl --disable --progress-bar --fail --location --proto '=https' --tlsv1.2 --http1.1 \
        --retry 3 --retry-delay 3 --connect-timeout 30 \
        --output "$WIN_ISO_DIR/$file_name" "$iso_download_link" || {
        handle_curl_error $?
        return 1
    }

    if [[ $? -ne 0 ]]; then
        print_error "Failed to download the Windows $windows_version ISO."
        return 1
    fi

    print_success "Successfully downloaded Windows $windows_version ISO to $WIN_ISO_DIR/$file_name"

    # Return the downloaded filename so calling code can use it
    echo "$file_name"
    return 0
}

# Create unattended installation ISO with proper Windows 11 bypass
create_unattended_iso() {
    print_info "Creating unattended installation ISO..."

    # Create enhanced autounattend.xml with Windows 11 TPM/Secure Boot bypass
    if [ ! -f "$WIN_ISO_DIR/unattended/autounattend.xml" ]; then
        print_info "Creating enhanced autounattend.xml with Windows 11 bypass..."
        mkdir -p "$WIN_ISO_DIR/unattended"
        cat >"$WIN_ISO_DIR/unattended/autounattend.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SetupUILanguage>
                <UILanguage>en-US</UILanguage>
            </SetupUILanguage>
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UILanguageFallback>en-US</UILanguageFallback>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <DiskConfiguration>
                <Disk wcm:action="add">
                    <CreatePartitions>
                        <CreatePartition wcm:action="add">
                            <Order>1</Order>
                            <Type>Primary</Type>
                            <Size>100</Size>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>2</Order>
                            <Type>EFI</Type>
                            <Size>100</Size>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>3</Order>
                            <Type>MSR</Type>
                            <Size>16</Size>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>4</Order>
                            <Type>Primary</Type>
                            <Extend>true</Extend>
                        </CreatePartition>
                    </CreatePartitions>
                    <ModifyPartitions>
                        <ModifyPartition wcm:action="add">
                            <Order>1</Order>
                            <PartitionID>1</PartitionID>
                            <Label>WINRE</Label>
                            <Format>NTFS</Format>
                            <TypeID>DE94BBA4-06D1-4D40-A16A-BFD50179D6AC</TypeID>
                        </ModifyPartition>
                        <ModifyPartition wcm:action="add">
                            <Order>2</Order>
                            <PartitionID>2</PartitionID>
                            <Label>System</Label>
                            <Format>FAT32</Format>
                        </ModifyPartition>
                        <ModifyPartition wcm:action="add">
                            <Order>3</Order>
                            <PartitionID>3</PartitionID>
                        </ModifyPartition>
                        <ModifyPartition wcm:action="add">
                            <Order>4</Order>
                            <PartitionID>4</PartitionID>
                            <Label>Windows</Label>
                            <Format>NTFS</Format>
                        </ModifyPartition>
                    </ModifyPartitions>
                    <DiskID>0</DiskID>
                    <WillWipeDisk>true</WillWipeDisk>
                </Disk>
            </DiskConfiguration>
            <ImageInstall>
                <OSImage>
                    <InstallTo>
                        <DiskID>0</DiskID>
                        <PartitionID>4</PartitionID>
                    </InstallTo>
                    <InstallToAvailablePartition>false</InstallToAvailablePartition>
                    <WillShowUI>OnError</WillShowUI>
                    <InstallFrom>
                        <MetaData wcm:action="add">
                            <Key>/IMAGE/INDEX</Key>
                            <Value>6</Value>
                        </MetaData>
                    </InstallFrom>
                </OSImage>
            </ImageInstall>
            <UserData>
                <AcceptEula>true</AcceptEula>
                <FullName>Windows User</FullName>
                <Organization>Windows</Organization>
                <ProductKey>
                    <WillShowUI>Never</WillShowUI>
                </ProductKey>
            </UserData>
            <!-- Windows 11 Requirements Bypass -->
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassTPMCheck /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassSecureBootCheck /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>3</Order>
                    <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassRAMCheck /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>4</Order>
                    <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassStorageCheck /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>5</Order>
                    <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassCPUCheck /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
            <EnableFirewall>false</EnableFirewall>
            <EnableNetwork>true</EnableNetwork>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UILanguageFallback>en-US</UILanguageFallback>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>DESKTOP-PC</ComputerName>
            <TimeZone>UTC</TimeZone>
        </component>
        <component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SkipAutoActivation>true</SkipAutoActivation>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <AutoLogon>
                <Password>
                    <Value>password</Value>
                    <PlainText>true</PlainText>
                </Password>
                <LogonCount>1</LogonCount>
                <Username>Administrator</Username>
                <Enabled>true</Enabled>
            </AutoLogon>
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Home</NetworkLocation>
                <ProtectYourPC>1</ProtectYourPC>
                <SkipMachineOOBE>true</SkipMachineOOBE>
                <SkipUserOOBE>true</SkipUserOOBE>
            </OOBE>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>password</Value>
                    <PlainText>true</PlainText>
                </AdministratorPassword>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Password>
                            <Value>password</Value>
                            <PlainText>true</PlainText>
                        </Password>
                        <Name>User</Name>
                        <Group>Administrators</Group>
                        <DisplayName>User</DisplayName>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
            <!-- Additional Windows 11 bypass commands -->
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <CommandLine>reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v NoAutoUpdate /t REG_DWORD /d 1 /f</CommandLine>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <CommandLine>reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f</CommandLine>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <Order>3</Order>
                    <CommandLine>powershell -Command "Set-ExecutionPolicy Unrestricted -Force"</CommandLine>
                </SynchronousCommand>
            </FirstLogonCommands>
        </component>
    </settings>
</unattend>
EOF
    fi

    # Create the unattended ISO
    if command -v genisoimage >/dev/null 2>&1; then
        print_info "Creating unattended ISO using genisoimage..."
        genisoimage -J -r -o "$WIN_ISO_DIR/unattended.iso" "$WIN_ISO_DIR/unattended" 2>/dev/null
        return $?
    elif command -v mkisofs >/dev/null 2>&1; then
        print_info "Creating unattended ISO using mkisofs..."
        mkisofs -J -r -o "$WIN_ISO_DIR/unattended.iso" "$WIN_ISO_DIR/unattended" 2>/dev/null
        return $?
    elif command -v xorriso >/dev/null 2>&1; then
        print_info "Creating unattended ISO using xorriso..."
        xorriso -as genisoimage -J -r -o "$WIN_ISO_DIR/unattended.iso" "$WIN_ISO_DIR/unattended" 2>/dev/null
        return $?
    else
        print_warning "No ISO creation tool found (genisoimage, mkisofs, or xorriso)"
        print_warning "Installing genisoimage..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y genisoimage
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y genisoimage
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm cdrtools
        fi

        # Try again after installation
        if command -v genisoimage >/dev/null 2>&1; then
            print_info "Creating unattended ISO using newly installed genisoimage..."
            genisoimage -J -r -o "$WIN_ISO_DIR/unattended.iso" "$WIN_ISO_DIR/unattended" 2>/dev/null
            return $?
        else
            print_error "Failed to install ISO creation tools"
            return 1
        fi
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

    # Download VirtIO drivers if missing (optional for stealth mode)
    if [[ ! -f "$ISO_VIRTIO" ]]; then
        print_info "VirtIO drivers ISO not found, downloading (for fallback)..."
        download_file "$VIRTIO_ISO_URL" "$ISO_VIRTIO" "" "true"
    else
        print_success "VirtIO drivers ISO already exists: $ISO_VIRTIO"
    fi

    # Create unattended ISO if it doesn't exist
    if [[ ! -f "$ISO_UNATTENDED" ]]; then
        create_unattended_iso
        if [[ $? -eq 0 ]]; then
            print_success "Created unattended ISO: $ISO_UNATTENDED"
        else
            print_error "Failed to create unattended ISO"
            exit 1
        fi
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
        "/usr/share/qemu/edk2-x86_64-code.fd"
    )

    OVMF_CODE=""
    OVMF_VARS=""

    for dir in "${OVMF_DIRS[@]}"; do
        if [[ -f "$dir" ]]; then
            # Handle direct file paths
            if [[ "$dir" == *"code.fd" ]]; then
                OVMF_CODE="$dir"
                OVMF_VARS="$(dirname "$dir")/edk2-x86_64-vars.fd"
            fi
        elif [[ -d "$dir" ]]; then
            # Handle directories
            [[ -z "$OVMF_CODE" ]] && OVMF_CODE=$(find "$dir" -type f -name "OVMF_CODE.fd" -o -name "edk2-x86_64-code.fd" 2>/dev/null | head -n 1)
            [[ -z "$OVMF_VARS" ]] && OVMF_VARS=$(find "$dir" -type f -name "OVMF_VARS.fd" -o -name "edk2-x86_64-vars.fd" 2>/dev/null | head -n 1)
        fi
        [[ -n "$OVMF_CODE" && -n "$OVMF_VARS" ]] && break
    done

    # Try package-specific locations
    if [[ -z "$OVMF_CODE" || -z "$OVMF_VARS" ]]; then
        # Ubuntu/Debian locations
        [[ -z "$OVMF_CODE" ]] && OVMF_CODE="/usr/share/OVMF/OVMF_CODE_4M.fd"
        [[ -z "$OVMF_VARS" && -f "/usr/share/OVMF/OVMF_VARS_4M.fd" ]] && OVMF_VARS="/usr/share/OVMF/OVMF_VARS_4M.fd"

        # Arch Linux locations
        [[ -z "$OVMF_CODE" ]] && OVMF_CODE="/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"
        [[ -z "$OVMF_VARS" && -f "/usr/share/edk2-ovmf/x64/OVMF_VARS.fd" ]] && OVMF_VARS="/usr/share/edk2-ovmf/x64/OVMF_VARS.fd"
    fi

    # Ensure a writable copy of OVMF_VARS.fd
    local original_ovmf_vars="$OVMF_VARS"
    OVMF_VARS="$FIRMWARE_DIR/OVMF_VARS.fd"

    if [[ ! -f "$OVMF_VARS" && -f "$original_ovmf_vars" ]]; then
        print_info "Copying OVMF_VARS.fd to $OVMF_VARS"
        cp "$original_ovmf_vars" "$OVMF_VARS" 2>/dev/null || {
            print_error "Failed to copy OVMF_VARS.fd!"
            print_info "Trying to install OVMF firmware..."

            # Try to install OVMF
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y ovmf
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y edk2-ovmf
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -S --noconfirm edk2-ovmf
            fi

            # Try to locate again after installation
            locate_ovmf
            return
        }
    fi

    # Check if required files exist
    if [[ -z "$OVMF_CODE" || ! -f "$OVMF_CODE" ]]; then
        print_error "OVMF_CODE.fd not found!"
        print_info "Please install OVMF firmware package:"
        print_info "  Ubuntu/Debian: sudo apt install ovmf"
        print_info "  RHEL/CentOS: sudo yum install edk2-ovmf"
        print_info "  Arch: sudo pacman -S edk2-ovmf"
        exit 1
    fi
    if [[ ! -f "$OVMF_VARS" ]]; then
        print_error "OVMF_VARS.fd not found or could not be copied!"
        exit 1
    fi

    print_success "Found OVMF firmware: $OVMF_CODE"
    print_success "Using OVMF vars: $OVMF_VARS"
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
        print_success "Created VM disk image: $QCOW2_FILE"
    else
        print_success "VM disk image already exists: $QCOW2_FILE"
    fi
}

# Helper function to convert QCOW2 to RAW for stealth
convert_to_raw() {
    if [[ -f "$QCOW2_FILE" && ! -f "$RAW_FILE" ]]; then
        print_info "Converting QCOW2 to RAW format for stealth..."
        qemu-img convert -f qcow2 -O raw "$QCOW2_FILE" "$RAW_FILE" || {
            print_error "Failed to convert to RAW format"
            exit 1
        }
        print_success "Successfully converted to RAW format: $RAW_FILE"
    elif [[ ! -f "$RAW_FILE" ]]; then
        print_info "Creating RAW disk image..."
        qemu-img create -f raw "$RAW_FILE" "$VM_SIZE" || {
            print_error "Failed to create RAW disk image"
            exit 1
        }
        print_success "Created RAW disk image: $RAW_FILE"
    else
        print_success "RAW disk image already exists: $RAW_FILE"
    fi
}

# Check dependencies
check_dependencies() {
    local missing_deps=()

    # Check for essential tools
    command -v qemu-system-x86_64 >/dev/null 2>&1 || missing_deps+=("qemu-system-x86_64")
    command -v swtpm >/dev/null 2>&1 || missing_deps+=("swtpm")
    command -v curl >/dev/null 2>&1 || missing_deps+=("curl")
    command -v uuidgen >/dev/null 2>&1 || missing_deps+=("uuidgen")
    command -v openssl >/dev/null 2>&1 || missing_deps+=("openssl")

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_info "Please install them using your package manager:"
        print_info "  Ubuntu/Debian: sudo apt install qemu-system-x86 swtpm curl uuid-runtime openssl"
        print_info "  RHEL/CentOS: sudo yum install qemu-kvm swtpm curl util-linux openssl"
        print_info "  Arch: sudo pacman -S qemu swtpm curl util-linux openssl"
        exit 1
    fi
}

start_vm() {
    # Verify that we have a Windows ISO
    if [[ -z "$WINDOWS_ISO_PATH" || ! -f "$WINDOWS_ISO_PATH" ]]; then
        print_error "Windows ISO file not found. Cannot start VM."
        print_info "Please download Windows 11 ISO and save it to: $WIN_ISO_DIR"
        exit 1
    fi

    # Anti-detection: Generate realistic hardware identifiers
    REAL_MAC="00:1A:79:$(openssl rand -hex 3 | sed 's/../&:/g; s/:$//')"  # Dell OUI
    REAL_SERIAL="$(openssl rand -hex 8 | tr '[:lower:]' '[:upper:]')"
    REAL_UUID="$(uuidgen)"
    REAL_VENDOR="Dell Inc."
    REAL_PRODUCT="OptiPlex 7090"
    REAL_VERSION="01"
    REAL_FAMILY="OptiPlex"

    # Stop any existing swtpm process for this VM
    if [[ -f "$TPM_SOCKET" ]]; then
        print_info "Cleaning up existing TPM socket..."
        rm -f "$TPM_SOCKET"
    fi

    # Start swtpm (TPM emulator)
    print_info "Starting TPM emulator..."
    /sbin/swtpm socket \
        --ctrl type=unixio,path="$TPM_SOCKET" \
        --terminate \
        --tpmstate dir="$TPM_DIR" \
        --tpm2 &

    # Give swtpm a moment to create the socket
    sleep 1

    # Verify TPM socket exists
    if [[ ! -S "$TPM_SOCKET" ]]; then
        print_error "TPM socket not created: $TPM_SOCKET"
        exit 1
    fi

    print_info "Starting stealth Windows 11 VM..."
    print_info "Using Windows ISO: $WINDOWS_ISO_PATH"
    print_info "VM will boot from unattended installation ISO"
    print_info "Default login: Username=User, Password=password"
    print_info "Anti-detection measures enabled"

    # Build qemu arguments in an array for safety and readability
    QEMU_ARGS=(
        # Basic VM configuration
        -name "$REAL_PRODUCT",process="$VM_NAME"
        -machine q35,hpet=off,smm=on,vmport=off,accel=kvm

        # Global optimizations
        -global kvm-pit.lost_tick_policy=discard
        -global ICH9-LPC.disable_s3=1

        # CPU configuration (stealth)
        -cpu host,-hypervisor,+invtsc,+ssse3,l3-cache=on,migratable=no
        -smp "$SMP_CONFIG"
        -m "$VM_RAM"

        # SMBIOS spoofing for anti-detection
        -smbios type=0,vendor="$REAL_VENDOR",version="$REAL_VERSION",date="03/15/2023"
        -smbios type=1,manufacturer="$REAL_VENDOR",product="$REAL_PRODUCT",version="$REAL_VERSION",serial="$REAL_SERIAL",uuid="$REAL_UUID",family="$REAL_FAMILY"
        -smbios type=2,manufacturer="$REAL_VENDOR",product="0NK70N",version="A00",serial="$REAL_SERIAL"
        -smbios type=3,manufacturer="$REAL_VENDOR",version="$REAL_VERSION",serial="$REAL_SERIAL"
        -smbios type=4,manufacturer="Intel(R) Corporation",version="11th Gen Intel(R) Core(TM) i7-1165G7 @ 2.80GHz"

        # Process management
        -pidfile "$VM_DIR/$VM_NAME.pid"
        -rtc base=localtime,clock=host,driftfix=slew

        # Display and graphics
        -vga qxl
        -display sdl

        # Boot configuration
        -boot menu=on,splash-time=0,order=d,reboot-timeout=5000

        # Random number generator
        -object rng-random,id=rng0,filename=/dev/urandom
        -device i82801b11-bridge,id=pci.1

        # usb
        -device usb-ehci,id=usb
        -device usb-kbd,bus=usb.0
        -device usb-tablet,bus=usb.0
        -k en-us

        # audio (pipewire)
        -audiodev pipewire,id=audio0
        -device AC97,audiodev=audio0

        # Network (realistic NIC with stealth MAC)
        -device rtl8139,netdev=nic,mac="$REAL_MAC"
        -netdev user,hostname="$VM_NAME",hostfwd=tcp::"$HOST_PORT"-:"$GUEST_PORT",smb="$SHARED_DIR",id=nic

        # UEFI firmware
        -global driver=cfi.pflash01,property=secure,value=on
        -drive if=pflash,format=raw,unit=0,file="$OVMF_CODE",readonly=on
        -drive if=pflash,format=raw,unit=1,file="$OVMF_VARS"

        # Main storage (AHCI for compatibility)
        -device ahci,id=ahci
        -drive if=none,id=disk0,format=raw,file="$RAW_FILE",cache=writeback
        -device ide-hd,bus=ahci.0,drive=disk0

        # CD-ROM drives (Windows ISO + Unattended)
        -drive media=cdrom,index=0,file="$WINDOWS_ISO_PATH",if=ide
        -drive media=cdrom,index=1,file="$ISO_UNATTENDED",if=ide

        # TPM 2.0
        -chardev socket,id=chrtpm,path="$TPM_SOCKET"
        -tpmdev emulator,id=tpm0,chardev=chrtpm
        -device tpm-tis,tpmdev=tpm0

        # Monitoring and management sockets
        -monitor unix:"$SOCKET_DIR/$VM_NAME-monitor.socket",server,nowait
        -serial unix:"$SOCKET_DIR/$VM_NAME-serial.socket",server,nowait
    )

    # Add VirtIO ISO if it exists (as fallback)
    if [[ -f "$ISO_VIRTIO" ]]; then
        QEMU_ARGS+=(-drive media=cdrom,index=2,file="$ISO_VIRTIO",if=ide,readonly=on)
    fi

    print_info "Starting QEMU with stealth configuration..."
    print_info "Monitor socket: $SOCKET_DIR/$VM_NAME-monitor.socket"
    print_info "Serial socket: $SOCKET_DIR/$VM_NAME-serial.socket"
    print_info "SSH port forwarding: localhost:$HOST_PORT -> VM:$GUEST_PORT"

    # Execute qemu
    exec qemu-system-x86_64 "${QEMU_ARGS[@]}"

}

# Helper function to convert QCOW2 to RAW for stealth
convert_to_raw() {
    if [[ -f "$QCOW2_FILE" && ! -f "$RAW_FILE" ]]; then
        print_info "Converting QCOW2 to RAW format for stealth..."
        qemu-img convert -f qcow2 -O raw "$QCOW2_FILE" "$RAW_FILE"
        if [[ $? -eq 0 ]]; then
            print_success "Successfully converted to RAW format"
        else
            print_error "Failed to convert to RAW format"
            exit 1
        fi
    elif [[ ! -f "$RAW_FILE" ]]; then
        print_info "Creating RAW disk image..."
        qemu-img create -f raw "$RAW_FILE" "$VM_SIZE"
    fi
}

# Anti-detection validation commands
show_validation_commands() {
    cat << 'EOF'
=== VM DETECTION VALIDATION COMMANDS ===

Run these commands inside Windows to verify stealth:

# PowerShell - Check hardware info:
Get-WmiObject -Class Win32_ComputerSystem | Select-Object Manufacturer, Model, TotalPhysicalMemory
Get-WmiObject -Class Win32_BIOS | Select-Object Manufacturer, Version, SerialNumber
Get-WmiObject -Class Win32_BaseBoard | Select-Object Manufacturer, Product, SerialNumber
Get-WmiObject -Class Win32_Processor | Select-Object Name, Manufacturer, MaxClockSpeed

# Check for hypervisor presence:
Get-WmiObject -Class Win32_ComputerSystem | Select-Object HypervisorPresent
bcdedit /enum | findstr hypervisorlaunchtype

# Registry checks for VM artifacts:
reg query "HKLM\HARDWARE\DESCRIPTION\System" /v SystemBiosVersion
reg query "HKLM\HARDWARE\DESCRIPTION\System\BIOS" /v SystemManufacturer
reg query "HKLM\SYSTEM\CurrentControlSet\Services" | findstr -i "vbox\|vmware\|qemu\|virtio"

# Check network adapter:
Get-WmiObject -Class Win32_NetworkAdapter | Where-Object {$_.NetConnectionStatus -eq 2} | Select-Object Name, MACAddress, Manufacturer

# Check PCI devices for VM signatures:
Get-WmiObject -Class Win32_PnPEntity | Where-Object {$_.Name -match "VirtIO|QEMU|VMware|VirtualBox|Hyper-V"} | Select-Object Name, DeviceID

# Check running services:
Get-Service | Where-Object {$_.Name -match "vbox|vmware|qemu|virtio|spice"}

# Check for VM-specific processes:
Get-Process | Where-Object {$_.ProcessName -match "vbox|vmware|qemu|virtio"}

# Additional checks:
systeminfo | findstr /C:"System Manufacturer" /C:"System Model" /C:"BIOS Version"
wmic computersystem get manufacturer,model,name,systemtype

EOF
}

# Cleanup function
cleanup() {
    print_info "Cleaning up..."

    # Kill swtpm if running
    if [[ -f "$TPM_SOCKET" ]]; then
        pkill -f "swtpm.*$TPM_SOCKET" 2>/dev/null || true
        rm -f "$TPM_SOCKET" 2>/dev/null || true
    fi

    # Remove PID file
    if [[ -f "$VM_DIR/$VM_NAME.pid" ]]; then
        rm -f "$VM_DIR/$VM_NAME.pid" 2>/dev/null || true
    fi
}

# Trap cleanup on exit
trap cleanup EXIT

# Main execution function
main() {
    print_info "=== Windows 11 Stealth VM Setup ==="
    print_info "VM Name: $VM_NAME"
    print_info "VM Size: $VM_SIZE"
    print_info "VM RAM: $VM_RAM"
    print_info "VM CPUs: $VM_CPU"
    print_info "Host Port: $HOST_PORT"

    check_dependencies
    prepare_files
    locate_ovmf
    create_disk
    convert_to_raw
    show_validation_commands

    print_success "Setup complete! Starting VM..."
    start_vm
}

# Run main function
main "$@"
