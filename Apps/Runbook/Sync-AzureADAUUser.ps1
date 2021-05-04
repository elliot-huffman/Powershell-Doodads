<#
.SYNOPSIS
    Add the specified users based upon UPN matching to the specified AU.
.DESCRIPTION
    This script is meant to be run from an Automation Account with a managed identity assigned to it.
    The managed identity needs to have "AdministrativeUnit.ReadWrite.All" and "User.Read.All" assigned to it.
.PARAMETER AdminUnitID
    This parameter is the GUID/ObjectID of the Administrative Unit that needs to have the users synced to.
.PARAMETER UPNBlobMatchString
    This parameter is used to specify the positive match of the UPN.
    A positive match will add a user to the list of users to be synced.
    A negative match will override a positive match.
    E.g. "*@elliot-labs.com" will match any UPN that has @elliot-labs.com at the end of it, for example ehuffman@elliot-labs.com will match.
.PARAMETER UPNNegativeBlobMatch
    This parameter is used to specify the negative match of the UPN.
    A negative match will override a positive match.
    A negative match will exclude the user from the sync if the match is successful.
    E.G. "priv-*" will exclude all UPNs that have a prefix of priv-. so an email like this will be excluded form the AU sync: "priv-ehuffman@elliot-labs.com".
.EXAMPLE
    PS C:\> Sync-AzureADAUUser.ps1 -AdminUnitID "00000000-0000-0000-0000-000000000000" -UPNBlobMatchString "*@example.com" -UPNNegativeBlobMatch "*priv*"
    Reads all of the users in the AAD and syncs them into the specified Administrative Unit (00000000-0000-0000-0000-000000000000).
    If the user has a UPN that ends in "@example.com" it will be included in the list.
    If the user has "priv" anywhere in its name then it will be excluded.
.INPUTS
    System.String
    System.GUID
.OUTPUTS
    Void
.NOTES
    Requires a Managed Identity with "AdministrativeUnit.ReadWrite.All" and "User.Read.All" rights assigned to it.
#>

#Requires -Module AzureAD
#Requires -Module Az.Accounts

param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [GUID]$AdminUnitID = "00000000-0000-0000-0000-000000000000",
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$UPNBlobMatchString = "*@example.com",
    [ValidateNotNullOrEmpty()]
    [String]$UPNNegativeBlobMatch = "*@examplered.com"
)

# Log into Azure
Connect-AzAccount -Identity | Out-Null

# Get an Access token for Microsoft Graph
$Token = (Get-AzAccessToken -Resource "https://graph.microsoft.com/").Token

# Log into AzureAD cmdlets
Connect-AzureAD -MsAccessToken $Token

# Get all users
[Microsoft.Open.AzureAD.Model.User[]]$UserList = Get-AzureADUser -All $true

# Get all AU users and save their GUIDs
[GUID[]]$AUUserGuidList = (Get-AzureADMSAdministrativeUnitMember -Id $AdminUnitID -All $true | Where-Object -FilterScript {$_.odataType -eq "#microsoft.graph.user"}).ID

# Loop through each user in the list to ensure they are in the correct AU
foreach ($User in $UserList) {
    # Execute the blob matches on the UPN to ensure it is the correct UPN format.
    if (($User.UserPrincipalName -like $UPNBlobMatchString) -and ($User.UserPrincipalName -NotLike $UPNNegativeBlobMatch)) {
        # Only add users that are not in the AU, as if the user is already in it, it will throw an error.
        if ($User.ObjectID -NotIn $AUUserGuidList) {
            # Add the specified user to the AU
            Add-AzureADMSAdministrativeUnitMember -Id $AdminUnitID -RefObjectId $User.ObjectID
        }
    }
}