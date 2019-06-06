<#
.SYNOPSIS
    Retrieves the access token for the Azure REST API.
.DESCRIPTION
    Grabs the Access Token for the Azure REST API.
    This library can accept a subscription ID for tenant identification.
    Otherwise, it takes the first subscription and uses the associated tenant ID.
.EXAMPLE
    PS C:\> Get-AzAccessToken
    Prompts the user for their Azure credentials and uses the context to retrieve a list of all subscriptions.
    Takes the top subscription and uses that to calculate the tenant id.
    It then uses the tenant id in a filter search of the current azure session's token cache to get the access token.
    The access token is returned as a string.
.EXAMPLE
    PS C:\> Get-AzAccessToken -Account (Connect-AzAccount)
    The script takes the output of the Connect-AzAccount cmdlet.
    Because of this, the script does not prompt for credential itself, it uses the credentials and context provided by the input.
.EXAMPLE
    PS C:\> Get-AzAccessToken -TenantID "fa5f4980-7932-44eb-b464-18de66c616ad"
    Prompts the user for their Azure credentials and stores the context.
    The script uses the tenant id specified to find the appropriate access token.
    This executes faster than letting the system identify a subscription to use as context.
.EXAMPLE
    PS C:\> Get-AzAccessToken -SubscriptionID "5823e060-075d-4447-aa2d-3472e41ed362"
    Prompts the user for their Azure credentials and stores the context.
    The script uses the subscription id specified to find the tenant that houses the subscription.
    The script then uses the tenant id in a filter search of the tokens and returns the appropriate access token as a string.
.INPUTS
    Microsoft.Azure.Commands.Profile.Models.Core.PSAzureProfile
    System.Guid
.OUTPUTS
    System.String
.NOTES
    This script requires the Az.Accounts module to be installed.
.LINK
    https://github.com/elliot-labs/Powershell-Doodads/
#>

#Requires -Modules Az.Accounts

[OutputType([System.String])]
[CmdletBinding(DefaultParameterSetName='TenantID')]
param(
    # Accepts a user account context session, otherwise establishes its own session
    [Parameter(
        Mandatory = $false,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "Account context"
    )]
    [ValidateNotNullOrEmpty()]
    [Microsoft.Azure.Commands.Profile.Models.Core.PSAzureProfile]$Account = (Connect-AzAccount),
    # Accepts a Tenant ID, does not require subscription id if specified
    [Parameter(
        Mandatory = $false,
        Position = 1,
        ParameterSetName = "TenantID",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "Tenant ID to get access token for"
    )]
    [ValidateNotNullOrEmpty()]
    [System.Guid]$TenantID,
    # Accepts a subscription id to use as the reference to retrieve the tenant id for
    [Parameter(
        Mandatory = $false,
        Position = 1,
        ParameterSetName = "SubscriptionID",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "Subscription ID to get tenant ID for tenant id extraction"
    )]
    [ValidateNotNullOrEmpty()]
    [System.Guid]$SubscriptionID = (Get-AzSubscription)[0].Id
)

# Verbose status output
Write-Verbose -Message "Checking account context"

# Check if the $Account context is populated
if ($null -eq $Account) {
    # Verbose status output
    Write-Verbose -Message "Logging into the Azure account and storing the context"

    # Catch authentication errors and if there are any, exit the script
    try {
        # If the account parameter is not populated with data, log in and store the login context
        $Account = Connect-AzAccount
    }
    catch {
        Write-Error "Log in failed, exiting script"
        exit 1
    }    
}

# Verbose status output
Write-Verbose -Message "Checking tenant ID"

# If the Tenant ID has not been specified, calculate it
if ($null -eq $TenantID) {
    # Verbose status output
    Write-Verbose -Message "Extracting Tenant ID from current subscription context"

    # Retrieve the Tenant ID by using the subscription's id to identify the subscription context
    $TenantID = (Get-AzSubscription -SubscriptionId $SubscriptionID).TenantId
}

# Verbose status output
Write-Verbose -Message "Tenant ID is ready"

# Verbose status output
Write-Verbose -Message "Extracting tokens from context"

# Use the current account context to retrieve all the tokens currently available
$Tokens = $Account.Context.TokenCache.ReadItems()

# Verbose status output
Write-Verbose -Message "Filtering and sorting tokens"

# Filter the listed tokens to only the ones that apply to the current tenant and list them in descending order based upon expiration date
$FilteredTokens = $Tokens | Where-Object -FilterScript {$_.TenantId -eq $TenantID} | Sort-Object -Property ExpiresOn -Descending

# Verbose status output
Write-Verbose -Message "Extracting access token"

# Extract the access token
$AccessToken = $FilteredTokens[0].AccessToken

# Verbose status output
Write-Verbose -Message "Returning access token"

# Return the access token
Return $AccessToken
