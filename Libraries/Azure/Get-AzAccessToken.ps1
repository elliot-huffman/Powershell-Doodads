<#
.SYNOPSIS
    Retrieves the access token for the Azure REST API.
.DESCRIPTION
    Grabs the Access Token for the Azure REST API.
    This library can accept a subscription ID for tenant identification.
    Otherwise, it takes the first subscription and uses the associated tenant ID.
.PARAMETER Account
    Accepts a user account context session, otherwise establishes its own session.
    If a context is not specified, a log in process will be launched.
.PARAMETER TenantID
    Accepts a Tenant ID, does not require subscription id if specified.
    Data format is in GUID format: "00000000-0000-0000-0000-000000000000".
    If a GUID type is not specified, a type cast will be attempted.
.PARAMETER SubscriptionID
    Accepts a subscription ID to use as the reference to retrieve the tenant ID for the specified subscription.
    It will automatically detect the tenant that the subscription resides in and use that for the access token.
    Data format is in GUID format: "00000000-0000-0000-0000-000000000000".
    If a GUID type is not specified, a type cast will be attempted.
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

# Specify the output type of the script
[OutputType([System.String])]
# Bind to cmdlet type and expose common parameters
[CmdletBinding(DefaultParameterSetName = 'TenantID')]
param(
    [Parameter(
        # Parameter can be omitted
        Mandatory = $false,
        # Parameter is the first positional parameter if used positionally
        Position = 0,
        # The below two value from pipeline options make it so that pipeline automatic matching magic happens
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    # Ensures that a user doesn't send a empty value to the parameter (this would cause issues)
    [ValidateNotNullOrEmpty()]
    # Validate user input by statically typing the variable (parameter name) and setting a default value if not specified
    [Microsoft.Azure.Commands.Profile.Models.Core.PSAzureProfile]$Account = (Connect-AzAccount),
    [Parameter(
        # Parameter can be omitted
        Mandatory = $false,
        # Parameter is the second positional parameter if used positionally
        Position = 1,
        # Set a parameter group so that if the user specifies TenantID or SubscriptionID as a parameter, it will lock
        ParameterSetName = "TenantID",
        # The below two value from pipeline options make it so that pipeline automatic matching magic happens
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    # Ensures that a user doesn't send a empty value to the parameter (this would cause issues)
    [ValidateNotNullOrEmpty()]
    # Validate user input by statically typing the variable (parameter name)
    [System.Guid]$TenantID,
    [Parameter(
        # Parameter can be omitted
        Mandatory = $false,
        # Parameter is the second positional parameter if used positionally
        Position = 1,
        # Set a parameter group so that if the user specifies TenantID or SubscriptionID as a parameter, it will lock the user out from using the other parameter to avoid a conflict
        ParameterSetName = "SubscriptionID",
        # The below two value from pipeline options make it so that pipeline automatic matching magic happens
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    # Ensures that a user doesn't send a empty value to the parameter (this would cause issues)
    [ValidateNotNullOrEmpty()]
    # Validate user input by statically typing the variable (parameter name)
    [System.Guid]$SubscriptionID = (Get-AzSubscription)[0].Id
)

begin {
# Set up the environment
    # Verbose status output
    Write-Verbose -Message "Checking account context"

    # Check if the $Account context is populated
    if ($Account -IsNot [Microsoft.Azure.Commands.Profile.Models.Core.PSAzureProfile]) {
        Write-Error "User is not logged in, please log in!"
        exit 1
    }
}

process {
# Execute the token retrieval process
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