@echo off
REM === Installing Dotfiles ===

REM Set execution policy for current user
powershell -NoProfile -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"

REM Run PowerShell profile (dotfiles)
powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

REM Run bootstrap script
powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\Documents\PowerShell\bootstrap.ps1"
