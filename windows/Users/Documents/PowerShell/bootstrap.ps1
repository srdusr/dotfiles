#!/usr/bin/env pwsh

# Created By: srdusr
# Created On: Windows PowerShell Bootstrap Script
# Project: Dotfiles installation script for Windows

# Dependencies: git, powershell

param(
    [string]$Profile = "essentials",
    [switch]$Force = $false,
    [switch]$Ask = $false,
    [switch]$Help = $false
)

# Color definitions for pretty UI
$Script:Colors = @{
    Reset   = "`e[0m"
    Red     = "`e[0;31m"
    Green   = "`e[0;32m"
    Yellow  = "`e[0;33m"
    Blue    = "`e[0;34m"
    Cyan    = "`e[0;36m"
    White   = "`e[0;37m"
    Bold    = "`e[1m"
}

# Prompt helper: Yes/No with default; in non-Ask mode, returns default immediately
function Prompt-YesNo {
    param(
        [Parameter(Mandatory=$true)][string]$Question,
        [ValidateSet('Y','N')][string]$Default = 'Y'
    )
    if (-not $Script:AskPreference) {
        return $Default -eq 'Y'
    }
    $suffix = if ($Default -eq 'Y') { '[Y/n]' } else { '[y/N]' }
    while ($true) {
        Write-Host -NoNewline "$Question $suffix: " -ForegroundColor Yellow
        $resp = Read-Host
        if ([string]::IsNullOrWhiteSpace($resp)) { $resp = $Default }
        switch ($resp.ToUpper()) {
            'Y' { return $true }
            'YES' { return $true }
            'N' { return $false }
            'NO' { return $false }
            default { Write-Warning "Please answer Y/yes or N/no" }
        }
    }
}

# Configuration
$Script:Config = @{
    DotfilesUrl = 'https://github.com/srdusr/dotfiles.git'
    DotfilesDir = "$HOME\.cfg"
    LogFile = "$HOME\AppData\Local\dotfiles_install.log"
    StateFile = "$HOME\AppData\Local\dotfiles_install_state"
    BackupDir = "$HOME\.dotfiles-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    PackagesFile = "packages.yml"
    OS = "windows"
}

# Logging functions
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $Script:Config.LogFile -Value $logEntry -Force
}

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
    Write-Log $Message
}

function Write-Success { param([string]$Message) Write-ColorOutput "✓ $Message" "Green" }
function Write-Info { param([string]$Message) Write-ColorOutput "ℹ $Message" "Cyan" }
function Write-Warning { param([string]$Message) Write-ColorOutput "⚠ $Message" "Yellow" }
function Write-Error { param([string]$Message) Write-ColorOutput "✗ $Message" "Red" }

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Blue
    Write-Host " $Title" -ForegroundColor Bold
    Write-Host "=" * 60 -ForegroundColor Blue
    Write-Host ""
}

# Utility functions
function Test-CommandExists {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-AdminCommand {
    param([string]$Command)
    if (-not (Test-IsAdmin)) {
        Write-Warning "Elevating privileges for: $Command"
        Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", $Command -Verb RunAs -Wait
    } else {
        Invoke-Expression $Command
    }
}

# Package management functions
function Get-PackageManager {
    if (Test-CommandExists "choco") { return "chocolatey" }
    if (Test-CommandExists "winget") { return "winget" }
    if (Test-CommandExists "scoop") { return "scoop" }
    return $null
}

# Return $true if a package appears to be installed for the given manager
function Test-PackageInstalled {
    param(
        [Parameter(Mandatory=$true)][string]$Manager,
        [Parameter(Mandatory=$true)][string]$Name
    )
    switch ($Manager) {
        "chocolatey" {
            $out = choco list --local-only --exact $Name 2>$null
            return ($out | Select-String -Pattern "^\s*$([regex]::Escape($Name))\s").Length -gt 0
        }
        "winget" {
            # Winget list may return multiple rows; use --exact name match when possible
            $out = winget list --name $Name 2>$null
            return ($out | Select-String -SimpleMatch $Name).Length -gt 0
        }
        "scoop" {
            # scoop list <name> returns 0 when installed
            scoop list $Name *> $null
            return $LASTEXITCODE -eq 0
        }
        default { return $false }
    }
}

function Install-PackageManager {
    Write-Header "Installing Package Manager"
    
    if (-not (Test-CommandExists "choco")) {
        Write-Info "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        if (Test-CommandExists "choco") {
            Write-Success "Chocolatey installed successfully"
        } else {
            Write-Error "Failed to install Chocolatey"
            return $false
        }
    } else {
        Write-Info "Chocolatey already installed"
    }
    return $true
}

function Install-Packages {
    param([string]$PackagesFile, [string]$Profile)
    
    if (-not (Test-Path $PackagesFile)) {
        Write-Warning "Packages file not found: $PackagesFile"
        return
    }
    
    Write-Header "Installing Packages"
    
    # Install powershell-yaml if not available
    if (-not (Get-Module powershell-yaml -ListAvailable)) {
        Write-Info "Installing powershell-yaml module..."
        $policy = Get-PSRepository -Name 'PSGallery' | Select-Object -ExpandProperty InstallationPolicy
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
        Install-Module powershell-yaml -Force
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy $policy
    }
    
    Import-Module powershell-yaml

    # Helper: run custom_installs.<name>.windows if condition passes
    function Invoke-CustomInstallsWindows {
        param([Parameter(Mandatory=$true)]$Yaml)
        if (-not $Yaml.custom_installs) { return }
        foreach ($name in $Yaml.custom_installs.PSObject.Properties.Name) {
            $entry = $Yaml.custom_installs.$name
            if (-not $entry) { continue }
            $winCmd = $entry.windows
            if (-not $winCmd) { continue }
            $shouldRun = $true
            if ($entry.condition) {
                $cond = [string]$entry.condition
                if ($cond -match "!\s*command\s+-v\s+([A-Za-z0-9._-]+)") {
                    $shouldRun = -not (Test-CommandExists $Matches[1])
                } elseif ($cond -match "command\s+-v\s+([A-Za-z0-9._-]+)") {
                    $shouldRun = (Test-CommandExists $Matches[1])
                }
            }
            if (-not $shouldRun) { Write-Info "Skipping custom install: $name"; continue }
            Write-Info "Running custom install: $name"
            try { Invoke-Expression $winCmd; Write-Success "Custom install completed: $name" }
            catch { Write-Warning "Custom install failed for '$name': $_" }
        }
    }
    
    try {
        $packages = Get-Content $PackagesFile | ConvertFrom-Yaml
        $packageManager = Get-PackageManager
        
        if (-not $packageManager) {
            Write-Error "No package manager available"
            return
        }
        
        # Install profile-specific Windows packages (profiles.<profile>.windows)
        if ($packages.profiles.$Profile.windows) {
            foreach ($pkg in $packages.profiles.$Profile.windows) {
                if ([string]::IsNullOrWhiteSpace($pkg)) { continue }
                if (Test-PackageInstalled -Manager $packageManager -Name $pkg) { Write-Info "Already installed: $pkg"; continue }
                Write-Info "Installing package: $pkg"
                switch ($packageManager) {
                    "chocolatey" { if (-not (choco list --local-only | Select-String -Pattern "^$([regex]::Escape($pkg))\s")) { choco install $pkg -y } }
                    "winget"     { winget install --id $pkg --silent --accept-package-agreements --accept-source-agreements }
                    "scoop"      { scoop install $pkg }
                }
            }
        }

        # Install top-level Windows packages list if present
        if ($packages.windows) {
            foreach ($pkg in $packages.windows) {
                if ([string]::IsNullOrWhiteSpace($pkg)) { continue }
                if (Test-PackageInstalled -Manager $packageManager -Name $pkg) { Write-Info "Already installed: $pkg"; continue }
                Write-Info "Installing package: $pkg"
                switch ($packageManager) {
                    "chocolatey" {
                        if (-not (choco list --local-only | Select-String -Pattern "^$([regex]::Escape($pkg))\s")) { choco install $pkg -y }
                    }
                    "winget" { winget install --id $pkg --silent --accept-package-agreements --accept-source-agreements }
                    "scoop" { scoop install $pkg }
                }
            }
        }

        # Execute Windows custom installs from packages.yml
        Invoke-CustomInstallsWindows -Yaml $packages
    } catch {
        Write-Error "Error processing packages: $_"
    }
}

# Dotfiles management functions
function Install-Dotfiles {
    Write-Header "Installing Dotfiles"
    
    if (Test-Path $Script:Config.DotfilesDir) {
        Write-Info "Updating existing dotfiles repository..."
        & git --git-dir="$($Script:Config.DotfilesDir)" --work-tree="$($Script:Config.DotfilesDir)" pull origin main
    } else {
        Write-Info "Cloning dotfiles repository..."
        git clone --bare $Script:Config.DotfilesUrl $Script:Config.DotfilesDir
        
        if (-not (Test-Path $Script:Config.DotfilesDir)) {
            Write-Error "Failed to clone dotfiles repository"
            return $false
        }
    }
    
    # Set up config alias for this session
    function script:config {
        git --git-dir="$($Script:Config.DotfilesDir)" --work-tree="$($Script:Config.DotfilesDir)" @args
    }
    
    # Configure repository
    config config --local status.showUntrackedFiles no
    
    # Checkout files to restore directory structure
    Write-Info "Checking out dotfiles..."
    try {
        config checkout 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Info "Forcing checkout to overwrite existing files..."
            config checkout -f
        }
        Write-Success "Dotfiles checked out successfully"
    } catch {
        Write-Error "Failed to checkout dotfiles: $_"
        return $false
    }
    
    return $true
}

function Deploy-Dotfiles {
    Write-Header "Deploying Dotfiles"
    
    if (-not (Test-Path $Script:Config.DotfilesDir)) {
        Write-Error "Dotfiles directory not found. Run Install-Dotfiles first."
        return $false
    }
    
    # Source the config command from profile if available
    $profilePath = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    if (Test-Path $profilePath) {
        Write-Info "Loading config command from profile..."
        . $profilePath
    }
    
    # Deploy using config command if available, otherwise manual deployment
    if (Get-Command config -ErrorAction SilentlyContinue) {
        Write-Info "Deploying dotfiles using config command..."
        config deploy
    } else {
        Write-Warning "Config command not available, using manual deployment..."
        # Manual deployment fallback would go here
    }
    
    Write-Success "Dotfiles deployment completed"
    return $true
}

# Locate profile-specific packages.yml similar to Linux installer
function Get-ProfilePackagesFile {
    param([string]$Profile)
    $candidates = @(
        # Profile-specific overrides
        Join-Path $HOME ".cfg/profile/$Profile/packages.yml",
        Join-Path $HOME "profile/$Profile/packages.yml",
        Join-Path $HOME "dot_setup/profile/$Profile/packages.yml",
        # Common locations for the primary packages.yml
        Join-Path $HOME ".cfg/common/$($Script:Config.PackagesFile)",
        Join-Path $HOME "$($Script:Config.PackagesFile)",
        Join-Path $HOME "common/$($Script:Config.PackagesFile)",
        Join-Path $HOME "dot_setup/packages.yml",
        Join-Path $Script:Config.DotfilesDir "common/$($Script:Config.PackagesFile)",
        Join-Path $Script:Config.DotfilesDir "packages.yml"
    )
    foreach ($pf in $candidates) {
        if (Test-Path $pf) { return $pf }
    }
    return $null
}

# System configuration functions
function Set-WindowsConfiguration {
    param(
        [string]$PackagesFile
    )
    
    Write-Header "Configuring Windows Settings"
    
    if (-not $PackagesFile -or -not (Test-Path $PackagesFile)) {
        Write-Warning "Packages file not found, skipping Windows configuration"
        return
    }
    
    try {
        # Load YAML content
        $yamlContent = Get-Content $PackagesFile -Raw | ConvertFrom-Yaml
        $registrySettings = $yamlContent.system_tweaks.windows.registry
        
        if (-not $registrySettings) {
            Write-Warning "No Windows registry settings found in packages.yml"
            return
        }
        
        Write-Info "Applying registry settings from packages.yml..."
        
        foreach ($setting in $registrySettings) {
            try {
                $path = $setting.path
                $name = $setting.name
                $value = $setting.value
                $type = $setting.type
                $description = $setting.description
                
                Write-Info "Setting: $description"
                
                # Ensure the registry path exists
                $pathParts = $path -split '\\'
                $currentPath = $pathParts[0]
                for ($i = 1; $i -lt $pathParts.Length; $i++) {
                    $currentPath = "$currentPath\$($pathParts[$i])"
                    if (-not (Test-Path $currentPath)) {
                        New-Item -Path $currentPath -Force | Out-Null
                    }
                }
                
                # Set the registry value
                Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -Force
                Write-Success "Applied: $description"
                
            } catch {
                Write-Warning "Failed to apply setting '$($setting.description)': $_"
            }
        }
        
        Write-Success "Windows configuration applied"
        
        # Restart explorer to apply changes
        Write-Info "Restarting Windows Explorer..."
        Stop-Process -Name explorer -Force
        Start-Process explorer.exe
        
    } catch {
        Write-Warning "Failed to process Windows configuration: $_"
    }
}

function Enable-WindowsFeatures {
    param(
        [string]$PackagesFile
    )
    
    Write-Header "Enabling Windows Features"
    
    if (-not $PackagesFile -or -not (Test-Path $PackagesFile)) {
        Write-Warning "Packages file not found, skipping Windows features"
        return
    }
    
    try {
        # Load YAML content
        $yamlContent = Get-Content $PackagesFile -Raw | ConvertFrom-Yaml
        $features = $yamlContent.system_tweaks.windows.features
        
        if (-not $features) {
            Write-Warning "No Windows features found in packages.yml"
            return
        }
        
        foreach ($feature in $features) {
            $featureName = $feature.name
            $description = $feature.description
            $requiresAdmin = $feature.requires_admin
            
            if ($requiresAdmin -and -not (Test-IsAdmin)) {
                Write-Warning "Skipping '$description' - requires administrator privileges"
                continue
            }
            
            try {
                Write-Info "Enabling: $description"
                dism.exe /online /enable-feature /featurename:$featureName /all /norestart
                Write-Success "Enabled: $description"
            } catch {
                Write-Warning "Failed to enable '$description': $_"
            }
        }
        
        Write-Success "Windows features processing complete (restart may be required)"
        
    } catch {
        Write-Warning "Failed to process Windows features: $_"
    }
}

function Install-PowerShellProfile {
    Write-Header "Setting up PowerShell Profile"
    
    $documentsPath = [System.Environment]::GetFolderPath('MyDocuments')
    $powerShellProfileDir = "$documentsPath\PowerShell"
    $profilePath = "$powerShellProfileDir\Microsoft.PowerShell_profile.ps1"
    
    Write-Info "PowerShell profile directory: $powerShellProfileDir"
    
    if (-not (Test-Path $powerShellProfileDir)) {
        New-Item -ItemType Directory -Path $powerShellProfileDir -Force | Out-Null
        Write-Success "Created PowerShell profile directory"
    }
    
    # Copy profile from dotfiles if it exists
    $dotfilesProfile = "$($Script:Config.DotfilesDir)\windows\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    if (Test-Path $dotfilesProfile) {
        Copy-Item $dotfilesProfile $profilePath -Force
        Write-Success "PowerShell profile installed from dotfiles"
    } else {
        Write-Warning "PowerShell profile not found in dotfiles"
    }
}

# Main execution function
function Start-Bootstrap {
    param([string]$Profile, [switch]$Force, [switch]$Ask)
    
    Write-Header "Windows Dotfiles Bootstrap"
    Write-Info "Profile: $Profile"
    Write-Info "Force mode: $Force"
    Write-Info "Interactive mode: $Ask"
    
    # Initialize logging
    $logDir = Split-Path $Script:Config.LogFile
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    Write-Log "Bootstrap started with profile: $Profile"

    # Set Ask preference for all prompts
    $Script:AskPreference = [bool]$Ask
    
    # Check dependencies
    Write-Header "Checking Dependencies"
    $requiredCommands = @("git", "powershell")
    $missingCommands = @()
    
    foreach ($cmd in $requiredCommands) {
        if (-not (Test-CommandExists $cmd)) {
            $missingCommands += $cmd
            Write-Error "Required command not found: $cmd"
        } else {
            Write-Success "Found: $cmd"
        }
    }
    
    if ($missingCommands.Count -gt 0) {
        Write-Error "Missing required dependencies. Please install: $($missingCommands -join ', ')"
        return $false
    }
    
    # Install package manager (skippable)
    if (Prompt-YesNo -Question "Install/check package manager?" -Default 'Y') {
        if (-not (Install-PackageManager)) {
            Write-Error "Failed to install package manager"
            return $false
        }
    } else {
        Write-Warning "Skipped package manager step by user choice"
    }
    
    # Install dotfiles
    if (Prompt-YesNo -Question "Install or update dotfiles?" -Default 'Y') {
        if (-not (Install-Dotfiles)) {
            Write-Error "Failed to install dotfiles"
            return $false
        }
    } else {
        Write-Warning "Skipped dotfiles installation by user choice"
    }
    
    # Get packages file (profile-aware)
    $packagesFile = Get-ProfilePackagesFile -Profile $Profile
    if (-not $packagesFile) {
        Write-Error "Failed to get packages file for profile '$Profile'"
        return $false
    }
    
    # Install packages
    if (Prompt-YesNo -Question "Install profile packages?" -Default 'Y') {
        Install-Packages -PackagesFile $packagesFile -Profile $Profile
    } else {
        Write-Warning "Skipped package installation by user choice"
    }
    
    # Set up PowerShell profile
    if (Prompt-YesNo -Question "Install PowerShell profile?" -Default 'Y') {
        Install-PowerShellProfile
    } else {
        Write-Warning "Skipped PowerShell profile setup by user choice"
    }
    
    # Deploy dotfiles
    if (Prompt-YesNo -Question "Deploy dotfiles to system locations?" -Default 'Y') {
        if (-not (Deploy-Dotfiles)) {
            Write-Error "Failed to deploy dotfiles"
            return $false
        }
    } else {
        Write-Warning "Skipped dotfiles deployment by user choice"
    }
    
    # Configure Windows
    if (Prompt-YesNo -Question "Apply Windows configuration from packages.yml?" -Default 'N') {
        Set-WindowsConfiguration -PackagesFile $packagesFile
    } else {
        Write-Warning "Skipped Windows configuration by user choice"
    }
    
    # Enable Windows features (if admin)
    if (Prompt-YesNo -Question "Enable Windows optional features?" -Default 'N') {
        Enable-WindowsFeatures -PackagesFile $packagesFile
    } else {
        Write-Warning "Skipped enabling Windows features by user choice"
    }
    
    Write-Header "Bootstrap Complete"
    Write-Success "Windows dotfiles bootstrap completed successfully!"
    Write-Info "Please restart your computer to apply all changes."
    Write-Log "Bootstrap completed successfully"
    
    return $true
}

# Help function
function Show-Help {
    Write-Host @"
Windows Dotfiles Bootstrap Script

USAGE:
    .\bootstrap.ps1 [-Profile <profile>] [-Force] [-Ask] [-Help]

PARAMETERS:
    -Profile <string>   Installation profile (default: essentials)
                       Available: essentials, minimal, dev, server, full, or a custom profile.
                       Custom profile files are resolved from:
                         - %USERPROFILE%\.cfg\profile\<name>\packages.yml
                         - %USERPROFILE%\profile\<name>\packages.yml
                         - %USERPROFILE%\dot_setup\profile\<name>\packages.yml
    -Force             Force installation without prompts
    -Ask               Interactive mode with step-by-step prompts  
    -Help              Show this help message

EXAMPLES:
    .\bootstrap.ps1                          # Install with essentials profile
    .\bootstrap.ps1 -Profile dev             # Install development profile
    .\bootstrap.ps1 -Profile full -Force     # Force install full profile
    .\bootstrap.ps1 -Ask                     # Interactive installation

"@ -ForegroundColor Cyan
}

# Script entry point
if ($Help) {
    Show-Help
    exit 0
}

# Run bootstrap
try {
    $result = Start-Bootstrap -Profile $Profile -Force:$Force -Ask:$Ask
    if (-not $result) {
        exit 1
    }
} catch {
    Write-Error "Bootstrap failed: $_"
    Write-Log "Bootstrap failed: $_" "ERROR"
    exit 1
}
