<#
.SYNOPSIS
    Fixes a variety of shortcut issues caused by accidental shortcut deletion.
.LINK
    https://aka.ms/psdoodads
.EXAMPLE
    PS> Sync-Shortcut.ps1
    Fixes a variety of missing shortcuts by placing them back in the start menu.
.NOTES
    Requires administrator rights

    Exit codes:
        1- Unsupported platform
#>

#Requires -RunAsAdministrator

# Create a function that generates shortcuts
function New-Shortcut {
    <#
    .SYNOPSIS
        Creates a shortcut with the specified info
    .PARAMETER Name
        Name of the shortcut to create.
        
        Do not include the "lnk" at the end.
        This is auto appended.
    .PARAMETER ShortcutPath
        Folder where the shortcut will be created at
    .PARAMETER TargetPath
        Path to the file or folder that the shortcut points to.
    .PARAMETER StartIn
        The working directory context that the file will be launched from.
    #>
    
    # Initialize advanced capabilities of the function to mimic cmdlets
    [CmdletBinding(SupportsShouldProcess)]
    
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]$Name,
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -Path $_ -PathType 'Container' })]
        [System.String]$ShortcutPath,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]$TargetPath,
        [ValidateScript({ Test-Path -Path $_ -PathType 'Container' })]
        [System.String]$StartIn
    )

    # Execute once at the beginning of the pipeline
    begin {
        # Simulate command
        if ($PSCmdlet.ShouldProcess('Memory', 'Instantiate an instance of the WScript subsystem.')) {
            # Instantiate the WShell processor
            $WShellInstance = New-Object -ComObject 'WScript.Shell'
        }
    }

    # Execute for each object passed on the pipeline or just once if executed outside of a pipeline
    process {
        # Simulate command
        if ($PSCmdlet.ShouldProcess('Memory', 'Create Shortcut Object')) {
            # Create a shortcut object in memory
            $Shortcut = $WShellInstance.CreateShortcut("$ShortcutPath\$Name.lnk")
        }

        # Simulate command
        if ($PSCmdlet.ShouldProcess('Shortcut Object', 'Set location of target')) {
            # Set the target of the shortcut
            $Shortcut.TargetPath = $TargetPath
        }

        # Set the working directory
        if ($PSBoundParameters.ContainsKey('StartIn')) {
            # Simulate command
            if ($PSCmdlet.ShouldProcess('Shortcut Object', 'Set Working Directory')) {
                # Set the working directory for the shortcut if specified
                $Shortcut.WorkingDirectory = $StartIn
            }
        }

        # Simulate command
        if ($PSCmdlet.ShouldProcess('Disk', 'Write Shortcut Object')) {
            # Write the shortcut from memory to disk
            $Shortcut.Save()
        }
    }
}

# Disable progress bar to speed up downloads
$ProgressPreference = 'SilentlyContinue'

# Check CPU architecture
if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') {
    # Set the architecture internally
    [System.String]$Architecture = 'x64'
} elseif ($env:PROCESSOR_ARCHITECTURE -eq 'x86') {
    # Set the architecture internally
    [System.String]$Architecture = 'x86'
} else {
    # Unsupported architecture
    Write-Error -Message 'This script does not support systems that are not x64 or x86, e.g. IA64...'

    # Exit unsuccessfully
    exit 1
}

# Repair Office
if (Test-Path -Path 'C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe' -PathType 'Leaf') {
    # Repair Office
    Start-Process -FilePath 'C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe' -ArgumentList 'scenario=Repair', "platform=$Architecture", 'culture=en-us', 'forceappshutdown=True', 'RepairType=QuickRepair', 'DisplayLevel=False' -Wait

    # Download Teams's MSI
    Invoke-WebRequest -Uri "https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=$Architecture&managedInstaller=true&download=true" -OutFile 'Teams.msi'

    # Uninstall teams if it exists already
    Start-Process -FilePath 'msiexec.exe' -ArgumentList '/uninstall', 'teams.msi', '/qn' -Wait

    # Install teams
    Start-Process -FilePath 'msiexec.exe' -ArgumentList '/install', 'teams.msi', '/qn' -Wait

    # Remove the MSI file used to reinstall teams
    Remove-Item -Path '.\Teams.msi' -ErrorAction 'SilentlyContinue'
}

# Fix MS Edge
if (Test-Path -Path 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe' -PathType 'Leaf') {
    # Repair Edge
    Start-Process -FilePath 'C:\Program Files (x86)\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe' -ArgumentList '/install', 'appguid={56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}&appname=Microsoft%20Edge&needsadmin=true&repairtype=windowsonlinerepair', '/installsource', 'windowsupdate', '/silent' -Wait
}

# Get a list of installed Google Chrome version(s)
[System.IO.DirectoryInfo]$ChromeDirList = Get-ChildItem -Directory -Path 'C:\Program Files\Google\Chrome\Application' | Where-Object -FilterScript { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' }

# Loop through each Google Chrome version and reinstall it
foreach ($ChromeVersion in $ChromeDirList) {
    Start-Process -FilePath "$($ChromeVersion.FullName)\Installer\setup.exe" -ArgumentList '--install', '--channel=stable', '--system-level', '--verbose-logging' -Wait
}

# Check if VS Code is installed
if (Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{EA457B21-F73E-494C-ACAB-524FDE069978}_is1') {
    # Uninstall VS Code
    [System.String]$UninstallString = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{EA457B21-F73E-494C-ACAB-524FDE069978}_is1').'QuietUninstallString'
    
    # Extract the arguments for uninstalling VS Code
    [System.String[]]$ParsedUninstallString = $UninstallString -split '" '

    # Download the latest VS code
    Invoke-WebRequest -Uri "https://code.visualstudio.com/sha/download?build=stable&os=win32$(if ($Architecture -eq 'x64') {'-x64'})" -OutFile '.\VSCode.exe'

    # Uninstall VS Code
    Start-Process -FilePath ($ParsedUninstallString[0] -replace '"', '') -ArgumentList ($ParsedUninstallString[1] -split ' ') -Wait

    # Install VS Code
    Start-Process -FilePath '.\VSCode.exe' -ArgumentList '/VerySilent', '/MergeTasks=!RunCode' -Wait
    
    # Delete the VS Code installer
    Remove-Item -Path '.\VSCode.exe'
}
