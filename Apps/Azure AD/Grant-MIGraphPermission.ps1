<#PSScriptInfo

.VERSION 1.0.6

.GUID 0b801f6d-e4f2-4968-a5d2-d959dc0dd7c5

.AUTHOR Elliot Huffman

.COMPANYNAME

.COPYRIGHT Elliot Huffman 2022

.TAGS Azure AD AAD IAM Identity_And_Access_Management MI Managed_Identity

.LICENSEURI https://github.com/elliot-huffman/Powershell-Doodads/blob/main/LICENSE

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES Microsoft.Graph.Authentication,Microsoft.Graph.Applications 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
1.0.6: Change to Microsoft.Graph.Beta to support new features.
1.0.5: Disable access token validation since it is not working with Install-PSM. Will be re-enabled later.
1.0.4: Fix a bug where the Get-MgServicePrincipal changed requiring the use of a switch type for the 'All' parameter.

.PRIVATEDATA

#> 

#Requires -Module Microsoft.Graph.Authentication
#Requires -Module Microsoft.Graph.Beta.Applications

# Ensure the appropriate pre-requirements for the script


<#
.SYNOPSIS
    Grants Graph API Permissions to Managed Identity Service Principals
.DESCRIPTION
    Grants API permissions to managed identities. The default setting is the MS Graph API but other APIs registered in Azure AD are supported. Such as MDE, EXO, etc.
    Returns false on failure
.EXAMPLE
    PS C:\> Grant-MIGraphPermission
    Launches the GUI to walk the user through picking out the API permissions to grant to a Managed Identity
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
        - Microsoft Graph API: 00000003-0000-0000-c000-000000000000
        - Defender for Endpoint: fc780465-2017-40d4-a0c5-307022471b92
        - Defender for Cloud Apps: 05a65629-4c1b-48c1-a78b-804c4abdd4af
        - Exchange Online: 00000002-0000-0ff1-ce00-000000000000
        - SharePoint Online: 00000003-0000-0ff1-ce00-000000000000
        - Yammer: 00000005-0000-0ff1-ce00-000000000000
        - Universal Print: da9b70f6-5323-4ce6-ae5c-88dcc5082966
.PARAMETER AccessToken
    This parameter is used to pass an access token into this script rather than going through the authentication process via GUI.
    This is useful for fully automated processes that are able to provide their own access tokens and run this script without human interaction.
    
    The audience should be "https://graph.microsoft.com" for the token, otherwise it won't work.
    There is input validation to help catch access tokens that don't have the correct audience.
    
    The access token should minimally have the scopes (permissions) of 'Directory.Read.All', 'AppRoleAssignment.ReadWrite.All', and 'Application.ReadWrite.All'.
    Scopes that have these basic set of permissions or greater will work (e.g. Global Admin).
    
    Example use cases:
        - CI/CD Pipeline
        - Dot Sourced Loading this script from another
.INPUTS
    Switch
    System.GUID
    System.GUID[]
    System.String
    System.String[]
.OUTPUTS
    System.Boolean
.NOTES
    This script requires the Microsoft.Graph.Authentication and Microsoft.Graph.Applications modules to be installed before execution.
    If the GUI mode is to be used, ISE must be installed as some Windows Forms components are included in ISE that this script uses (Out-GridView).

    This script requires the minimum Azure AD permissions of:
        - Directory.Read.All
        - AppRoleAssignment.ReadWrite.All
        - Application.ReadWrite.All
    These permission may be granted by a more widely scoped permission such as "Global admin" or "Directory.ReadWrite.All", etc..
#>

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
    [System.GUID]$GraphServicePrincipalID = '00000003-0000-0000-c000-000000000000',
    # [ValidateScript({ ([System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String(($_ -split '\.')[1])) | ConvertFrom-Json).aud -eq 'https://graph.microsoft.com' })]
    [System.Security.SecureString]$AccessToken
)

# Initialize processing
begin {
    # Stop execution on error
    $ErrorActionPreference = 'Stop'

    # Write Verbose info
    Write-Verbose -Message 'Logging into Azure AD'
    
    # Check if an access token has been provided
    if ($null -ne $AccessToken) {
        # Log into the Graph API using the provided access token
        Connect-MgGraph -AccessToken $AccessToken
    } else {
        # Log into the Graph API using Azure AD authentication
        Connect-MgGraph -Scopes 'Directory.Read.All', 'AppRoleAssignment.ReadWrite.All', 'Application.ReadWrite.All'
    }

    # Write Verbose info
    Write-Verbose -Message 'Calculating GUI or CLI mode'

    # Check to see if GUI mode is forced or necessary
    if ($CLIMode) {
        # If CLI mode is $true, the operator is forcing the execution of no GUI in headless only
        [System.Boolean]$GUIMode = $false
    } elseif (!$ObjectID -or !$PermissionName) {
        # If the ObjectID or PermissionName parameters are not specified and the script is not forced CLI only, GUI is implied.
        [System.Boolean]$GUIMode = $true
    } else {
        # If the parameters are present as expected, set the GUI mode to be off as no user selection is necessary.
        [System.Boolean]$GUIMode = $false
    }
}

# Process each object passed on the command line
process {
    # Write Verbose info
    Write-Verbose -Message 'Getting an instance of the Graph API App Service Principal'

    # Get the GraphAPI instance
    [Microsoft.Graph.Beta.PowerShell.Models.MicrosoftGraphServicePrincipal]$GraphAppSP = Get-MgBetaServicePrincipal -Filter "AppID eq '$GraphServicePrincipalID'"

    # Write debug info
    Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss') - Graph API SP Info:"
    Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss') - `$GraphAppSP: $GraphAppSP"

    # If in GUI mode
    if ($GUIMode) {
        # Write Verbose info
        Write-Verbose -Message 'Getting a list of all managed identities and render it in a picker dialog for the end user to select one.'

        # Get a list of Managed Identities and make the user select one of them
        [Microsoft.Graph.Beta.PowerShell.Models.MicrosoftGraphServicePrincipal[]]$SelectedPrincipalList = Get-MgBetaServicePrincipal -Filter "ServicePrincipalType eq 'ManagedIdentity'" -All | Out-GridView -Title 'Select the Managed Identity to Assign Permission' -OutputMode 'Multiple'
    } else {
        # Write Verbose info
        Write-Verbose -Message 'Getting the specified service principal.'

        # Loop through each ID specified and save the results into a new list.
        foreach ($GUID in $ObjectID) {
            # Pull the specified Object ID's graph object
            [Microsoft.Graph.Beta.PowerShell.Models.MicrosoftGraphServicePrincipal[]]$SelectedPrincipalList += Get-MgBetaServicePrincipal -ServicePrincipalId $GUID
        }
    }

    # Write debug info
    Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss') - Selected Principal List:"
    Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss') - `$SelectedPrincipal: $SelectedPrincipalList"

    # Write Verbose info
    Write-Verbose -Message 'Validating principal selection was successful'
        
    # Throw an error and end execution if the end user doesn't select an object
    if (($null -eq $SelectedPrincipalList) -or ($SelectedPrincipalList.Count -eq 0)) {
        # Write an error to the console
        Write-Error -Message 'No principals were selected successfully.
        If GUI was used, this usually indicates that the end user closed the dialog.
        If CLI was used, ths was most likely due to an incorrect GUID.'

        # Return false to the caller to indicate failure
        return $false
    }

    # Route execution based on GUI mode
    if ($GUIMode) {
        # Write Verbose info
        Write-Verbose -Message 'Getting a list of all app roles/permissions and render it in a picker dialog for the end user to select one.'

        # Get the specified permission that needs to be assigned
        [Microsoft.Graph.Beta.PowerShell.Models.MicrosoftGraphAppRole[]]$AppRoleList = $GraphAppSP.AppRoles | Out-GridView -Title 'Select the Permission to Assign' -OutputMode 'Multiple'
    } else {
        # Write Verbose info
        Write-Verbose -Message 'Getting the specified app role/permission'

        # Loop through each permission requested and enrich the permission provided with system context
        foreach ($RoleName in $PermissionName) {
            # Add each context instance to the app role list
            [Microsoft.Graph.Beta.PowerShell.Models.MicrosoftGraphAppRole[]]$AppRoleList += $GraphAppSP.AppRoles | Where-Object -FilterScript { $_.Value -eq $RoleName }
        }         
    }

    # Write debug info
    Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss') - List of selected app roles/permissions:"
    Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss') - `$AppRoleList: $AppRoleList"


    # Write Verbose info
    Write-Verbose -Message 'Validating role selection was successful'

    # Throw an error and end execution if the end user doesn't select an object
    if (($null -eq $AppRoleList) -or ($AppRoleList.Count -eq 0)) {
        # Write an error to the console
        Write-Error -Message 'No API roles were selected successfully.
        If GUI was used, this usually indicates that the end user closed the dialog.
        If CLI was used, ths was most likely due to an incorrect permission name being specified.'

        # Return false to the caller to indicate failure
        return $false
    }

    # Write Verbose info
    Write-Verbose -Message 'Assigning the specified permission to the specified principal'

    # Loop through each principal specified and perform the specified role assignment
    foreach ($Principal in $SelectedPrincipalList) {
        # Loop through each of the selected app roles and assign the role to the specified principal
        foreach ($Role in $AppRoleList) {
            # Simulate the result if asked to simulate
            if ($PSCmdlet.ShouldProcess('Selected Service Principal', "Grant $($Role.Value)")) {
                # Write debug info
                Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss') - Pre-Assignment Variable Dump:"
                Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss') - `$Principal.ObjectId: $($Principal.Id)"
                Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss') - `$GraphAppSP.ObjectId: $($GraphAppSP.Id)"
                Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss') - `$Role.Id: $($Role.Id)"

                # Assign the Graph API permission to the specified service principal
                New-MgBetaServicePrincipalAppRoleAssignment -PrincipalId $Principal.Id -ServicePrincipalId $Principal.Id -AppRoleId $Role.Id -ResourceId $GraphAppSP.Id
            }
        }
    }
}

# Run the necessary cleanup commands after processing is complete
end {
    # Log out of the session
    Disconnect-MgGraph
}
