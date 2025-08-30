<#
    .SYNOPSIS
    Bootstrap Windows command prompts (cmd, PS, PSCore) with my dotfiles and apps.

    .DESCRIPTION
    To bootstrap directly from GitHub, run these 2 cmdlets in a PowerShell prompt:
    > Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    > irm 'https://raw.githubusercontent.com/srdusr/dotfiles/main/bootstrap.ps1' | iex
#>
[CmdletBinding()]
param (
    [ValidateSet('clone', 'setup', 'apps', 'env', IgnoreCase = $true)]
    [Parameter(Position = 0)] [string]
    $verb = 'clone',
    [Parameter()] [string]
    $userName = $null,
    [Parameter()] [string]
    $email = $null,
    [Parameter()] [switch]
    $runAsAdmin = $false
)

$ErrorActionPreference = 'Stop'

$originGitHub = 'https://github.com/srdusr/dotfiles.git'
$dotPath = (Join-Path $env:USERPROFILE '.cfg')

# Ensure Tls12
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

function ensureLocalGit {
    if (Get-Command 'git' -ErrorAction SilentlyContinue) {
        return
    }

    $localGitFolder = (Join-Path $env:USERPROFILE (Join-Path "Downloads" "localGit"))
    Write-Host "Installing ad-hoc git into $localGitFolder..."

    $gitUrl = Invoke-RestMethod 'https://api.github.com/repos/git-for-windows/git/releases/latest' |
        Select-Object -ExpandProperty 'assets' |
        Where-Object { $_.name -Match 'MinGit' -and $_.name -Match '64-bit' -and $_.name -notmatch 'busybox' } |
        Select-Object -ExpandProperty 'browser_download_url'
    $localGitZip = (Join-Path $localGitFolder "MinGit.zip")
    New-Item -ItemType Directory -Path $localGitFolder -Force | Out-Null
    (New-Object Net.WebClient).DownloadFile($gitUrl, $localGitZip)
    Expand-Archive -Path $localGitZip -DestinationPath $localGitFolder -Force

    $gitPath = (Join-Path $localGitFolder 'cmd')
    $env:Path += ";$gitPath"
}

function cloneDotfiles {
    Write-Host "Cloning $originGitHub -> $dotPath"
    Write-Host -NoNewline "OK to proceed with setup? [Y/n] "
    $answer = (Read-Host).ToUpper()
    if ($answer -ne 'Y' -and $answer -ne '') {
        Write-Warning "Aborting."
        return 4
    }

    ensureLocalGit

    if (-not $userName -or $userName -eq '') {
        $userName = (& git config --global --get user.name)
    }
    if (-not $userName -or $userName -eq '') {
        $userName = "$env:USERNAME@$env:COMPUTERNAME"
    }

    if (-not $email -or $email -eq '') {
        $email = (& git config --global --get user.email)
    }
    if (-not $email -or $email -eq '') {
        $email = Read-Host "Enter your email address for git commits"
        if ($email -eq '') {
            Write-Warning "Need email address, aborting."
            return 3
        }
    }

    & git.exe config --global user.name $userName
    & git.exe config --global user.email $email


    function global:config {
        git --git-dir="$dotPath" --work-tree="$env:USERPROFILE" $args
    }

    Add-Content -Path "$env:USERPROFILE\.gitignore" -Value ".cfg"

    if (Test-Path -Path $dotfiles_dir) {
        config pull | Out-Null
        $update = $true
    } else {
        git clone --bare $originGitHub $dotPath | Out-Null
        $update = $false
    }

    $std_err_output = config checkout 1>&1

    if ($std_err_output -match "following untracked working tree files would be overwritten") {
        if (-not $update) {
            config checkout | Out-Null
        }
    }
    config config --local status.showUntrackedFiles no

    if ($update -or (Read-Host "Do you want to overwrite existing files and continue with the dotfiles setup? [Y/n]" -eq "Y")) {
        config fetch origin main:main | Out-Null
        config reset --hard main | Out-Null
        config checkout -f
        if ($?) {
            Write-Host "Successfully imported $dotPath."
        } else {
            handle_error "Mission failed."
        }
    } else {
        handle_error "Aborted by user. Exiting..."
    }

    return 0
}

function setup {
    ensureLocalGit
}

function installApps {
    ensureLocalGit
}

function writeGitConfig {
    param (
        [Parameter(Mandatory = $true)] [string] $configIniFile
    )

    if ((Test-Path (Join-Path $env:USERPROFILE '.gitconfig')) -and -not (Test-Path (Join-Path $env:USERPROFILE '.gitconfig.bak'))) {
        $userName = (& git config --global --get user.name)
        $email = (& git config --global --get user.email)

        Move-Item -Path (Join-Path $env:USERPROFILE '.gitconfig') -Destination (Join-Path $env:USERPROFILE '.gitconfig.bak')

        if ($userName -and $userName -ne '') {
            & git.exe config --global user.name $userName
        }
        if ($email -and $email -ne '') {
            & git.exe config --global user.email $email
        }
    }

    Get-Content $configIniFile | ForEach-Object {
        if ($_.TrimStart().StartsWith('#')) { return }
        $key, $value = $_.Split('=', 2)
        Write-Verbose "git config --global $key $value"
        & git.exe config --global $key "$value"
    }
}

function setupShellEnvs {
    Write-Host "Setting cmd console properties:"
    $consolePath = 'HKCU\Console'
    & reg add $consolePath /v QuickEdit         /d 0x1              /t REG_DWORD /f | Out-Null
    & reg add $consolePath /v WindowSize        /d 0x00320078       /t REG_DWORD /f | Out-Null
    & reg add $consolePath /v ScreenBufferSize  /d 0x23280078       /t REG_DWORD /f | Out-Null
    & reg add $consolePath /v FontFamily        /d 0x36             /t REG_DWORD /f | Out-Null
    & reg add $consolePath /v HistoryBufferSize /d 0x64             /t REG_DWORD /f | Out-Null
    & reg add $consolePath /v FaceName          /d "Hack Nerd Font Mono" /t REG_SZ  /f | Out-Null
    & reg add $consolePath /v FontSize          /d 0x00100000       /t REG_DWORD /f | Out-Null

    $win32rc = (Join-Path $PSScriptRoot (Join-Path 'win' 'win32-rc.cmd'))
    Write-Host "Setting up cmd autorun: $win32rc"
    & reg add "HKCU\Software\Microsoft\Command Processor" /v AutoRun /t REG_SZ /d $win32rc /f | Out-Null

    Write-Host "Configuring user home dir..."
    $configDir = (Join-Path $env:USERPROFILE '.config')
    New-Item -ItemType Directory -Path $configDir -ErrorAction SilentlyContinue | Out-Null

    $sshDir = (Join-Path $env:USERPROFILE '.ssh')
    Remove-Item (Join-Path $sshDir 'config') -ErrorAction SilentlyContinue -Force | Out-Null
    $openSsh = ((Join-Path $env:windir 'System32\OpenSSH\ssh.exe').Replace("\", "/"))
    & git config --global core.sshCommand $openSsh
}

function main {
    param (
        [Parameter(Mandatory = $true)] [string] $verbAction
    )

    Write-Verbose "PS: $($PSVersionTable.PSVersion)-$($PSVersionTable.PSEdition)"
    switch ($verbAction) {
        'clone' {
            Write-Host
            if (Test-Path (Join-Path $dotPath '.git')) {
                Write-Host "Local git repo already exists, skipping."
                main setup
                return
            }

            $rc = cloneDotfiles
            if ($rc -ne 0) {
                Write-Error "Cloning dotfiles failed, aborting."
                return
            }

            $script = (Join-Path $dotPath '.config\powershell\bootstrap.ps1')
            Write-Host "Continue $script in child process"
            Start-Process -PassThru -NoNewWindow -FilePath "powershell.exe" -ArgumentList "-NoProfile -File $script setup" | Wait-Process
        }

        'setup' {
            Write-Host "Setting up..."
            setup
            installApps
            setupShellEnvs
            Write-Host "Done (setup)."
            exit
        }

        'apps' { installApps }

        'env' { setupShellEnvs }
    }

    Write-Host "Done."
}

main $verb
