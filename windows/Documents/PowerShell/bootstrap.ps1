# Requires -RunAsAdministrator

# Set execution policy to remote signed
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Set network category to private
Set-NetConnectionProfile -NetworkCategory Private

# Variables
$dotfiles_url = 'https://github.com/srdusr/dotfiles.git'
$dotfiles_dir = "$HOME\.cfg"

# Function to handle errors
function handle_error {
    param ($message)
    Write-Host $message -ForegroundColor Red
    exit 1
}

# Logs
New-Item -Path $Env:USERPROFILE\Logs -ItemType directory -Force
Start-Transcript -Path $Env:USERPROFILE\Logs\Bootstrap.log
$ErrorActionPreference = 'SilentlyContinue'
Write-Host "Bootstrap.log generated in Logs\"

# Function to check if the current session is elevated
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Ensure the script is run as administrator
if (-not (Test-IsAdmin)) {
    handle_error "This script must be run as an administrator."
}

# Imports
. $HOME\.config\powershell\initialize.ps1
. $HOME\.config\powershell\bloatware.ps1

# Configure PowerShell
Write-Host "Configuring PowerShell"
Write-Host "----------------------------------------"

# Get the "MyDocuments" path for the current user, excluding OneDrive
$UserMyDocumentsPath = [System.Environment]::GetFolderPath('MyDocuments').Replace("OneDrive", "")

$PowerShellProfileDirectory = "$UserMyDocumentsPath\PowerShell"
$PowerShellLegacySymlink = "$UserMyDocumentsPath\WindowsPowerShell"

$PowerShellProfileTemplate = "$PSScriptRoot\$USERNAME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
$env:PSModulePath = $env:PSModulePath -replace "\\OneDrive\\Documents\\WindowsPowerShell\\","\.powershell\"

# Set documents path to user's local Documents folder
$documentsPath = "$UserMyDocumentsPath"
$powerShellProfileDir = "$documentsPath\PowerShell"

# Output the chosen PowerShell profile directory
$PROFILE = "$powerShellProfileDir\Microsoft.PowerShell_profile.ps1"
Write-Host "PowerShell profile directory set to: $powerShellProfileDir"

if (-not (Test-Path -Path $powerShellProfileDir)) {
    New-Item -ItemType Directory -Path $powerShellProfileDir -Force
}

New-Item -ItemType HardLink -Force `
    -Path "$powerShellProfileDir\Microsoft.PowerShell_profile.ps1" `
    -Target "$home\.config\powershell\Microsoft.PowerShell_profile.ps1"

# Set environment variable
[System.Environment]::SetEnvironmentVariable('PowerShellProfileDir', $powerShellProfileDir, [System.EnvironmentVariableTarget]::User)

Write-Host "PowerShell profile directory set to: $powerShellProfileDir"
Write-Host "Environment variable 'PowerShellProfileDir' set to: $powerShellProfileDir"

# Verify profile sourcing
if (!(Test-Path -Path "$home\.config\powershell\Microsoft.PowerShell_profile.ps1")) {
    handle_error "PowerShell profile does not exist. Please create it at $home\.config\powershell\Microsoft.PowerShell_profile.ps1"
}

# Install Chocolatey if not installed
Write-Host "Installing Chocolatey"
Write-Host "----------------------------------------"

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # Check if Chocolatey installed successfully
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        handle_error "Chocolatey installation failed."
    }
} else {
    Write-Host "Chocolatey is already installed."
}

# Install Applications
Write-Host "Installing Applications"
Write-Host "----------------------------------------"

# Check if the powershell-yaml module is installed, if not, install it
if (-not (Get-Module powershell-yaml -ListAvailable)) {
    $policy = Get-PSRepository -Name 'PSGallery' | Select-Object -ExpandProperty InstallationPolicy
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    Install-Module powershell-yaml
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy $policy
}

Import-Module powershell-yaml

# Load packages.yml
$packagesFile = "$HOME\packages.yml"
$packages = Get-Content $packagesFile | ConvertFrom-Yaml

# Ensure 'windows' section exists and has applications listed
if ($packages.windows) {
    foreach ($app in $packages.windows) {
        # Check if the application is already installed
        if (-not (choco list --local-only | Select-String -Pattern "^$app\s")) {
            Write-Host "Installing $app"
            choco install $app -y

            if ($LASTEXITCODE -ne 0) {
                handle_error "Installation of $app failed."
            } else {
                Write-Host "$app installed successfully."
            }
        } else {
            Write-Host "$app is already installed."
        }
    }
} else {
    Write-Host "No applications specified under the 'windows' section in $packagesFile."
}

# Set Chrome as default browser ------------------------
#Add-Type -AssemblyName 'System.Windows.Forms'
#Start-Process $env:windir\system32\control.exe -ArgumentList '/name Microsoft.DefaultPrograms /page pageDefaultProgram\pageAdvancedSettings?pszAppName=google%20chrome'
#Sleep 2
#[System.Windows.Forms.SendKeys]::SendWait("{TAB} {TAB}{TAB} ")
SetDefaultBrowser firefox

# Refresh the environment variables
Write-Host "Refreshing environment variables"

# Update the current session environment variables
Write-Host "Setting environment variables" -ForegroundColor Cyan
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
[System.Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Process)
[Environment]::SetEnvironmentVariable("HOME", "$env:USERPROFILE", "User")
[Environment]::SetEnvironmentVariable("LC_ALL", "C.UTF-8", "User")
refreshenv

# Add Git to PATH if it's installed via Chocolatey
Write-Host "Checking for Git installation"
$gitBinPath = "C:\Program Files\Git\bin"
$gitCmdPath = "C:\Program Files\Git\cmd"
$gitPaths = @($gitBinPath, $gitCmdPath)

foreach ($path in $gitPaths) {
    if (Test-Path $path) {
        Write-Host "Adding $path to PATH"
        [System.Environment]::SetEnvironmentVariable("Path", "$env:Path;$path", [System.EnvironmentVariableTarget]::Machine)
        [System.Environment]::SetEnvironmentVariable("Path", "$env:Path;$path", [System.EnvironmentVariableTarget]::User)
        [System.Environment]::SetEnvironmentVariable("Path", "$env:Path;$path", [System.EnvironmentVariableTarget]::Process)
    } else {
        Write-Host "$path does not exist."
    }
}

# Check if Git is installed
Write-Host "Checking for Git installation"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    handle_error "Git is not installed or not found in PATH after installation."
} else {
    Write-Host "Git is installed and available in PATH."
}

# Define the `config` alias in the current session
function global:config {
    git --git-dir="$env:USERPROFILE\.cfg" --work-tree="$env:USERPROFILE" $args
}

# Add .gitignore entries
Add-Content -Path "$HOME\.gitignore" -Value ".cfg"
Add-Content -Path "$HOME\.gitignore" -Value "install.bat"
Add-Content -Path "$HOME\.gitignore" -Value ".config/powershell/bootstrap.ps1"

# Create symbolic links
Write-Host "Create symbolic links"
Write-Host "----------------------------------------"

# Visual Studio Code settings.json
New-Item -Force -ItemType SymbolicLink $HOME\AppData\Roaming\Code\User\ -Name settings.json -Value $HOME\.config\Code\User\settings.json

# Visual Studio Code keybindings
New-Item -Force -ItemType SymbolicLink $HOME\AppData\Roaming\Code\User\ -Name keybindings.json -Value $HOME\.config\Code\User\keybindings.json

# Function to install dotfiles
function install_dotfiles {
    if (Test-Path -Path $dotfiles_dir) {
        config pull | Out-Null
        $update = $true
    } else {
        git clone --bare $dotfiles_url $dotfiles_dir | Out-Null
        $update = $false
    }

    $std_err_output = config checkout 2>&1

    if ($std_err_output -match "following untracked working tree files would be overwritten") {
        if (-not $update) {
            config checkout | Out-Null
        }
    }
    config config status.showUntrackedFiles no

    git config --global include.path "$HOME\.gitconfig.aliases"

    if ($update -or (Read-Host "Do you want to overwrite existing files and continue with the dotfiles setup? [Y/n]" -eq "Y")) {
        config fetch origin main:main | Out-Null
        config reset --hard main | Out-Null
        config checkout -f
        if ($?) {
            Write-Host "Successfully imported $dotfiles_dir."
        } else {
            handle_error "Mission failed."
        }
    } else {
        handle_error "Aborted by user. Exiting..."
    }
}

install_dotfiles

# Install python
Write-Host "Updating python packages" -ForegroundColor Cyan
python -m pip install --upgrade pip

# Enable WSL feature
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
Write-Host "Enable WSL feature"
wsl --install -d ubuntu
wsl --set-default-version 2

# Enable Virtual Machine feature
#dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
#Write-Host "Enable Virtual Machine feature"

Write-Header "Installing Hyper-V"

# Install Hyper-V
Write-Host "Installing Hyper-V and restart"
Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
Install-WindowsFeature -Name Hyper-V -IncludeAllSubFeature -IncludeManagementTools -NoRestart

# Configure Neovim
Write-Host "Configuring Neovim"
Write-Host "----------------------------------------"

$neovimLocalPath = "$home\AppData\Local\nvim"
$neovimConfigPath = "$home\.config\nvim"

# Check if nvim directory already exists in AppData\Local
if (-not (Test-Path -Path $neovimLocalPath)) {
    New-Item -ItemType Junction -Force -Path $neovimLocalPath -Target $neovimConfigPath
} else {
    Write-Host "Neovim directory ($neovimLocalPath) already exists."
}

# Install Windows Terminal, and configure
Write-Host "Install Windows Terminal, and configure"
Write-Host "----------------------------------------"

$windowsTerminalSettingsPath = "$home\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$windowsTerminalConfigPath = "$home\.config\windows-terminal\settings.json"

# Check if Windows Terminal settings.json already exists
if (Test-Path -Path $windowsTerminalSettingsPath) {
    # Backup existing settings.json
    Move-Item -Force $windowsTerminalSettingsPath "$windowsTerminalSettingsPath.old"
} else {
    Write-Host "Windows Terminal settings.json not found, no need to backup."
}

# Create a hard link to the settings.json file in .config\windows-terminal
New-Item -ItemType HardLink -Force -Path $windowsTerminalSettingsPath -Target $windowsTerminalConfigPath

# Function to check if a registry key exists
function Test-RegistryKeyExists {
    param ($path)
    return (Test-Path $path -PathType Container)
}

# Function to check if a registry property exists
function Test-RegistryPropertyExists {
    param ($keyPath, $propertyName)
    if (Test-Path $keyPath) {
        $properties = Get-ItemProperty -Path $keyPath
        return $properties.PSObject.Properties.Name -contains $propertyName
    }
    return $false
}

# Registry Tweaks
Write-Host "Registry Tweaks"
Write-Host "----------------------------------------"

# Show hidden files
$advancedKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (-not (Test-RegistryPropertyExists $advancedKeyPath "Hidden")) {
    Set-ItemProperty -Path $advancedKeyPath -Name Hidden -Value 1
}

# Show file extensions in Windows Explorer
$hideFileExtPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (-not (Test-RegistryPropertyExists $hideFileExtPath "HideFileExt")) {
    Set-ItemProperty -Path $hideFileExtPath -Name HideFileExt -Value 0
}

# Never Combine taskbar buttons when the taskbar is full
$taskbarGlomLevelPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (-not (Test-RegistryPropertyExists $taskbarGlomLevelPath "TaskbarGlomLevel")) {
    Set-ItemProperty -Path $taskbarGlomLevelPath -Name TaskbarGlomLevel -Value 2
}

# Taskbar small icons
$taskbarSmallIconsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (-not (Test-RegistryPropertyExists $taskbarSmallIconsPath "TaskbarSmallIcons")) {
    Set-ItemProperty -Path $taskbarSmallIconsPath -Name TaskbarSmallIcons -Value 1
}

# Set Windows to use UTC time instead of local time for system clock
$timeZoneInfoPath = "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation"
if (-not (Test-RegistryPropertyExists $timeZoneInfoPath "RealTimeIsUniversal")) {
    Set-ItemProperty -Path $timeZoneInfoPath -Name RealTimeIsUniversal -Value 1
}

# Disable the search in taskbar
$searchBoxTaskbarPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
if (-not (Test-RegistryPropertyExists $searchBoxTaskbarPath "SearchBoxTaskbarMode")) {
    New-ItemProperty -Path $searchBoxTaskbarPath -Name SearchBoxTaskbarMode -Value 0 -Type DWord -Force
}

# Dark mode:
$personalizePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
if (-not (Test-RegistryPropertyExists $personalizePath "AppsUseLightTheme")) {
    Set-ItemProperty -Path $personalizePath -Name AppsUseLightTheme -Value 0 -Type Dword -Force
}
if (-not (Test-RegistryPropertyExists $personalizePath "SystemUsesLightTheme")) {
    Set-ItemProperty -Path $personalizePath -Name SystemUsesLightTheme -Value 0 -Type Dword -Force
}

# Restart explorer so the rest of the settings take effect:
Stop-Process -f -ProcessName explorer
Start-Process explorer.exe

# Function to disable the Windows key
function Disable-WindowsKey {
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout"
    $regName = "Scancode Map"

    # Binary data to remap the Windows key to F24 (an unused key)
    $binaryValue = [byte[]](
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x02, 0x00, 0x00, 0x00,
        0x3A, 0x00, 0x5B, 0xE0,
        0x00, 0x00, 0x00, 0x00
    )

    # Create the registry key if it doesn't exist
    if (-not (Test-RegistryKeyExists $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }

    # Set the Scancode Map value if it doesn't exist
    if (-not (Test-RegistryPropertyExists $regPath $regName)) {
        Set-ItemProperty -Path $regPath -Name $regName -Value $binaryValue
    }

    Write-Output "Windows key has been disabled from opening the start menu. Please restart your computer for the changes to take effect."
}

#Disable-WindowsKey

Write-Host "Bootstrap script completed."
Write-Host "Please Restart."

# Clean up Bootstrap.log
Write-Host "Clean up Bootstrap.log"
Stop-Transcript
$logSuppress = Get-Content $Env:USERPROFILE\Logs\Bootstrap.log | Where-Object { $_ -notmatch "Host Application: powershell.exe" }
$logSuppress | Set-Content $Env:USERPROFILE\Logs\Bootstrap.log -Force
