<#
.SYNOPSIS
    Optimizes LOD VM
.DESCRIPTION
    Optimizes the Learning on Demand Virtual Machine before hard disk snapshot.
    After optimization, it stops the VM as another best practice for disk snapshots.
.EXAMPLE
    PS C:\> Optimize-LOD.ps1
    Cleans various temporary files and sets lab best practice settings.
    This script supports Edge (Chrome) Stable too.
.INPUTS
    None
.OUTPUTS
    Void
.NOTES
    Requires administrative rights
#>

#Requires -RunAsAdministrator

param(
    [System.String]$EdgeChrome = "$Home\AppData\Local\Microsoft\Edge\User Data\Default\Cache\"
)

# Requires CleanMgr.exe /SageSet:0 to be set on each machine to run correctly
Start-Process -FilePath "CleanMgr.exe" -ArgumentList "/SageRun:0" -Wait

# Set desktop wallpaper and window colorization
Set-ItemProperty -Path "HKCU:\Control Panel\Colors" -Name "Background" -Value "0 0 0"
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value ""
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers" -Name "BackgroundType" -Value 1
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "AutoColorization" -Value 1

# Removes the PowerShell session history file
Remove-Item -Path "$home\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"

# Removes the network history
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\*" -Recurse

# Clear the super(pre)fetch
Remove-Item -Path "$Env:WinDir\Prefetch\*" -Recurse -Force

# Stop Edge Chrome if running
Get-Process -Name "MSEdge" | Stop-Process

# Remove Edge Chrome Data
Set-Location -Path $EdgeChrome
Remove-Item -Path "*cookies*", "*history*", "*web data*", "*top sites*", "*log*", "*manifest*", "cache", "Code cache", "AutofillStrikeDatabase" -Recurse -Force -ErrorAction "SilentlyContinue"

# Remove Explorer History
Remove-Item "$Env:APPDATA\Microsoft\Windows\Recent\*" -Recurse -Force -ErrorAction "SilentlyContinue"
Remove-Item "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Recurse -Force -ErrorAction "SilentlyContinue"
Remove-Item "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths" -Recurse -Force -ErrorAction "SilentlyContinue"

# Clear all of the event logs
Get-EventLog -LogName * | ForEach-Object -Process {Clear-EventLog -LogName $_.Log}

# Shut down the computer in prep for VHD check point
Stop-Computer -Force