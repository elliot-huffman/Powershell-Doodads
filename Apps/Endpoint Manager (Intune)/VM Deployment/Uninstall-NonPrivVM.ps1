<#
.SYNOPSIS
    Removes the specified VM and its Virtual Hard Disk(s).
.DESCRIPTION
    Removes the specified VM from the local computer and any VHD files that are attached to it.
    The VHD files are removed after the VM has been removed from Hyper-V.
    The VHD files are dynamically detected at runtime by getting a copy of the VM's config and reading the VHD paths from any attached disks.
.PARAMETER VMName
    The name of the VM to be removed from the local computer.
    The default value is "Enterprise" if no value is specified.
.EXAMPLE
    PS C:\> .\Uninstall-NonPrivVM.ps1
    Removes the VM named "Enterprise" and any supporting virtual hard disks from the local computer.
.EXAMPLE
    PS C:\> .\Uninstall-NonPrivVM.ps1 -VMName "Tier 2"
    Removes the VM named "Tier 2" and any supporting virtual hard disks from the local computer.
.INPUTS
    System.String
.OUTPUTS
    Void
.NOTES
    Requires administrator rights
    Requires the Hyper-V module
#>

#Requires -Module Hyper-V

[CmdletBinding(SupportsShouldProcess = $true)]

param(
    [System.String]$VMName = "Enterprise"
)

# List each VHD path attached to the specified VM
[System.String[]]$VhdPathList = (Get-VM -Name $VMName).HardDrives.Path

# Simulate the command if requested
if ($PSCmdlet.ShouldProcess("VM: $VMName", "Remove")) {
    # Removes the specified VM config
    Remove-VM -Name $VMName -Force
}

# Loop through each VHD file present in the list
foreach ($DrivePath in $VhdPathList) {
    # Simulate the command if requested
    if ($PSCmdlet.ShouldProcess("VHD File", "Remove")) {
        # Remove the specified VHD file
        Remove-Item -Path $DrivePath -Force
    }
}