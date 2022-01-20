<#
.SYNOPSIS
    Removes/migrates licenses from user accounts
.DESCRIPTION
    If the old and the new License GUID are present, remove the old license assignment by its GUID.
.PARAMETER NewLicenseGUID
    The license GUID of the license to keep assigned. This will be checked to ensure that it is present on the User's license assignment before removal of the old license.
.PARAMETER OldLicenseGUID
    The license GUID of the license to remove. This will be checked to ensure that it is present on the User's license assignment before removal.
.EXAMPLE
    PS C:\> Remove-DuplicateLicense.ps1 -NewLicenseGUID "634f7402-c1d0-459a-8eae-109b63e22649" -OldLicenseGUID "65786aa5-5b39-49e7-8879-446ef05e67b2"
    Iterates over all users and if the old and the new license are present, remove the old license assignment for the user(s)
.INPUTS
    System.GUID
.OUTPUTS
    Void
.NOTES
    Requires the Microsoft.Graph powershell module to be installed
#>

#Requires -Module Microsoft.Graph

# Allow command simulation
[CmdletBinding(SupportsShouldProcess=$true)]

# Define the default GUID configurations
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [System.Guid]$NewLicenseGUID,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [System.Guid]$OldLicenseGUID
)
 
# Log in to the MS Graph
Connect-MgGraph -Scopes "User.ReadWrite.All"

# Get a list of all users in the logged in tenant
[Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser1[]]$UserList = Get-MgUser -All

# Loop through the user list
foreach ($User in $UserList) {
    # Get the license details for the specified user
    [Microsoft.Graph.PowerShell.Models.MicrosoftGraphLicenseDetails[]]$CurrentLicenseList = Get-MgUserLicenseDetail -UserId $User.UserPrincipalName

    # Check old and the new license are both present
    if (($CurrentLicenseList.SkuId -contains $NewLicenseGUID) -and ($CurrentLicenseList.SkuId -contains $OldLicenseGUID)) {
        # If -WhatIf is specified, simulate command execution without affecting the directory
        if ($PSCmdlet.ShouldProcess("$($User.UserPrincipalName)", "Remove License Assignment: $OldLicenseGUID")) {
            # Remove the old license from the user
            Set-MgUserLicense -RemoveLicenses $OldLicenseGUID
        };
    };
};