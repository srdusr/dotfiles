# bloatware.ps1

# Check if the powershell-yaml module is installed, if not, install it
if (-not (Get-Module powershell-yaml -ListAvailable)) {
    $policy = Get-PSRepository -Name 'PSGallery' | Select-Object -ExpandProperty InstallationPolicy
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    Install-Module powershell-yaml
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy $policy
}

Import-Module powershell-yaml

# Define the path to the YAML file
$yamlFilePath = "$HOME\packages.yml"

# Parse the YAML file
$packages = ConvertFrom-Yaml -Path $yamlFilePath
$bloatware = $packages.bloatware
$defaultApps = $packages.defaultApps

# Check if Registry key exists
function Check-RegistryKeyExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyPath
    )

    if (Test-Path $KeyPath) {
        Write-Host "Registry key exists: $KeyPath"
        return $true
    } else {
        Write-Host "Registry key does not exist: $KeyPath"
        return $false
    }
}

# Helper functions ------------------------
function force-mkdir($path) {
    if (!(Test-Path $path)) {
        Write-Host "-- Creating full path to: " $path -ForegroundColor White -BackgroundColor DarkGreen
        New-Item -ItemType Directory -Force -Path $path
    }
}

function Takeown-Registry($key) {
    # TODO does not work for all root keys yet
    switch ($key.split('\')[0]) {
        "HKEY_CLASSES_ROOT" {
            $reg = [Microsoft.Win32.Registry]::ClassesRoot
            $key = $key.substring(18)
        }
        "HKEY_CURRENT_USER" {
            $reg = [Microsoft.Win32.Registry]::CurrentUser
            $key = $key.substring(18)
        }
        "HKEY_LOCAL_MACHINE" {
            $reg = [Microsoft.Win32.Registry]::LocalMachine
            $key = $key.substring(19)
        }
    }

    # get administrator group
    $admins = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
    $admins = $admins.Translate([System.Security.Principal.NTAccount])

    # set owner
    $key = $reg.OpenSubKey($key, "ReadWriteSubTree", "TakeOwnership")
    $acl = $key.GetAccessControl()
    $acl.SetOwner($admins)
    $key.SetAccessControl($acl)

    # set FullControl
    $acl = $key.GetAccessControl()
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule($admins, "FullControl", "Allow")
    $acl.SetAccessRule($rule)
    $key.SetAccessControl($acl)
}

# Function to take ownership of registry keys
function Takeown-Registry($keyPath) {
    $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($keyPath, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::TakeOwnership)
    $acl = $regKey.GetAccessControl()
    $acl.SetOwner([System.Security.Principal.NTAccount]"Administrators")
    $regKey.SetAccessControl($acl)
    $regKey.Close()
}

# Remove Features
function Takeown-File($path) {
    takeown.exe /A /F $path
    $acl = Get-Acl $path

    # get administrator group
    $admins = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
    $admins = $admins.Translate([System.Security.Principal.NTAccount])

    # add NT Authority\SYSTEM
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($admins, "FullControl", "None", "None", "Allow")
    $acl.AddAccessRule($rule)

    Set-Acl -Path $path -AclObject $acl
}

function Takeown-Folder($path) {
    Takeown-File $path
    foreach ($item in Get-ChildItem $path) {
        if (Test-Path $item -PathType Container) {
            Takeown-Folder $item.FullName
        }
        else {
            Takeown-File $item.FullName
        }
    }
}

function Elevate-Privileges {
    param($Privilege)
    $Definition = @"
    using System;
    using System.Runtime.InteropServices;

    public class AdjPriv {
        [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
            internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr rele);

        [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
            internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);

        [DllImport("advapi32.dll", SetLastError = true)]
            internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);

        [StructLayout(LayoutKind.Sequential, Pack = 1)]
            internal struct TokPriv1Luid {
                public int Count;
                public long Luid;
                public int Attr;
            }

        internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
        internal const int TOKEN_QUERY = 0x00000008;
        internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;

        public static bool EnablePrivilege(long processHandle, string privilege) {
            bool retVal;
            TokPriv1Luid tp;
            IntPtr hproc = new IntPtr(processHandle);
            IntPtr htok = IntPtr.Zero;
            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
            tp.Count = 1;
            tp.Luid = 0;
            tp.Attr = SE_PRIVILEGE_ENABLED;
            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
            return retVal;
        }
    }
"@
    $ProcessHandle = (Get-Process -id $pid).Handle
    $type = Add-Type $definition -PassThru
    $type[0]::EnablePrivilege($processHandle, $Privilege)
}

# Remove Features ------------------------
foreach ($bloat in $bloatware) {
    Write-Output "Removing packages containing $bloat"
    $pkgs = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" | Where-Object Name -Like "*$bloat*"

    foreach ($pkg in $pkgs) {
        $pkgname = $pkg.Name.Split('\')[-1]
        Takeown-Registry $pkg.Name
        Takeown-Registry ($pkg.Name + "\Owners")
        Set-ItemProperty -Path ("HKLM:" + $pkg.Name.Substring(18)) -Name Visibility -Value 1
        New-ItemProperty -Path ("HKLM:" + $pkg.Name.Substring(18)) -Name DefVis -PropertyType DWord -Value 2
        Remove-Item -Path ("HKLM:" + $pkg.Name.Substring(18) + "\Owners")
        dism.exe /Online /Remove-Package /PackageName:$pkgname /NoRestart
    }
}

# Remove default apps and bloat
Write-Output "Uninstalling default apps"
foreach ($app in $defaultApps) {
    Write-Output "Trying to remove $app"
    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers
    Get-AppXProvisionedPackage -Online | Where-Object DisplayName -EQ $app | Remove-AppxProvisionedPackage -Online
}

# Disable Microsoft Edge sidebar
$RegistryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
$Name = 'HubsSidebarEnabled'
$Value = '00000000'
# Create the key if it does not exist
If (-NOT (Test-Path $RegistryPath)) {
    New-Item -Path $RegistryPath -Force | Out-Null
}
New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force

# Disable Microsoft Edge first-run Welcome screen
$RegistryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
$Name = 'HideFirstRunExperience'
$Value = '00000001'
# Create the key if it does not exist
If (-NOT (Test-Path $RegistryPath)) {
    New-Item -Path $RegistryPath -Force | Out-Null
}
New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force

# Remove Microsoft Edge ------------------------
$ErrorActionPreference = "Stop"
$regView = [Microsoft.Win32.RegistryView]::Registry32
$microsoft = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $regView).
OpenSubKey('SOFTWARE\Microsoft', $true)
$edgeUWP = "$env:SystemRoot\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe"
$uninstallRegKey = $microsoft.OpenSubKey('Windows\CurrentVersion\Uninstall\Microsoft Edge')
$uninstallString = $uninstallRegKey.GetValue('UninstallString') + ' --force-uninstall'
Write-Host "Removed Microsoft Edge"

$edgeClient = $microsoft.OpenSubKey('EdgeUpdate\ClientState\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}', $true)
if ($null -ne $edgeClient.GetValue('experiment_control_labels')) {
	$edgeClient.DeleteValue('experiment_control_labels')
}
$microsoft.CreateSubKey('EdgeUpdateDev').SetValue('AllowUninstall', '')
[void](New-Item $edgeUWP -ItemType Directory -ErrorVariable fail -ErrorAction SilentlyContinue)
[void](New-Item "$edgeUWP\MicrosoftEdge.exe" -ErrorAction Continue)
Start-Process cmd.exe "/c $uninstallString" -WindowStyle Hidden -Wait
[void](Remove-Item "$edgeUWP\MicrosoftEdge.exe" -ErrorAction Continue)

if (-not $fail) {
	[void](Remove-Item "$edgeUWP")
}

Write-Output "Edge should now be uninstalled!"

# Kill OneDrive with fire ------------------------
Write-Output "Kill OneDrive process"
taskkill.exe /F /IM "OneDrive.exe"
taskkill.exe /F /IM "explorer.exe"
Write-Output "Remove OneDrive"
if (Test-Path "$env:systemroot\System32\OneDriveSetup.exe") {
    & "$env:systemroot\System32\OneDriveSetup.exe" /uninstall
}
if (Test-Path "$env:systemroot\SysWOW64\OneDriveSetup.exe") {
    & "$env:systemroot\SysWOW64\OneDriveSetup.exe" /uninstall
}

Write-Output "Removing OneDrive leftovers"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:localappdata\Microsoft\OneDrive"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:programdata\Microsoft OneDrive"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:systemdrive\OneDriveTemp"
# check if directory is empty before removing:
If ((Get-ChildItem "$env:userprofile\OneDrive" -Recurse | Measure-Object).Count -eq 0) {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:userprofile\OneDrive"
}

Write-Output "Disable OneDrive via Group Policies"
force-mkdir "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\OneDrive"
Set-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" 1

Write-Output "Remove Onedrive from explorer sidebar"
New-PSDrive -PSProvider "Registry" -Root "HKEY_CLASSES_ROOT" -Name "HKCR"
force-mkdir "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
Set-ItemProperty "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0
force-mkdir "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
Set-ItemProperty "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0
Remove-PSDrive "HKCR"

# Thank you Matthew Israelsson
Write-Output "Removing run hook for new users"
reg load "hku\Default" "C:\Users\Default\NTUSER.DAT"
reg delete "HKEY_USERS\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f
reg unload "hku\Default"

Write-Output "Removing startmenu entry"
Remove-Item -Force -ErrorAction SilentlyContinue "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"

Write-Output "Removing scheduled task"
$scheduledTasks = Get-ScheduledTask -TaskPath '\' -TaskName 'OneDrive*' -ErrorAction SilentlyContinue
if ($scheduledTasks) {
    try {
        $scheduledTasks | Unregister-ScheduledTask -Confirm:$false
        Write-Output "OneDrive scheduled tasks removed."
    } catch {
        Write-Warning "Failed to unregister scheduled tasks: $_"
    }
} else {
    Write-Output "No OneDrive scheduled tasks found."
}

Write-Output "Restarting explorer"
Start-Process "explorer.exe"

Write-Output "Waiting for explorer to complete loading"
Start-Sleep 10

Write-Output "Removing additional OneDrive leftovers"
foreach ($item in (Get-ChildItem "$env:WinDir\WinSxS\*onedrive*")) {
    Takeown-Folder $item.FullName
    try {
        Remove-Item -Recurse -Force -ErrorAction Continue -ErrorVariable RemoveError $item.FullName
        if ($RemoveError) {
            Write-Warning "Failed to remove $($item.FullName): $($RemoveError.Exception.Message)"
        } else {
            Write-Output "Successfully removed: $($item.FullName)"
        }
    } catch {
        Write-Warning "Failed to remove $($item.FullName): $_"
    }
}

# As a last step, disable UAC ------------------------
New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force

# Remove OneDrive directory if it exists
Write-Host "Removing OneDrive directory"

# Change directory to user's home directory
Set-Location $HOME

# Check if OneDrive directory exists
$OneDrivePath = Join-Path $HOME "OneDrive"
if (Test-Path -Path $OneDrivePath -PathType Container) {
    # Remove OneDrive directory recursively and forcefully
    Remove-Item -Path $OneDrivePath -Recurse -Force -ErrorAction Continue
    if ($?) {
        Write-Output "OneDrive directory removed successfully."
    } else {
        Write-Warning "Failed to remove OneDrive directory."
    }
} else {
    Write-Output "OneDrive directory not found."
}

# Prevents "Suggested Applications" returning
if (Check-RegistryKeyExists -KeyPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Cloud Content") {
    Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Cloud Content" "DisableWindowsConsumerFeatures" 1
}
