<#
.SYNOPSIS
    Retrieves the access token for the Azure REST API.
.DESCRIPTION
    Grabs the Access Token for the Azure REST API.
    This library can accept a subscription ID for tenant identification.
    Otherwise, it takes the first subscription and uses the associated tenant ID.
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    This script requires the Az.Accounts module to be installed.
#>
#Requires -Modules Az.Accounts

$Account = Connect-AzAccount
$TenantID = (Get-AzSubscription -SubscriptionId "e5b8499c-217c-4eef-b3e8-4942085b6a51").TenantId
$Tokens = $account.Context.TokenCache.ReadItems()
$FilteredTokens = $Tokens | Where-Object -FilterScript {$_.TenantId -eq $TenantID} | Sort-Object -Property ExpiresOn -Descending

# $apiVersion = "2017-05-10"
# Invoke-RestMethod -Method Get `
#                   -Uri ("https://management.azure.com/subscriptions/" + $subscriptionId +
#                         "/resourcegroups" +
#                         "?api-version=" + $apiVersion) `
#                   -Headers @{ "Authorization" = "Bearer " + $accessToken }
