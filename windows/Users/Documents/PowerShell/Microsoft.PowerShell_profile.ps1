# Dotfiles Management System
if (Test-Path "$HOME\.cfg" -and Test-Path "$HOME\.cfg\refs") {

    # Core git wrapper with repository as work-tree
    function _config {
        param(
            [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
            [String[]]$Args
        )
        git --git-dir="$HOME\.cfg" --work-tree="$HOME\.cfg" @Args
    }

    # Detect OS (cross-platform, PowerShell-native)
    $osPlatform = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform
    if ($osPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
        $global:CFG_OS = "windows"
    } elseif ($osPlatform([System.Runtime.InteropServices.OSPlatform]::Linux)) {
        $global:CFG_OS = "linux"
    } elseif ($osPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)) {
        $global:CFG_OS = "macos"
    } else {
        $global:CFG_OS = "other"
    }

    # Map system path to repository path
    function _repo_path {
        param([string]$FilePath)

        # If it's an absolute path that's not in HOME, handle it specially
        if (($FilePath.StartsWith("\\") -or $FilePath.Contains(":")) -and -not $FilePath.StartsWith($HOME)) {
            return "$CFG_OS/" + ($FilePath -replace '^[A-Z]:\\', '' -replace '\\', '/')
        }

        # Check for paths that should go to the repository root
        if ($FilePath -match '^(common|linux|macos|windows|profile)/.*|^README\.md$') {
            return $FilePath -replace '\\', '/'
        }

        # Remove HOME prefix if present
        if ($FilePath.StartsWith($HOME)) {
            $FilePath = $FilePath.Substring($HOME.Length + 1)
        }

        # Default: put under OS-specific home
        return "$CFG_OS/home/" + ($FilePath -replace '\\', '/')
    }

    # Map repository path back to system path
    function _sys_path {
        param([string]$RepoPath)

        $osPathPattern = "$CFG_OS/"
        
        # Handle OS-specific files that are not in the home subdirectory
        if ($RepoPath.StartsWith($osPathPattern) -and $RepoPath -notmatch '/home/') {
            return ($RepoPath.Substring($osPathPattern.Length) -replace '/', '\\')
        }

        switch -Wildcard ($RepoPath) {
            "common/config/*" {
                $file = $RepoPath.Substring("common/config/".Length)
                switch ($CFG_OS) {
                    "linux" { return Join-Path ($env:XDG_CONFIG_HOME ?? "$HOME\.config") $file }
                    "macos" { return Join-Path "$HOME\Library\Application Support" $file }
                    "windows" { return Join-Path $env:LOCALAPPDATA $file }
                    default { return Join-Path "$HOME\.config" $file }
                }
            }
            "common/assets/*" { return Join-Path "$HOME\.cfg" $RepoPath }
            "common/*" { return Join-Path $HOME ($RepoPath.Substring("common/".Length)) }
            "*/home/*" { return Join-Path $HOME ($RepoPath.Substring($RepoPath.IndexOf("home/") + 5)) }
            "profile/*" { return Join-Path "$HOME\.cfg" $RepoPath }
            "README.md" { return Join-Path "$HOME\.cfg" $RepoPath }
            default { return Join-Path "$HOME\.cfg" $RepoPath }
        }
    }

    # Prompts for administrator permissions if needed and runs the command
    function _admin_prompt {
        param(
            [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
            [String[]]$Command
        )
        if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Host "Warning: This action requires administrator privileges." -ForegroundColor Yellow
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-Command", "Set-Location '$PWD'; & $Command" -Verb RunAs
        } else {
            & $Command
        }
    }

    # Main config command
    function config {
        param(
            [string]$Command,
            [string]$TargetDir = "",
            [Parameter(ValueFromRemainingArguments=$true)]
            [string[]]$Args
        )

        # Parse --target flag for add command
        if ($Command -eq "add" -and $Args.Count -gt 0) {
            $i = 0
            while ($i -lt $Args.Count) {
                if ($Args[$i] -eq "--target" -or $Args[$i] -eq "-t") {
                    if ($i + 1 -lt $Args.Count) {
                        $TargetDir = $Args[$i + 1]
                        $Args = $Args[0..($i-1)] + $Args[($i+2)..($Args.Count-1)]
                        break
                    } else {
                        Write-Host "Error: --target requires a directory argument" -ForegroundColor Red
                        return
                    }
                }
                $i++
            }
        }

        switch ($Command) {
            "add" {
                foreach ($file in $Args) {
                    if (-not $TargetDir) {
                        $repoPath = _repo_path $file
                    } else {
                        $fileName = if ($file.Contains("\\") -or $file.Contains(":")) { Split-Path $file -Leaf } else { $file }
                        $repoPath = "$TargetDir/$fileName" -replace '\\', '/'
                    }
                    
                    $fullRepoPath = Join-Path "$HOME\.cfg" $repoPath
                    $dir = Split-Path $fullRepoPath
                    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
                    Copy-Item -Path $file -Destination $fullRepoPath -Recurse -Force
                    _config add $repoPath
                    Write-Host "Added: $file -> $repoPath" -ForegroundColor Green
                }
            }
            "rm" {
                $rmOpts = @()
                $fileList = @()
                
                foreach ($arg in $Args) {
                    if ($arg.StartsWith("-")) {
                        $rmOpts += $arg
                    } else {
                        $fileList += $arg
                    }
                }
                
                foreach ($file in $fileList) {
                    $repoPath = _repo_path $file
                    if ($rmOpts -contains "-r") {
                        _config rm --cached -r $repoPath
                    } else {
                        _config rm --cached $repoPath
                    }
                    Remove-Item -Path $file -Recurse:($rmOpts -contains "-r") -Force
                    Write-Host "Removed: $file" -ForegroundColor Yellow
                }
            }
            "sync" {
                $direction = if ($Args.Count -gt 0) { $Args[0] } else { "to-repo" }
                _config ls-files | ForEach-Object {
                    $repoFile = $_
                    $sysFile = _sys_path $repoFile
                    $fullRepoPath = Join-Path "$HOME\.cfg" $repoFile
                    
                    if ($direction -eq "to-repo") {
                        if ((Test-Path $sysFile) -and (Test-Path $fullRepoPath)) {
                            $diff = Compare-Object (Get-Content $fullRepoPath -ErrorAction SilentlyContinue) (Get-Content $sysFile -ErrorAction SilentlyContinue)
                            if ($diff) {
                                Copy-Item $sysFile $fullRepoPath -Force
                                Write-Host "Synced to repo: $sysFile" -ForegroundColor Cyan
                            }
                        }
                    } elseif ($direction -eq "from-repo") {
                        if ((Test-Path $fullRepoPath)) {
                            $diff = if (Test-Path $sysFile) { Compare-Object (Get-Content $fullRepoPath -ErrorAction SilentlyContinue) (Get-Content $sysFile -ErrorAction SilentlyContinue) } else { $true }
                            if ($diff) {
                                $destDir = Split-Path $sysFile
                                if (($sysFile.StartsWith('\\') -or $sysFile.Contains(':')) -and -not $sysFile.StartsWith($HOME)) {
                                    _admin_prompt "Copy-Item '$fullRepoPath' '$sysFile' -Recurse -Force"
                                } else {
                                    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
                                    Copy-Item $fullRepoPath $sysFile -Recurse -Force
                                }
                                Write-Host "Synced from repo: $sysFile" -ForegroundColor Cyan
                            }
                        }
                    }
                }
            }
            "status" {
                $autoSynced = @()
                _config ls-files | ForEach-Object {
                    $repoFile = $_
                    $sysFile = _sys_path $repoFile
                    $fullRepoPath = Join-Path "$HOME\.cfg" $repoFile
                    if ((Test-Path $sysFile) -and (Test-Path $fullRepoPath)) {
                        $diff = Compare-Object (Get-Content $fullRepoPath -ErrorAction SilentlyContinue) (Get-Content $sysFile -ErrorAction SilentlyContinue)
                        if ($diff) {
                            Copy-Item $sysFile $fullRepoPath -Force
                            $autoSynced += $repoFile
                        }
                    }
                }
                if ($autoSynced.Count -gt 0) {
                    Write-Host "=== Auto-synced Files ===" -ForegroundColor Magenta
                    foreach ($repoFile in $autoSynced) {
                        Write-Host "synced: $(_sys_path $repoFile) -> $repoFile" -ForegroundColor Cyan
                    }
                    Write-Host
                }
                _config status
                Write-Host
            }
            "deploy" {
                _config ls-files | ForEach-Object {
                    $repoFile = $_
                    $sysFile = _sys_path $repoFile
                    $fullRepoPath = Join-Path "$HOME\.cfg" $repoFile
                    
                    if ((Test-Path $fullRepoPath) -and $sysFile) {
                        $destDir = Split-Path $sysFile
                        if (($sysFile.StartsWith('\\') -or $sysFile.Contains(':')) -and -not $sysFile.StartsWith($HOME)) {
                            _admin_prompt "New-Item -ItemType Directory -Path '$destDir' -Force; Copy-Item '$fullRepoPath' '$sysFile' -Recurse -Force"
                        } else {
                            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
                            Copy-Item $fullRepoPath $sysFile -Recurse -Force
                        }
                        Write-Host "Deployed: $repoFile -> $sysFile" -ForegroundColor Green
                    }
                }
            }
            "checkout" {
                Write-Host "Checking out dotfiles from .cfg..." -ForegroundColor Blue
                _config ls-files | ForEach-Object {
                    $repoFile = $_
                    $sysFile = _sys_path $repoFile
                    $fullRepoPath = Join-Path "$HOME\.cfg" $repoFile
                    
                    if ((Test-Path $fullRepoPath) -and $sysFile) {
                        $destDir = Split-Path $sysFile
                        if (($sysFile.StartsWith('\\') -or $sysFile.Contains(':')) -and -not $sysFile.StartsWith($HOME)) {
                            _admin_prompt "New-Item -ItemType Directory -Path '$destDir' -Force; Copy-Item '$fullRepoPath' '$sysFile' -Recurse -Force"
                        } else {
                            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
                            Copy-Item $fullRepoPath $sysFile -Recurse -Force
                        }
                        Write-Host "Checked out: $repoFile -> $sysFile" -ForegroundColor Green
                    }
                }
            }
            "backup" {
                $timestamp = Get-Date -Format "yyyyMMddHHmmss"
                $backupDir = Join-Path $HOME ".dotfiles_backup\$timestamp"
                Write-Host "Backing up existing dotfiles to $backupDir..." -ForegroundColor Blue
                
                _config ls-files | ForEach-Object {
                    $repoFile = $_
                    $sysFile = _sys_path $repoFile
                    if (Test-Path $sysFile) {
                        $destDirFull = Join-Path $backupDir (Split-Path $repoFile)
                        if (-not (Test-Path $destDirFull)) { New-Item -ItemType Directory -Path $destDirFull -Force | Out-Null }
                        Copy-Item $sysFile (Join-Path $backupDir $repoFile) -Recurse -Force
                    }
                }
                Write-Host "Backup complete. To restore, copy files from $backupDir to their original locations." -ForegroundColor Green
            }
            default {
                _config $Command @Args
            }
        }
    }
}

# Shows navigable menu of all options when hitting Tab
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# Autocompletion for arrow keys
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

New-Alias vi nvim.exe

