param(
    [String]$Permission = "Domain.Read.All",
    [GUID]$ManagedIdentityGUID
)

#Requires -Module AzureAD

# Get an instance of the MS Graph App
$GraphServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"

# Extract the ID of the Role that the MI will get in the MS Graph API
$AppRole = ($GraphServicePrincipal.AppRoles | Where-Object -FilterScript {($_.Value -eq $Permission) -and ($_.AllowedMemberTypes -eq "Application")}).ID

# Grant the Managed Identity the permission
New-AzureAdServiceAppRoleAssignment -ObjectId $ManagedIdentityGUID -PrincipalId $ManagedIdentityGUID -ResourceId $GraphServicePrincipal.ObjectId -Id $AppRole