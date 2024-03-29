<#
.SYNOPSIS
    Retrieves the access token for the Azure REST API.
.DESCRIPTION
    Grabs the Access Token for the Azure REST API.
    This library can accept a subscription ID for tenant identification.
    Otherwise, it takes the first subscription and uses the associated tenant ID.
.EXAMPLE
    PS C:\> Get-AzureRMAccessToken
    Prompts the user for their Azure credentials and uses the context to retrieve a list of all subscriptions.
    Takes the top subscription and uses that to calculate the tenant id.
    It then uses the tenant id in a filter search of the current azure session's token cache to get the access token.
    The access token is returned as a string.
.EXAMPLE
    PS C:\> Get-AzureRMAccessToken -Account (Connect-AzureRmAccount)
    The script takes the output of the Connect-AzureRmAccount cmdlet.
    Because of this, the script does not prompt for credential itself, it uses the credentials and context provided by the input.
.EXAMPLE
    PS C:\> Get-AzureRMAccessToken -TenantID "fa5f4980-7932-44eb-b464-18de66c616ad"
    Prompts the user for their Azure credentials and stores the context.
    The script uses the tenant id specified to find the appropriate access token.
    This executes faster than letting the system identify a subscription to use as context.
.EXAMPLE
    PS C:\> Get-AzureRMAccessToken -SubscriptionID "5823e060-075d-4447-aa2d-3472e41ed362"
    Prompts the user for their Azure credentials and stores the context.
    The script uses the subscription id specified to find the tenant that houses the subscription.
    The script then uses the tenant id in a filter search of the tokens and returns the appropriate access token as a string.
.INPUTS
    Microsoft.Azure.Commands.Profile.Models.Core.PSAzureProfile
    System.Guid
.OUTPUTS
    System.String
.LINK
    https://github.com/elliot-labs/Powershell-Doodads/
    Connect-AzureRMAccount
.NOTES
    This script requires the AzureRM.profile module to be installed.

    Exit Codes:
        1 - No Account context, this means that the user has exited the login process or somehow passed a unsupported object to the -Account parameter.
#>

#Requires -Modules AzureRM.profile

[OutputType([System.String])]
[CmdletBinding(DefaultParameterSetName='TenantID')]
param(
    # Accepts a user account context session, otherwise establishes its own session
    [Parameter(
        Mandatory = $false,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [ValidateNotNullOrEmpty()]
    [Microsoft.Azure.Commands.Profile.Models.PSAzureProfile]$Account = (Connect-AzureRmAccount),
    # Accepts a Tenant ID, does not require subscription id if specified
    [Parameter(
        Mandatory = $false,
        Position = 1,
        ParameterSetName = "TenantID",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [ValidateNotNullOrEmpty()]
    [System.Guid]$TenantID,
    # Accepts a subscription id to use as the reference to retrieve the tenant id for
    [Parameter(
        Mandatory = $false,
        Position = 1,
        ParameterSetName = "SubscriptionID",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [ValidateNotNullOrEmpty()]
    [System.Guid]$SubscriptionID = (Get-AzureRmSubscription)[0].Id
)

# Execute the token retrieval process for each object
Process {
    # Verbose status output
    Write-Verbose -Message "Checking account context"

    # Check if the $Account context is populated
    if ($Account -IsNot [Microsoft.Azure.Commands.Profile.Models.PSAzureProfile]) {
        Write-Error "User is not logged in, please log in!"
        exit 1
    }

    # Verbose status output
    Write-Verbose -Message "Checking tenant ID"

    # If the Tenant ID has not been specified, calculate it
    if ($null -eq $TenantID) {
        # Verbose status output
        Write-Verbose -Message "Extracting Tenant ID from current subscription context"

        # Retrieve the Tenant ID by using the subscription's id to identify the subscription context
        $TenantID = (Get-AzureRMSubscription -SubscriptionId $SubscriptionID).TenantId
    }

    # Verbose status output
    Write-Verbose -Message "Tenant ID is ready"

    # Verbose status output
    Write-Verbose -Message "Extracting tokens from context"

    # Use the current account context to retrieve all the tokens currently available
    [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCacheItem[]]$Tokens = $Account.Context.TokenCache.ReadItems()

    # Verbose status output
    Write-Verbose -Message "Filtering and sorting tokens"

    # Filter the listed tokens to only the ones that apply to the current tenant and list them in descending order based upon expiration date
    $FilteredTokens = $Tokens | Where-Object -FilterScript { $_.TenantId -eq $TenantID } | Sort-Object -Property ExpiresOn -Descending

    # Verbose status output
    Write-Verbose -Message "Extracting access token"

    # Extract the access token
    $AccessToken = $FilteredTokens[0].AccessToken

    # Verbose status output
    Write-Verbose -Message "Returning access token"

    # Return the access token
    Return $AccessToken
}