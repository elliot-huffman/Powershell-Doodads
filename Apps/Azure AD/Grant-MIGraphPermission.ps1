<#
.SYNOPSIS
    Grants Graph API Permissions to MAnaged Identity Service Principals
.DESCRIPTION
    App registration is not supported as it has a really good GUI in the Azure AD Portal.
    Returns false on failure
.EXAMPLE
    PS C:\> Grant-MIGraphPermission
    Explanation of what the example does
.PARAMETER CLIMode
    This switch forces the suppression of GUI elements and forces headless mode.
    This is useful if used in an automation system where a GUI will gum up the works.
    Errors will be thrown if a required param is not specified in CLI only mode.
.PARAMETER ObjectID
    This is the identity that is going to have the permission granted to it.
    By default the GUI returns a list of managed identities however this can be any service principal.
.PARAMETER PermissionName
    This is the display name of the permission the be granted to the target ObjectID.
.PARAMETER GraphServicePrincipalID
    This is the GUID of the service principal that is the permissions provider.
    By default the service provider is the Microsoft Graph API, however you can grant permissions on other providers too by providing their GUID.
    Common providers are as below:
    Microsoft Graph API: 00000003-0000-0000-c000-000000000000
    Defender for Endpoint: fc780465-2017-40d4-a0c5-307022471b92
    Defender for Cloud Apps: 05a65629-4c1b-48c1-a78b-804c4abdd4af
    SharePoint Online: 00000003-0000-0ff1-ce00-000000000000
    Yammer: 00000005-0000-0ff1-ce00-000000000000
    Universal Print: da9b70f6-5323-4ce6-ae5c-88dcc5082966
.INPUTS
    Switch
    System.GUID
    System.GUID[]
    System.String[]
.OUTPUTS
    System.Boolean
.NOTES
    This script requires the AzureAD module to be installed before execution.
    PS Core 6 is not supported for this script since it utilizes Windows Forms.
    ISE must be installed as some PowerShell Windows Forms components are included in ISE that this script uses (Out-GridView)
    
    Exit Codes:
        1 - lorem ipsum
#>

# Ensure the appropriate pre-requirements for the script
#Requires -Module AzureAD
#Requires -PSEdition Desktop

# Cmdlet bind script so that it can perform advanced operations
[CmdletBinding(
    DefaultParameterSetName = 'GUI Mode',
    SupportsShouldProcess = $true
)]

# Initialize the parameters for the script
param(
    [Parameter(
        Mandatory = $true,
        Position = 0,
        ParameterSetName = 'CLI Mode'
    )]
    [Switch]$CLIMode,
    [Parameter(
        Mandatory = $true,
        Position = 1,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ParameterSetName = 'CLI Mode'
    )]
    [Parameter(ParameterSetName = 'GUI Mode')]
    [ValidateNotNullOrEmpty()]
    [System.GUID[]]$ObjectID,
    [Parameter(
        Mandatory = $true,
        Position = 2,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ParameterSetName = 'CLI Mode'
    )]
    [Parameter(ParameterSetName = 'GUI Mode')]
    [ValidateNotNullOrEmpty()]
    [System.String[]]$PermissionName,
    [ValidateNotNullOrEmpty()]
    [System.GUID]$GraphServicePrincipalID = "00000003-0000-0000-c000-000000000000"
)

# Initialize processing
begin {
    # Stop execution on error
    $ErrorActionPreference = "Stop"

    # Write Verbose info
    Write-Verbose -Message "Logging into Azure AD"
    
    # Log into Azure AD
    [Microsoft.Open.Azure.AD.CommonLibrary.PSAzureContext]$AzureADSession = Connect-AzureAD

    # Write debug info
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Session Info:"
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$AzureADSession: $AzureADSession"

    # Check to see if GUI mode is forced or necessary
    if ($CLIMode) {
        # If CLI mode is $true, the operator is forcing the execution of no GUI in headless only
        [System.Boolean]$GUIMode = $false
    }
    elseif (!$ObjectID -or !$PermissionName) {
        # If the ObjectID or PermissionName parameters are not specified and the script is not forced CLI only, GUI is implied.
        [System.Boolean]$GUIMode = $true
    }
    else {
        # If the parameters are present as expected, set the GUI mode to be off as no user selection is necessary.
        [System.Boolean]$GUIMode = $false
    }
}

# Process each object passed on the command line
process {
    # Write Verbose info
    Write-Verbose -Message "Getting an instance of the Graph API App Service Principal"

    # Get the GraphAPI instance
    [Microsoft.Open.AzureAD.Model.ServicePrincipal]$GraphAppSP = Get-AzureADServicePrincipal -Filter "AppID eq '$GraphServicePrincipalID'"

    # Write debug info
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Graph API SP Info:"
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$GraphAppSP: $GraphAppSP"

    # If in GUI mode
    if ($GUIMode) {
        # Write Verbose info
        Write-Verbose -Message "Getting a list of all managed identities and render it in a picker dialog for the end user to select one."

        # Get a list of Managed Identities and make the user select one of them
        [Microsoft.Open.AzureAD.Model.ServicePrincipal[]]$SelectedPrincipalList = Get-AzureADServicePrincipal -Filter "ServicePrincipalType eq 'ManagedIdentity'" -All $true | Out-GridView -Title "Select the Managed Identity to Assign Permission" -OutputMode "Multiple"
    } else {
        # Write Verbose info
        Write-Verbose -Message "Getting the specified service principal."

        # Pull the specified Object ID
        [Microsoft.Open.AzureAD.Model.ServicePrincipal[]]$SelectedPrincipalList = Get-AzureADServicePrincipal -ObjectId $ObjectID
    }

    # Write debug info
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Selected Principal List:"
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$SelectedPrincipal: $SelectedPrincipalList"

    # Write Verbose info
    Write-Verbose -Message "Validating principal selection was successful"
        
    # Throw an error and end execution if the end user doesn't select an object
    if ($null -eq $SelectedPrincipalList) {
        # Write an error to the console
        Write-Error -Message "No principals were selected successfully.
        If GUI was used, this usually indicates that the end user closed the dialog.
        If CLI was used, ths was most likely due to an incorrect GUID."

        # Return false to the caller to indicate failure
        return $false
    }

    # Route execution based on GUI mode
    if ($GUIMode) {
        # Write Verbose info
        Write-Verbose -Message "Getting a list of all app roles/permissions and render it in a picker dialog for the end user to select one."

        # Get the specified permission that needs to be assigned
        [Microsoft.Open.AzureAD.Model.AppRole[]]$AppRoleList = $GraphAppSP.AppRoles | Out-GridView -Title "Select the Permission to Assign" -OutputMode "Multiple"
    } else {
        # Write Verbose info
        Write-Verbose -Message "Getting the specified app role/permission"

        # Loop through each permission requested and enrich the permission provided with system context
        foreach ($RoleName in $PermissionName) {
            # Add each context instance to the app role list
            [Microsoft.Open.AzureAD.Model.AppRole[]]$AppRoleList += $GraphAppSP.AppRoles | Where-Object -FilterScript { $_.Value -eq $RoleName }
        }         
    }

    # Write debug info
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - List of selected app roles/permissions:"
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$AppRoleList: $AppRoleList"


    # Write Verbose info
    Write-Verbose -Message "Validating role selection was successful"

    # Throw an error and end execution if the end user doesn't select an object
    if ($null -eq $AppRoleList) {
        # Write an error to the console
        Write-Error -Message "No API roles were selected successfully.
        If GUI was used, this usually indicates that the end user closed the dialog.
        If CLI was used, ths was most likely due to an incorrect permission name being specified."

        # Return false to the caller to indicate failure
        return $false
    }

    # Write Verbose info
    Write-Verbose -Message "Assigning the specified permission to the specified principal"

    # Loop through each principal specified and perform the specified role assignment
    foreach ($Principal in $SelectedPrincipalList) {
        # Loop through each of the selected app roles and assign the role to the specified principal
        foreach ($Role in $AppRoleList) {
            # Simulate the result if asked to simulate
            if ($PSCmdlet.ShouldProcess("Selected Service Principal", "Grant $($Role.Value)")) {
                # Write debug info
                Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Pre-Assignment Variable Dump:"
                Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$Principal.ObjectId: $($Principal.ObjectId)"
                Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$GraphAppSP.ObjectId: $($GraphAppSP.ObjectId)"
                Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$Role.Id: $($Role.Id)"

                # Assign the Graph API permission to the specified service principal
                New-AzureAdServiceAppRoleAssignment -ObjectId $Principal.ObjectId -PrincipalId $Principal.ObjectId -ResourceId $GraphAppSP.ObjectId -Id $Role.Id   
            }
        }
    }
}

# Run the necessary cleanup commands after processing is complete
end {
    # Log out of Azure AD
    Disconnect-AzureAD
}