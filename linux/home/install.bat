REM Installing Dotfiles

powershell . $HOME\.config\powershell\Microsoft.PowerShell_profile.ps1
powershell Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
powershell . $HOME\.config\powershell\bootstrap.ps1

