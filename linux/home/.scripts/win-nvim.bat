@echo off

REM Install NeoVim with winget, if not already present on the system
where nvim >nul 2>nul
if %errorlevel% neq 0 (
    winget install Neovim.Neovim -q
)

REM Clone my dotfiles repo
set dotFilesRoot=%USERPROFILE%\dotfiles
if not exist "%dotFilesRoot%\." (
    git clone git@github.com:srdusr/dotfiles.git "%dotFilesRoot%"
)

REM Link NeoVim configuration
set localConfiguration=%LOCALAPPDATA%\nvim
set dotfilesConfiguration=%dotFilesRoot%\.config\nvim

if not exist "%localConfiguration%\." (
    mklink /D "%localConfiguration%" "%dotfilesConfiguration%"
)

REM Clone Packer.nvim, if not already present on the system
set localPacker=%LOCALAPPDATA%\nvim-data\site\pack\packer\start\packer.nvim

if not exist "%localPacker%\." (
    git clone https://github.com/wbthomason/packer.nvim "%localPacker%"
)

REM Run the script by using this command in the same existing directory: win-nvim.bat

@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://aka.ms/install-winget'))"
iex ((new-object net.webclient).DownloadString('https://aka.ms/install-winget'))
curl -o winget-cli.appxbundle https://aka.ms/winget-cli-appxbundle

powershell Add-AppxPackage -Path "winget-cli.appxbundle"

