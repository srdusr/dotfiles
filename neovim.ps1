# Neovim Installation Script for Windows (PowerShell)
# Created By: srdusr (PowerShell port)
# Project: Install/update/uninstall/change version Neovim script for Windows

#Requires -Version 5.1

param(
    [switch]$Force,
    [switch]$NoPrompt
)

# Color definitions
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Cyan = "Cyan"
}

# Global variables
$Script:DownloadCommand = $null
$Script:IsAdmin = $false
$Script:ShowPrompt = $true
$Script:NeovimPath = "$env:LOCALAPPDATA\nvim"
$Script:NeovimBin = "$Script:NeovimPath\bin"
$Script:NeovimExe = "$Script:NeovimBin\nvim.exe"

# Handle errors
function Write-ErrorMessage {
    param([string]$Message)
    Write-Host "Error: $Message" -ForegroundColor $Colors.Red
}

# Handle success messages
function Write-SuccessMessage {
    param([string]$Message)
    Write-Host $Message -ForegroundColor $Colors.Green
}

# Handle info messages
function Write-InfoMessage {
    param([string]$Message)
    Write-Host $Message -ForegroundColor $Colors.Cyan
}

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if necessary dependencies are installed
function Test-Dependencies {
    Write-InfoMessage "Checking dependencies..."
    
    # Check for download tools
    if (Get-Command curl -ErrorAction SilentlyContinue) {
        $Script:DownloadCommand = "curl"
        Write-InfoMessage "Found curl"
    } elseif (Get-Command wget -ErrorAction SilentlyContinue) {
        $Script:DownloadCommand = "wget"
        Write-InfoMessage "Found wget"
    } else {
        Write-InfoMessage "Neither curl nor wget found. Will use PowerShell's Invoke-WebRequest"
        $Script:DownloadCommand = "powershell"
    }

    # Check for admin privileges
    $Script:IsAdmin = Test-Administrator
    if (-not $Script:IsAdmin) {
        Write-Host "Warning: Not running as administrator. Some operations may fail." -ForegroundColor $Colors.Yellow
        if (-not $NoPrompt) {
            $continue = Read-Host "Continue anyway? (y/n)"
            if ($continue -notin @('y', 'yes', 'Y', 'Yes')) {
                exit 1
            }
        }
    }

    return $true
}

# Find all Neovim installations
function Find-AllNeovimInstallations {
    $installations = @()
    
    # Check common installation paths
    $commonPaths = @(
        "$env:LOCALAPPDATA\nvim",
        "$env:ProgramFiles\Neovim",
        "$env:ProgramFiles(x86)\Neovim",
        "$env:APPDATA\nvim",
        "$env:USERPROFILE\nvim",
        "C:\tools\neovim",
        "C:\neovim"
    )
    
    foreach ($path in $commonPaths) {
        # Check for nvim.exe in bin subdirectory
        if (Test-Path "$path\bin\nvim.exe") {
            $installations += @{
                Path = $path
                BinPath = "$path\bin"
                Type = "Portable"
                Version = Get-NeovimVersion -Path "$path\bin\nvim.exe"
            }
        }
        # Check for nvim.exe directly in path
        elseif (Test-Path "$path\nvim.exe") {
            $installations += @{
                Path = $path
                BinPath = $path
                Type = "Portable"
                Version = Get-NeovimVersion -Path "$path\nvim.exe"
            }
        }
        # Check for nvim-win64 subdirectory (common structure)
        elseif (Test-Path "$path\nvim-win64\bin\nvim.exe") {
            $installations += @{
                Path = "$path\nvim-win64"
                BinPath = "$path\nvim-win64\bin"
                Type = "Portable"
                Version = Get-NeovimVersion -Path "$path\nvim-win64\bin\nvim.exe"
            }
        }
    }
    
    # Check for MSI installations in registry
    try {
        $uninstallKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        
        foreach ($keyPath in $uninstallKeys) {
            Get-ItemProperty $keyPath -ErrorAction SilentlyContinue | Where-Object { 
                $_.DisplayName -like "*Neovim*" -or $_.DisplayName -like "*nvim*" 
            } | ForEach-Object {
                $installations += @{
                    Path = $_.InstallLocation
                    BinPath = "$($_.InstallLocation)\bin"
                    Type = "MSI"
                    Version = $_.DisplayVersion
                    UninstallString = $_.UninstallString
                    ProductCode = $_.PSChildName
                }
            }
        }
    }
    catch {
        Write-InfoMessage "Could not check registry for MSI installations"
    }
    
    # Check PATH for nvim.exe - this is crucial for detecting installations
    $pathDirs = $env:PATH -split ';' | Where-Object { $_ -ne "" }
    foreach ($dir in $pathDirs) {
        $dir = $dir.Trim()
        if (Test-Path "$dir\nvim.exe") {
            # Determine the installation root
            $installRoot = $dir
            if ($dir -like "*\bin") {
                $installRoot = Split-Path -Parent $dir
            }
            
            # Check if we already found this installation
            $alreadyFound = $false
            foreach ($existing in $installations) {
                if ($existing.Path -eq $installRoot -or $existing.BinPath -eq $dir) {
                    $alreadyFound = $true
                    break
                }
            }
            
            if (-not $alreadyFound) {
                $installations += @{
                    Path = $installRoot
                    BinPath = $dir
                    Type = "PATH"
                    Version = Get-NeovimVersion -Path "$dir\nvim.exe"
                }
            }
        }
    }
    
    return $installations
}

# Get Neovim version from executable
function Get-NeovimVersion {
    param([string]$Path)
    
    try {
        $versionOutput = & $Path --version 2>$null | Select-String "NVIM v(\d+\.\d+\.\d+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }
        return $versionOutput
    }
    catch {
        return "Unknown"
    }
}

# Complete uninstall of all Neovim instances
function Uninstall-AllNeovim {
    param([switch]$Silent)
    
    Write-InfoMessage "Searching for all Neovim installations..."
    $installations = Find-AllNeovimInstallations
    
    if ($installations.Count -eq 0) {
        Write-InfoMessage "No Neovim installations found."
        return $true
    }
    
    if (-not $Silent) {
        Write-Host "Found $($installations.Count) Neovim installation(s):" -ForegroundColor $Colors.Yellow
        for ($i = 0; $i -lt $installations.Count; $i++) {
            Write-Host "  $($i + 1). $($installations[$i].Type) - $($installations[$i].Path) (v$($installations[$i].Version))"
        }
        
        if (-not $NoPrompt) {
            $confirm = Read-Host "Remove all installations? (y/n)"
            if ($confirm -notin @('y', 'yes', 'Y', 'Yes')) {
                Write-InfoMessage "Uninstall cancelled."
                return $false
            }
        }
    }
    
    $success = $true
    foreach ($installation in $installations) {
        Write-InfoMessage "Removing $($installation.Type) installation: $($installation.Path)"
        
        try {
            if ($installation.Type -eq "MSI") {
                # Uninstall MSI package
                if ($installation.UninstallString) {
                    if ($installation.UninstallString -like "*msiexec*") {
                        # Extract the product code from the uninstall string
                        $productCode = $installation.ProductCode
                        if ($productCode -and $productCode -match "^\{.*\}$") {
                            $uninstallArgs = "/x `"$productCode`" /quiet /norestart"
                            Write-InfoMessage "Uninstalling MSI with product code: $productCode"
                            Start-Process -FilePath "msiexec.exe" -ArgumentList $uninstallArgs -Wait -NoNewWindow
                        } else {
                            # Fallback to parsing the uninstall string
                            $uninstallArgs = $installation.UninstallString -replace "MsiExec.exe", "" -replace "/I\{", "/x{"
                            $uninstallArgs += " /quiet /norestart"
                            Write-InfoMessage "Uninstalling MSI with args: $uninstallArgs"
                            Start-Process -FilePath "msiexec.exe" -ArgumentList $uninstallArgs -Wait -NoNewWindow
                        }
                    } else {
                        # Direct uninstall command
                        Write-InfoMessage "Running uninstall command: $($installation.UninstallString)"
                        Invoke-Expression $installation.UninstallString
                    }
                    
                    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
                        Write-SuccessMessage "Successfully uninstalled MSI package"
                    } else {
                        Write-ErrorMessage "MSI uninstall failed with exit code: $LASTEXITCODE"
                        $success = $false
                    }
                } else {
                    Write-ErrorMessage "No uninstall string found for MSI package"
                    $success = $false
                }
            } else {
                # Remove portable installation
                if (Test-Path $installation.Path) {
                    Write-InfoMessage "Removing directory: $($installation.Path)"
                    # Force kill any processes that might be using files in the directory
                    Get-Process -Name "nvim*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                    
                    # Try to remove the directory
                    Remove-Item -Path $installation.Path -Recurse -Force -ErrorAction Stop
                    Write-SuccessMessage "Successfully removed directory: $($installation.Path)"
                } else {
                    Write-InfoMessage "Directory already removed: $($installation.Path)"
                }
            }
        }
        catch {
            Write-ErrorMessage "Failed to remove $($installation.Path): $_"
            # Try alternative removal methods
            try {
                Write-InfoMessage "Attempting alternative removal method..."
                if (Test-Path $installation.Path) {
                    # Use robocopy to move and delete (works around file locks)
                    $tempDir = "$env:TEMP\nvim_removal_$(Get-Random)"
                    robocopy "$($installation.Path)" "$tempDir" /E /MOVE /NFL /NDL /NJH /NJS /NC /NS /NP
                    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                    Write-SuccessMessage "Successfully removed using alternative method: $($installation.Path)"
                }
            }
            catch {
                Write-ErrorMessage "Alternative removal also failed: $_"
                $success = $false
            }
        }
    }
    
    # Clean up PATH environment variable
    Write-InfoMessage "Cleaning up PATH environment variable..."
    
    # Get both user and system PATH
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $systemPath = ""
    
    if ($Script:IsAdmin) {
        try {
            $systemPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        }
        catch {
            Write-InfoMessage "Could not access system PATH"
        }
    }
    
    # Create patterns for all found installations
    $nvimPathPatterns = @()
    foreach ($installation in $installations) {
        $nvimPathPatterns += [regex]::Escape($installation.BinPath)
        $nvimPathPatterns += [regex]::Escape($installation.Path)
    }
    
    # Add common patterns
    $nvimPathPatterns += @(
        [regex]::Escape($Script:NeovimBin),
        [regex]::Escape("$env:ProgramFiles\Neovim\bin"),
        [regex]::Escape("$env:ProgramFiles(x86)\Neovim\bin"),
        [regex]::Escape("C:\tools\neovim\nvim-win64\bin"),
        [regex]::Escape("C:\tools\neovim\nvim-win64")
    )
    
    # Clean user PATH
    $originalUserPath = $userPath
    foreach ($pattern in $nvimPathPatterns) {
        $userPath = $userPath -replace ";$pattern;", ";"
        $userPath = $userPath -replace "^$pattern;", ""
        $userPath = $userPath -replace ";$pattern$", ""
        $userPath = $userPath -replace "^$pattern$", ""
    }
    
    if ($userPath -ne $originalUserPath) {
        try {
            [Environment]::SetEnvironmentVariable("PATH", $userPath, "User")
            Write-InfoMessage "Cleaned up user PATH"
        }
        catch {
            Write-ErrorMessage "Failed to clean up user PATH: $_"
        }
    }
    
    # Clean system PATH if running as admin
    if ($Script:IsAdmin -and $systemPath) {
        $originalSystemPath = $systemPath
        foreach ($pattern in $nvimPathPatterns) {
            $systemPath = $systemPath -replace ";$pattern;", ";"
            $systemPath = $systemPath -replace "^$pattern;", ""
            $systemPath = $systemPath -replace ";$pattern$", ""
            $systemPath = $systemPath -replace "^$pattern$", ""
        }
        
        if ($systemPath -ne $originalSystemPath) {
            try {
                [Environment]::SetEnvironmentVariable("PATH", $systemPath, "Machine")
                Write-InfoMessage "Cleaned up system PATH"
            }
            catch {
                Write-ErrorMessage "Failed to clean up system PATH: $_"
            }
        }
    }
    
    if ($success) {
        Write-SuccessMessage "All Neovim installations have been removed successfully!"
    } else {
        Write-Host "Some installations could not be removed completely." -ForegroundColor $Colors.Yellow
    }
    
    Write-InfoMessage "You may need to restart your shell for PATH changes to take effect."
    return $success
}

# Check if Neovim is already installed
function Test-NeovimInstalled {
    if (Test-Path $Script:NeovimExe) {
        return $true
    }
    
    # Check if nvim is in PATH
    if (Get-Command nvim -ErrorAction SilentlyContinue) {
        return $true
    }
    
    return $false
}

# Download a file - FIXED VERSION
function Get-FileDownload {
    param(
        [string]$Url,
        [string]$OutputPath
    )

    Write-InfoMessage "Downloading from: $Url"
    Write-InfoMessage "Saving to: $OutputPath"

    try {
        switch ($Script:DownloadCommand) {
            "curl" {
                # Use Start-Process instead of cmd /c for better compatibility
                $curlArgs = @("-L", "--progress-bar", "-o", $OutputPath, $Url)
                $process = Start-Process -FilePath "curl" -ArgumentList $curlArgs -Wait -NoNewWindow -PassThru
                if ($process.ExitCode -ne 0) { 
                    throw "Curl download failed with exit code: $($process.ExitCode)" 
                }
            }
            "wget" {
                # Use Start-Process instead of cmd /c for better compatibility
                $wgetArgs = @("--progress=bar", "--show-progress", "-O", $OutputPath, $Url)
                $process = Start-Process -FilePath "wget" -ArgumentList $wgetArgs -Wait -NoNewWindow -PassThru
                if ($process.ExitCode -ne 0) { 
                    throw "Wget download failed with exit code: $($process.ExitCode)" 
                }
            }
            "powershell" {
                # Enhanced PowerShell download with progress
                Write-InfoMessage "Using PowerShell's Invoke-WebRequest..."
                $ProgressPreference = 'Continue'
                
                # Create a WebClient for better progress reporting
                $webClient = New-Object System.Net.WebClient
                $webClient.Headers.Add("User-Agent", "PowerShell Neovim Installer")
                
                # Register progress event
                Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action {
                    $Global:DownloadProgress = $Event.SourceEventArgs.ProgressPercentage
                    Write-Progress -Activity "Downloading Neovim" -Status "Progress: $($Event.SourceEventArgs.ProgressPercentage)%" -PercentComplete $Event.SourceEventArgs.ProgressPercentage
                } | Out-Null
                
                # Download the file
                try {
                    $webClient.DownloadFile($Url, $OutputPath)
                    Write-Progress -Activity "Downloading Neovim" -Completed
                }
                finally {
                    $webClient.Dispose()
                    # Clean up event handlers
                    Get-EventSubscriber | Where-Object { $_.SourceObject -eq $webClient } | Unregister-Event
                }
            }
        }
        
        # Verify the file was downloaded
        if (-not (Test-Path $OutputPath)) {
            throw "Downloaded file not found at: $OutputPath"
        }
        
        $fileSize = (Get-Item $OutputPath).Length
        if ($fileSize -eq 0) {
            throw "Downloaded file is empty"
        }
        
        Write-InfoMessage "Download completed successfully. File size: $($fileSize / 1MB) MB"
        return $true
    }
    catch {
        Write-ErrorMessage "Download failed: $_"
        # Clean up partial download
        if (Test-Path $OutputPath) {
            Remove-Item -Path $OutputPath -Force -ErrorAction SilentlyContinue
        }
        return $false
    }
}

# Get available versions from GitHub API
function Get-AvailableVersions {
    try {
        $apiUrl = "https://api.github.com/repos/neovim/neovim/releases"
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        return $response | ForEach-Object { $_.tag_name }
    }
    catch {
        Write-ErrorMessage "Failed to fetch available versions: $_"
        return @()
    }
}

# Check if a specific version exists
function Test-VersionExists {
    param([string]$Version)
    
    if ($Version -notmatch "^v") {
        $Version = "v$Version"
    }
    
    $versions = Get-AvailableVersions
    return $versions -contains $Version
}

# Get the latest stable version
function Get-LatestStableVersion {
    try {
        $apiUrl = "https://api.github.com/repos/neovim/neovim/releases/latest"
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        return $response.tag_name
    }
    catch {
        Write-ErrorMessage "Failed to fetch latest version: $_"
        return $null
    }
}

# Download specific version
function Get-SpecificVersion {
    param([string]$Version)
    
    if ($Version -notmatch "^v") {
        $Version = "v$Version"
    }
    
    try {
        $apiUrl = "https://api.github.com/repos/neovim/neovim/releases/tags/$Version"
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        
        # Look for Windows assets
        $asset = $response.assets | Where-Object { 
            $_.name -match "nvim-win64\.zip$" -or 
            $_.name -match "nvim-win64\.msi$" -or
            $_.name -match "nvim-windows\.zip$"
        } | Select-Object -First 1
        
        if (-not $asset) {
            Write-ErrorMessage "No Windows asset found for version ${Version}"
            return $null
        }
        
        $fileName = $asset.name
        $downloadUrl = $asset.browser_download_url
        
        Write-InfoMessage "Found asset: $fileName"
        
        if (Get-FileDownload -Url $downloadUrl -OutputPath $fileName) {
            return $fileName
        }
    }
    catch {
        Write-ErrorMessage "Failed to download version ${Version}: $_"
    }
    
    return $null
}

# Install Neovim from downloaded file
function Install-NeovimFromFile {
    param(
        [string]$FilePath,
        [string]$Version = "Unknown",
        [switch]$CleanInstall
    )
    
    try {
        if ($CleanInstall) {
            Write-InfoMessage "Performing clean installation - removing existing installations..."
            Uninstall-AllNeovim -Silent
        }
        
        Write-InfoMessage "Installing Neovim ${Version}..."
        
        $fileExtension = [System.IO.Path]::GetExtension($FilePath).ToLower()
        
        if ($fileExtension -eq ".msi") {
            # Handle MSI installation
            Write-InfoMessage "Installing from MSI package..."
            $installArgs = @(
                "/i", "`"$FilePath`""
                "/quiet"
                "/norestart"
            )
            
            Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -NoNewWindow
            
            if ($LASTEXITCODE -eq 0) {
                Write-SuccessMessage "Neovim ${Version} installed successfully via MSI!"
                
                # MSI typically installs to Program Files, add to PATH if needed
                $programFiles = "${env:ProgramFiles}\Neovim\bin"
                $programFilesX86 = "${env:ProgramFiles(x86)}\Neovim\bin"
                
                $nvimPath = ""
                if (Test-Path "$programFiles\nvim.exe") {
                    $nvimPath = $programFiles
                } elseif (Test-Path "$programFilesX86\nvim.exe") {
                    $nvimPath = $programFilesX86
                }
                
                if ($nvimPath) {
                    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
                    if ($currentPath -notlike "*$nvimPath*") {
                        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$nvimPath", "User")
                        Write-InfoMessage "Added Neovim to PATH: $nvimPath"
                    }
                }
            } else {
                Write-ErrorMessage "MSI installation failed with exit code: $LASTEXITCODE"
                return $false
            }
        }
        elseif ($fileExtension -eq ".zip") {
            # Handle ZIP installation
            Write-InfoMessage "Installing from ZIP archive..."
            
            # Create installation directory
            if (Test-Path $Script:NeovimPath) {
                Remove-Item -Path $Script:NeovimPath -Recurse -Force
            }
            New-Item -Path $Script:NeovimPath -ItemType Directory -Force | Out-Null
            
            # Extract zip file
            Write-InfoMessage "Extracting archive..."
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($FilePath, $Script:NeovimPath)
            
            # Find the nvim.exe in the extracted files
            $nvimExe = Get-ChildItem -Path $Script:NeovimPath -Name "nvim.exe" -Recurse | Select-Object -First 1
            if (-not $nvimExe) {
                Write-ErrorMessage "Could not find nvim.exe in extracted files"
                return $false
            }
            
            $nvimDir = Split-Path -Path (Get-ChildItem -Path $Script:NeovimPath -Name "nvim.exe" -Recurse | Select-Object -First 1).FullName
            
            # Move files to proper location if needed
            if ($nvimDir -ne $Script:NeovimBin) {
                if (Test-Path $Script:NeovimBin) {
                    Remove-Item -Path $Script:NeovimBin -Recurse -Force
                }
                Move-Item -Path $nvimDir -Destination $Script:NeovimBin -Force
            }
            
            # Add to PATH if not already there
            $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
            if ($currentPath -notlike "*$Script:NeovimBin*") {
                [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$Script:NeovimBin", "User")
                Write-InfoMessage "Added Neovim to PATH"
            }
            
            Write-SuccessMessage "Neovim ${Version} installed successfully!"
            Write-InfoMessage "Location: $Script:NeovimBin"
        }
        else {
            Write-ErrorMessage "Unsupported file type: $fileExtension"
            return $false
        }
        
        # Clean up downloaded file
        Remove-Item -Path $FilePath -Force -ErrorAction SilentlyContinue
        
        Write-InfoMessage "You may need to restart your shell for PATH changes to take effect."
        return $true
    }
    catch {
        Write-ErrorMessage "Installation failed: $_"
        return $false
    }
}

# Install nightly version
function Install-NightlyVersion {
    param([switch]$CleanInstall)
    
    Write-InfoMessage "Installing Neovim Nightly..."
    $url = "https://github.com/neovim/neovim/releases/download/nightly/nvim-win64.zip"
    $fileName = "nvim-nightly.zip"
    
    if (Get-FileDownload -Url $url -OutputPath $fileName) {
        return Install-NeovimFromFile -FilePath $fileName -Version "Nightly" -CleanInstall:$CleanInstall
    }
    return $false
}

# Install stable version
function Install-StableVersion {
    param([switch]$CleanInstall)
    
    Write-InfoMessage "Installing Neovim Stable..."
    $latestVersion = Get-LatestStableVersion
    if (-not $latestVersion) {
        Write-ErrorMessage "Could not determine latest stable version"
        return $false
    }
    
    $fileName = Get-SpecificVersion -Version $latestVersion
    if ($fileName) {
        return Install-NeovimFromFile -FilePath $fileName -Version "Stable ($latestVersion)" -CleanInstall:$CleanInstall
    }
    return $false
}

# Install specific version
function Install-SpecificVersionWrapper {
    param(
        [string]$Version,
        [switch]$CleanInstall
    )
    
    Write-InfoMessage "Installing Neovim ${Version}..."
    
    if (-not (Test-VersionExists -Version $Version)) {
        Write-ErrorMessage "Version ${Version} does not exist"
        return $false
    }
    
    $fileName = Get-SpecificVersion -Version $Version
    if ($fileName) {
        return Install-NeovimFromFile -FilePath $fileName -Version $Version -CleanInstall:$CleanInstall
    }
    return $false
}

# Update/Install version menu
function Show-UpdateMenu {
    # Check if there are existing installations
    $installations = Find-AllNeovimInstallations
    $hasExistingInstalls = $installations.Count -gt 0
    
    if ($hasExistingInstalls) {
        Write-Host "Existing Neovim installations found:" -ForegroundColor $Colors.Yellow
        for ($i = 0; $i -lt $installations.Count; $i++) {
            Write-Host "  - $($installations[$i].Type) - $($installations[$i].Path) (v$($installations[$i].Version))"
        }
        Write-Host ""
        
        if (-not $NoPrompt) {
            $cleanInstall = Read-Host "Perform clean installation (remove existing installations)? (y/n)"
            $shouldClean = $cleanInstall -in @('y', 'yes', 'Y', 'Yes')
        } else {
            $shouldClean = $true
        }
    } else {
        $shouldClean = $false
    }
    
    $validChoice = $false
    while (-not $validChoice) {
        Write-Host ""
        Write-Host "Select version to install/update to:"
        Write-Host "  1. Nightly"
        Write-Host "  2. Stable"
        Write-Host "  3. Choose specific version by tag"
        
        $choice = Read-Host "Enter the number corresponding to your choice (1/2/3)"
        
        switch ($choice) {
            "1" {
                $result = Install-NightlyVersion -CleanInstall:$shouldClean
                $validChoice = $true
				$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
            }
            "2" {
                $result = Install-StableVersion -CleanInstall:$shouldClean
                $validChoice = $true
				$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
            }
            "3" {
                $version = Read-Host "Enter the specific version (e.g., v0.9.0)"
                $result = Install-SpecificVersionWrapper -Version $version -CleanInstall:$shouldClean
                $validChoice = $true
				$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
            }
            default {
                Write-ErrorMessage "Invalid choice. Please enter 1, 2, or 3."
            }
        }
    }
    
    return $result
}

# Uninstall Neovim (wrapper for backward compatibility)
function Uninstall-Neovim {
    return Uninstall-AllNeovim
}

# Check if Neovim is running
function Test-NeovimRunning {
    $nvimProcesses = Get-Process -Name "nvim" -ErrorAction SilentlyContinue
    if ($nvimProcesses) {
        Write-Host "Error: Neovim is currently running. Please close Neovim before proceeding." -ForegroundColor $Colors.Red
        
        if (-not $NoPrompt) {
            $choice = Read-Host "Do you want to forcefully terminate Neovim and continue? (y/n)"
            if ($choice -in @('y', 'yes', 'Y', 'Yes')) {
                $nvimProcesses | Stop-Process -Force
                Write-InfoMessage "Neovim processes terminated"
            } else {
                Write-InfoMessage "Exiting..."
                exit 1
            }
        } else {
            $nvimProcesses | Stop-Process -Force
            Write-InfoMessage "Neovim processes terminated"
        }
    }
}

# Check for updates
function Test-Updates {
    Write-InfoMessage "Checking for updates..."
    
    try {
        $latestVersion = Get-LatestStableVersion
        if (-not $latestVersion) {
            Write-ErrorMessage "Could not fetch latest version information"
            return
        }
        
        Write-InfoMessage "Latest stable version: $latestVersion"
        
        $installations = Find-AllNeovimInstallations
        if ($hasExistingInstalls) {
            Write-InfoMessage "Found $($installations.Count) installation(s):"
            foreach ($installation in $installations) {
                Write-InfoMessage "  - $($installation.Type): v$($installation.Version) at $($installation.Path)"
                if ($installation.Version -ne "Unknown" -and "v$($installation.Version)" -ne $latestVersion) {
                    Write-SuccessMessage "    Update available: v$($installation.Version) → $latestVersion"
                } elseif ("v$($installation.Version)" -eq $latestVersion) {
                    Write-InfoMessage "    Up to date"
                }
            }
        } else {
            Write-InfoMessage "Neovim is not installed"
        }
    }
    catch {
        Write-ErrorMessage "Failed to check for updates: $_"
    }
}

# Main function
function Main {
    Write-Host "Neovim Installation Script for Windows" -ForegroundColor $Colors.Cyan
    Write-Host "=======================================" -ForegroundColor $Colors.Cyan
    
    # Check dependencies
    if (-not (Test-Dependencies)) {
        exit 1
    }
    
    # Check if Neovim is running
    Test-NeovimRunning
    
    # Check if Neovim is installed
    $installations = Find-AllNeovimInstallations
    if ($installations.Count -gt 0) {
        Write-SuccessMessage "Found $($installations.Count) Neovim installation(s):"
        foreach ($installation in $installations) {
            Write-InfoMessage "  - $($installation.Type): v$($installation.Version) at $($installation.Path)"
        }
    } else {
        Write-Host "Neovim is not installed." -ForegroundColor $Colors.Red
        if (-not $NoPrompt) {
            $choice = Read-Host "Install Neovim? (y/n)"
            if ($choice -in @('y', 'yes', 'Y', 'Yes')) {
                Show-UpdateMenu
                return
            } else {
                Write-InfoMessage "Exiting..."
                return
            }
        }
    }
    
    # Main menu loop
    while ($Script:ShowPrompt) {
        Write-Host ""
        Write-Host "Select an option:"
        Write-Host "  1. Install/update Neovim"
        Write-Host "  2. Check for updates"
        Write-Host "  3. Uninstall all Neovim installations"
        Write-Host "  4. Run Neovim"
        Write-Host "  5. Quit"
        
        $choice = Read-Host "Enter a number or press 'q' to quit"
        
        switch ($choice) {
            "1" {
                Show-UpdateMenu
            }
            "2" {
                Test-Updates
            }
            "3" {
                Uninstall-AllNeovim
            }
            "4" {
                if ($installations.Count -gt 0 -or (Get-Command nvim -ErrorAction SilentlyContinue)) {
                    Write-InfoMessage "Starting Neovim..."
                    & nvim
                } else {
                    Write-ErrorMessage "Neovim is not installed"
                }
            }
            { $_ -in @("5", "q", "Q", "quit", "exit") } {
                Write-InfoMessage "Exiting..."
                $Script:ShowPrompt = $false
            }
            default {
                Write-ErrorMessage "Invalid choice. Please choose a valid option by entering the corresponding number or press 'q' to quit."
            }
        }
    }
}

# Run the main function
Main
