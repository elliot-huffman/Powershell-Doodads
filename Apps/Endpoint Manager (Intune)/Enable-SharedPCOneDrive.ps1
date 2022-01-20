<#
.SYNOPSIS
    Enables OneDrive on the target computer and prevents GPO/CSP from disabling it.
.DESCRIPTION
    This script is only meant for SharedPC configurations where OneDrive needs to be enabled.
    Shared PC configurations disable OneDrive as a mandatory configuration.
    This script enabled OneDrive and forces the registry key to not be able to be modified by the system by setting an ACL deny rule for modification of the key.
    This prevents the CSP and GPO systems from disabling OneDrive through the registry key.
.EXAMPLE
    PS C:\> .\Enable-SharedPCOneDrive.ps1
    Enables OneDrive and locks the Registry Key from GPO/CSP modification.
    Read access is still allowed to the key.
.OUTPUTS
    Void
.NOTES
    Requires Admin Rights
#>

#Requires -RunAsAdministrator

# Cmdlet bind the script to support advanced operations
[CmdletBinding(SupportsShouldProcess=$true)]

# Define the OneDrive path
[System.String]$OneDrive = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"

# Write debugging info if requested
Write-Debug -Message "`$OneDrive Value: $OneDrive"

# Verbose info about current step
Write-Verbose -Message "Creating the OneDrive Policy Key in the registry"

# Validate that the key exists
if (-not (Test-Path -Path $OneDrive -PathType "Container")) {
    # Simulate the command if requested
    if ($PSCmdlet.ShouldProcess("Registry", "Create OneDrive Policy Key")) {
        # Create the key if it does not exist
        New-Item -Path $OneDrive
    }
}

# Verbose info about current step
Write-Verbose -Message "Setting DisableFileSyncNGSC Value in the OneDrive Policy Key"

# Simulate the command if requested
if ($PSCmdlet.ShouldProcess("OneDrive Policy Key", "Set DisableFileSyncNGSC Value")) {
    # Set the OneDrive enable key
    Set-ItemProperty -Path $OneDrive -Name "DisableFileSyncNGSC" -Value 0
}

# Verbose info about current step
Write-Verbose -Message "Getting current ACL and storing in memory"

# Get the current ACL object
[System.Security.AccessControl.RegistrySecurity]$CurrentACL = Get-Acl -Path $OneDrive

# Write debugging info if requested
Write-Debug -Message "`$CurrentACL Value: $CurrentACL"

# Verbose info about current step
Write-Verbose -Message "Generating new ACL Node in memory"

# Create the new ACL Node
[System.Security.AccessControl.RegistryAccessRule]$NewACL = [System.Security.AccessControl.RegistryAccessRule]::new("NT AUTHORITY\SYSTEM", @("SetValue", "CreateSubKey", "Delete", "ChangePermissions", "TakeOwnership"), "Deny")

Write-Debug -Message "`$NewACL Value: $NewACL"

# Verbose info about current step
Write-Verbose -Message "Adding new ACL node to memory copy of current registry ACL"

# Add the new node to the existing rule set in memory
$CurrentACL.SetAccessRule($NewACL)

# Write debugging info if requested
Write-Debug -Message "`$CurrentACL Value: $CurrentACL"

# Verbose info about current step
Write-Verbose -Message "Writing the current copy of the ACL object in memory to the disk"

# Simulate the command if requested
if ($PSCmdlet.ShouldProcess("Registry", "Add New ACL")) {
    # Save the ACLs from memory to the disk
    $CurrentACL | Set-Acl -Path $OneDrive
}

# Verbose info about current step
Write-Verbose -Message "Execution complete!"