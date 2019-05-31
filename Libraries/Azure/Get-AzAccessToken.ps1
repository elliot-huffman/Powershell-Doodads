$Account = Connect-AzAccount
$TenantID = (Get-AzSubscription -SubscriptionId "e5b8499c-217c-4eef-b3e8-4942085b6a51").TenantId
$Tokens = $account.Context.TokenCache.ReadItems()
$FilteredTokens = $Tokens | Where-Object -FilterScript {$_.TenantId -eq $TenantID} | Sort-Object -Property ExpiresOn -Descending
