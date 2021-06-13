<#
.SYNOPSIS
    Grants Graph API Permissions to MAnaged Identity Service Principals
.DESCRIPTION
    App registration is not supported as it has a really good GUI in the Azure AD Portal.
.EXAMPLE
    PS C:\> Grant-MIGraphPermission
    Explanation of what the example does
.INPUTS
    GUID
    System.String
.OUTPUTS
    Void
.NOTES
    This script requries the AzureAD module to be installed before execution.
    PS Core 6 is not supported for this script since it utilizes Windows Forms.
    ISE must be installed as some PowerShell Windows Forms components are included in ISE that this script uses (Out-GridView)
    
    Exit Codes:
        1 - lorem ipsum
#>

# Ensure the appropriate pre-reqs for the script
#Requires -Module AzureAD
#Requires -PSEdition Desktop

# Cmdlet bind script so that it can perform advanced operations
[CmdletBinding(
    DefaultParameterSetName='GUI Selector',
    SupportsShouldProcess=$true
)]

# Initialize the parameters for the script
param(
    [Parameter(
        Mandatory=$true,
        ParameterSetName='Manual ID'
    )]
    [ValidateNotNullOrEmpty()]
    [GUID]$ObjectID,
    [Parameter(
        Mandatory=$true,
        ParameterSetName='Manual ID'
    )]
    [ValidateNotNullOrEmpty()]
    [System.String]$PermissionName,
    [Parameter(
        Mandatory=$true,
        ParameterSetName='GUI Selector'
    )]
    [Switch]$GUI
)

begin {
    # Stop execution on error
    $ErrorActionPreference = "Stop"

    # Write Verbose info
    Write-Verbose -Message "Logging into Azure AD"
    
    # Log into Azure AD
    [Microsoft.Open.Azure.AD.CommonLibrary.PSAzureContext]$AzureADSession = Connect-AzureAD

    # Write debug info
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Graph API SP Info:"
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$AzureADSession: $AzureADSession"

    # Write Verbose info
    Write-Verbose -Message "Getting an instance of the Graph API App Service Principal"

    # Get the GraphAPI instance
    [Microsoft.Open.AzureAD.Model.ServicePrincipal]$GraphAppSP = Get-AzureADServicePrincipal -Filter "AppID eq '00000003-0000-0000-c000-000000000000'"

    # Write debug info
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Graph API SP Info:"
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$GraphAppSP: $GraphAppSP"

    # Check to see if the GUI was requested
    if ($GUI) {
        # Get a list of Managed Identities and make the user select one of them
        [Microsoft.Open.AzureAD.Model.ServicePrincipal]$SelectedPrincipal = Get-AzureADServicePrincipal -Filter "ServicePrincipalType eq 'ManagedIdentity'" -All $true | Out-GridView -Title "Select the Managed Identity to Assign Permission" -OutputMode "Single"
        
        # Get the specified permission that needs to be assigned
        [Microsoft.Open.AzureAD.Model.AppRole]$AppRole = $GraphAppSP.AppRoles | Out-GridView -Title "Select the Permission to Assign" -OutputMode "Single"
    } else {
        # Pull the specified Object ID
        [Microsoft.Open.AzureAD.Model.ServicePrincipal]$SelectedPrincipal = Get-AzureADServicePrincipal -ObjectId $ObjectID

        # Get the specified permission that needs to be assigned
        [Microsoft.Open.AzureAD.Model.AppRole]$AppRole = $GraphAppSP.AppRoles | Where-Object -FilterScript {$_.Value -eq $PermissionName}
    }

    if ($PSCmdlet.ShouldProcess("Selected Service Principal", "Grant ${$AppRole.Value}")) {
        
    }
    # Assign the Graph API permission to the specified service principal
    New-AzureAdServiceAppRoleAssignment -ObjectId $SelectedPrincipal.ObjectId -PrincipalId $SelectedPrincipal.ObjectId -ResourceId $GraphAppSP.ObjectId -Id $AppRole.Id
}

end {
    # Log out of Azure AD
    Disconnect-AzureAD
}