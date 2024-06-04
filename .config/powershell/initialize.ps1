<#
    .SYNOPSIS
    Bootstrap Windows command prompts (cmd, PS, PSCore) with my dotfiles and apps.

    .DESCRIPTION
    to bootstrap directly from github, run these 2 cmdlets in a PowerShell prompt:
    > Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    > irm 'https://raw.githubusercontent.com/davidjenni/dotfiles/main/bootstrap.ps1' | iex
#>
[CmdletBinding()]
param (
    [ValidateSet('clone', 'setup', 'apps', 'env', IgnoreCase = $true)]
    [Parameter(Position = 0)] [string]
    # verb that indicates stage:
    #  clone:       clone the dotfiles repo and continue with 'setup' etc.
    #  setup:       setup PS, package managers, git. Includes 'apps' and 'env'.
    #  apps:        install apps via winget and scoop
    #  env:         setups consoles and configurations for git, neovim, PowerShell etc.
    $verb = 'clone',
    [Parameter()] [string]
    # user name for git commits, defaults to '$env:USERNAME@$env:COMPUTERNAME'
    $userName = $null,
    [Parameter()] [string]
    # email address for git commits, defaults to existing git config or prompts for input
    $email = $null,
    [Parameter()] [switch]
    # in most cases, do not run this script elevated; mostly needed in automation like PR loop
    $runAsAdmin = $false
)

$ErrorActionPreference = 'Stop'

$originGitHub='https://github.com/srdusr/dotfiles.git'
$dotPath=(Join-Path $env:USERPROFILE 'dotfiles')

# should be the default on all Win10+, but just in case...
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor
                                              [Net.SecurityProtocolType]::Tls12

function ensureLocalGit {
    if (Get-Command 'git' -ErrorAction SilentlyContinue) {
        return
    }

    # bootstrap with a local git to avoid early elevating for winget and the git installer:
    $localGitFolder = (Join-Path $env:USERPROFILE (Join-Path "Downloads" "localGit"))
    Write-Host "Installing ad-hoc git into $localGitFolder..."

    $gitUrl = Invoke-RestMethod 'https://api.github.com/repos/git-for-windows/git/releases/latest' |
        Select-Object -ExpandProperty 'assets' |
        Where-Object { $_.name -Match 'MinGit' -and $_.name -Match '64-bit' -and $_.name -notmatch 'busybox' } |
        Select-Object -ExpandProperty 'browser_download_url'
    $localGitZip = (Join-Path $localGitFolder "MinGit.zip")
    New-Item -ItemType Directory -Path $localGitFolder -Force | Out-Null
    # Invoke-RestMethod with its progress bar is about 10x slower than WebClient.DownloadFile...
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
    if (-not $username -or $username -eq '') {
        $username = "$env:USERNAME@$env:COMPUTERNAME"
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
    # https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-email-preferences/setting-your-commit-email-address
    & git.exe config --global user.email $email

    & git clone $originGitHub $dotPath
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

    # do a one-off save for the formerly symlinked .gitconfig:
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
    Write-Host "setting cmd console properties:"
    $consolePath='HKCU\Console'
    & reg add $consolePath /v QuickEdit         /d 0x1              /t REG_DWORD /f | Out-Null
    & reg add $consolePath /v WindowSize        /d 0x00320078       /t REG_DWORD /f | Out-Null
    & reg add $consolePath /v ScreenBufferSize  /d 0x23280078       /t REG_DWORD /f | Out-Null
    & reg add $consolePath /v FontFamily        /d 0x36             /t REG_DWORD /f | Out-Null
    & reg add $consolePath /v HistoryBufferSize /d 0x64             /t REG_DWORD /f | Out-Null
    & reg add $consolePath /v FaceName          /d "Hack Nerd Font Mono" /t REG_SZ  /f | Out-Null
    & reg add $consolePath /v FontSize          /d 0x00100000       /t REG_DWORD /f | Out-Null

    $win32rc=(Join-Path $PSScriptRoot (Join-Path 'win' 'win32-rc.cmd'))
    Write-Host "setting up cmd autorun: $win32rc"
    & reg add "HKCU\Software\Microsoft\Command Processor" /v AutoRun /t REG_SZ /d $win32rc /f | Out-Null

    # TODO: needs elevation
    # Write-Host "remap CapsLock to LeftCtrl key:"
    # # see http://www.experts-exchange.com/OS/Microsoft_Operating_Systems/Windows/A_2155-Keyboard-Remapping-CAPSLOCK-to-Ctrl-and-Beyond.html
    # # http://msdn.microsoft.com/en-us/windows/hardware/gg463447.aspx
    # & reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout" /v "Scancode Map" /d 0000000000000000020000001D003A0000000000 /t REG_BINARY /f | Out-Null
    # Write-Host "CapsLock remapped, will be effective after next system reboot."

    # TODO: initialize Terminal, but its .json file won't exist until after the first launch
    # $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json

    # can't use on WinPS, too many at-work scripts fail
    # $psProfile = (& powershell -NoProfile -Command '$PROFILE.CurrentUserAllHosts')
    # copyFile (Join-Path 'win' 'profile.ps1') $psProfile

    Write-Host "configuring user home dir..."
    $configDir = (Join-Path $env:USERPROFILE '.config')
    New-Item -ItemType Directory -Path $configDir -ErrorAction SilentlyContinue | Out-Null

    writeGitConfig (Join-Path $PSScriptRoot 'gitconfig.ini')

    $sshDir = (Join-Path $env:USERPROFILE '.ssh')
    # ensure 1Password's identity agent is visible to OpenSSH; cannot have both config and socket on Windows
    # https://developer.1password.com/docs/ssh/agent/advanced#windows
    # https://developer.1password.com/docs/ssh/get-started/#step-4-configure-your-ssh-or-git-client
    Remove-Item (Join-Path $sshDir 'config') -ErrorAction SilentlyContinue -Force | Out-Null
    $openSsh=((Join-Path $env:windir 'System32\OpenSSH\ssh.exe').Replace("\", "/"))
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
                Write-Host "local git repo already exists, skipping."
                # continue in-proc:
                main setup
                return
            }

            $rc = cloneDotfiles
            if ($rc -ne 0) {
                Write-Error "Cloning dotfiles failed, aborting."
                return
            }
            # continue with now-local bootstrap.ps1 from cloned repo:
            # still stick with desktop PS since PSCore is not necessarily installed yet
            $script= (Join-Path $dotPath 'bootstrap.ps1')
            Write-Host "Continue $script in child process"
            Start-Process -PassThru -NoNewWindow -FilePath "powershell.exe" -ArgumentList "-NoProfile -File $script setup" |
                Wait-Process
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
