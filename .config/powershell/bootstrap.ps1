#Requires -RunAsAdministrator

# Write-Host Set PowerShell Execution Policy
# Write-Host ----------------------------------------
# Set-ExecutionPolicy Unrestricted

$newUsername = "srdusr"
$newUserProfilePath = "C:\Users\$newUsername"
$oldUsername = $env:USERNAME

# Function to update registry for user profile path
function Update-ProfileRegistry {
    $profileListKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
    $subKeys = Get-ChildItem -Path $profileListKey
    foreach ($subKey in $subKeys) {
        $profileImagePath = (Get-ItemProperty -Path "$profileListKey\$($subKey.PSChildName)").ProfileImagePath
        if ($profileImagePath -like "*$oldUsername*") {
            $newProfileImagePath = $profileImagePath -replace $oldUsername, $newUsername
            Set-ItemProperty -Path "$profileListKey\$($subKey.PSChildName)" -Name ProfileImagePath -Value $newProfileImagePath
            Write-Host "Updated ProfileImagePath for $($subKey.PSChildName)"
        }
    }
}

# Function to update environment variables
function Update-EnvironmentVariables {
    $envVars = [System.Environment]::GetEnvironmentVariables("User")
    foreach ($envVar in $envVars.Keys) {
        if ($envVars[$envVar] -like "*$oldUsername*") {
            $newEnvValue = $envVars[$envVar] -replace $oldUsername, $newUsername
            [System.Environment]::SetEnvironmentVariable($envVar, $newEnvValue, "User")
            Write-Host "Updated environment variable $envVar"
        }
    }
}

# Rename the user profile directory
function Rename-UserProfileDirectory {
    $oldUserProfilePath = "C:\Users\$oldUsername"
    if (Test-Path -Path $oldUserProfilePath) {
        Rename-Item -Path $oldUserProfilePath -NewName $newUsername
        Write-Host "Renamed user profile directory from $oldUserProfilePath to $newUserProfilePath"
    } else {
        Write-Host "The old user profile directory $oldUserProfilePath does not exist."
    }
}

# Perform the updates
Rename-UserProfileDirectory
Update-ProfileRegistry
Update-EnvironmentVariables

Write-Host "Profile registry paths, environment variables, and user profile directory have been updated. Please reboot the system."


# Install NVM if not installed
Write-Host "Configuring NVM"
Write-Host "----------------------------------------"
if (-not (Test-NVMInstalled)) {
    Write-Host "NVM is not installed. Proceeding with installation."
    $nvmUrl = "https://github.com/coreybutler/nvm-windows/releases/latest/download/nvm-setup.zip"
    $extractPath = "C:\Temp\nvm\"
    $downloadZipFile = $extractPath + (Split-Path -Path $nvmUrl -Leaf)
    mkdir $extractPath -ErrorAction SilentlyContinue
    Invoke-WebRequest -Uri $nvmUrl -OutFile $downloadZipFile
    $extractShell = New-Object -ComObject Shell.Application
    $extractFiles = $extractShell.Namespace($downloadZipFile).Items()
    $extractShell.NameSpace($extractPath).CopyHere($extractFiles)
    pushd $extractPath
    Start-Process .\nvm-setup.exe -Wait
    popd
    Read-Host -Prompt "Setup done, now close the command window, and run this script again in a new elevated window. Press any key to continue"
    Exit
} else {
    Write-Host "Detected that NVM is already installed. Now using it to install NodeJS LTS."
    $nvmPath = "$env:USERPROFILE\AppData\Roaming\nvm"
    pushd $nvmPath
    .\nvm.exe install lts
    .\nvm.exe use lts
    popd
}

# WSL
Write-Host "Configuring WSL"
wsl --install -d Ubuntu

# Install Chocolatey
Write-Host "Installing Chocolatey"
Write-Host "----------------------------------------"
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Applications
Write-Host "Installing Applications"
Write-Host "----------------------------------------"
choco install ripgrep -y
choco install fd -y
choco install sudo -y
choco install win32yank -y

# Configure Neovim
Write-Host "Configuring Neovim"
Write-Host "----------------------------------------"
New-Item -ItemType Junction -Force `
    -Path "$home\AppData\Local\nvim" `
    -Target "$home\.config\nvim"

# Install Windows Terminal, and configure
Write-Host "Install Windows Terminal, and configure"
Write-Host "----------------------------------------"
Move-Item -Force "$home\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" "$home\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json.old"
New-Item -ItemType HardLink -Force `
    -Path "$home\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" `
    -Target "$home\.config\windows-terminal\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

# Configure PowerShell
Write-Host "Configuring PowerShell"
Write-Host "----------------------------------------"
$documentsPath = [Environment]::GetFolderPath('Personal') # Default Documents folder
if ($documentsPath -like "*OneDrive*") {
    $documentsPath = "$env:USERPROFILE\Documents"
}
$powerShellProfileDir = "$documentsPath\PowerShell"

if (-not (Test-Path -Path $powerShellProfileDir)) {
    New-Item -ItemType Directory -Path $powerShellProfileDir -Force
}
New-Item -ItemType HardLink -Force `
    -Path "$powerShellProfileDir\Microsoft.PowerShell_profile.ps1" `
    -Target "$home\.config\powershell\Microsoft.PowerShell_profile.ps1"

# Registry Tweaks
Write-Host "Registry Tweaks"
Write-Host "----------------------------------------"

# Show hidden files
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Hidden -Value 1

# Show file extensions for known file types
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0

# Never Combine taskbar buttons when the taskbar is full
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarGlomLevel -Value 2

# Taskbar small icons
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarSmallIcons -Value 1

# Set Windows to use UTC time instead of local time for system clock
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name RealTimeIsUniversal -Value 1

# Function to check if the current session is elevated
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to disable the Windows key
function Disable-WindowsKey {
    $scancodeMap = @(
        0x00000000, 0x00000000, 0x00000003, 0xE05B0000, 0xE05C0000, 0x00000000
    )

    $binaryValue = New-Object byte[] ($scancodeMap.Length * 4)
    [System.Buffer]::BlockCopy($scancodeMap, 0, $binaryValue, 0, $binaryValue.Length)

    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout" -Name "Scancode Map" -Value $binaryValue

    Write-Output "Windows key has been disabled. Please restart your computer for the changes to take effect."
}

# Check if running as Administrator and call the function
if (Test-IsAdmin) {
    Disable-WindowsKey
} else {
    Write-Output "You need to run this script as Administrator to disable the Windows key."
}


# Check if the profile exists, otherwise create it
if (!(Test-Path -Path $PROFILE)) {
    New-Item -Type File -Path $PROFILE -Force
}

# Set the content of the profile to load your dotfiles and define 'config' alias
"'$env:USERPROFILE\.cfg'" >> $PROFILE
"function global:config { git --git-dir=$env:USERPROFILE/.cfg --work-tree=$env:USERPROFILE $args }" >> $PROFILE
"config config --local status.showUntrackedFiles no" >> $PROFILE
"config checkout" >> $PROFILE
