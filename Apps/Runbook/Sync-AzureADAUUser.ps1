<#
.SYNOPSIS
    Add the specified users based upon UPN matching to the specified AU.
.DESCRIPTION
    This script is meant to be run from an Automation Account with a managed identity assigned to it.
    The managed identity needs to have "AdministrativeUnit.ReadWrite.All" and "User.Read.All" assigned to it.
.PARAMETER AdminUnitID
    This parameter is the GUID/ObjectID of the Administrative Unit that needs to have the users synced to.
    Example Value: 8f14a65f-3032-42c8-a196-1cf66d11b930
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
.PARAMETER ExcludedUserGUID
    This parameter is used to explicitly exclude users.
    A match of the user's GUID with the value provided will exclude the user from sync.
    Use commas to separate GUIDs to exclude more than one object. Do not put a space after the comma.
    Example value: "8f14a65f-3032-42c8-a196-1cf66d11b930"
    Example values: 8f14a65f-3032-42c8-a196-1cf66d11b930,00000000-0000-0000-0000-000000000000"
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

#Requires -Module Az.Accounts

param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [GUID]$AdminUnitID,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$UPNBlobMatchString = "*@example.com",
    [ValidateNotNullOrEmpty()]
    [String]$UPNNegativeBlobMatch,
    [ValidateNotNullOrEmpty()]
    [String]$ExcludedUserGUID
)

# Remove whitespace from the excluded GUIDs parameter
$ExcludedUserGUID = $ExcludedUserGUID -replace "\S+", ""

# Set the initial URL ofr AU queries
$GraphAPIAdminUnitURL = "https://graph.microsoft.com/v1.0/directory/administrativeUnits/$AdminUnitID/members/microsoft.graph.user/"

# Set the initial URL for user queries
$GraphAPIUserURL = "https://graph.microsoft.com/v1.0/users"

# Initialize the User List array so that users can be added to it as well as the AU User GUID list
[System.Object[]]$UserList = @()
[GUID[]]$AUUserGuidList = @()


# Log into Azure
Connect-AzAccount -Identity | Out-Null

# Get an Access token for Microsoft Graph
$Token = (Get-AzAccessToken -Resource "https://graph.microsoft.com/").Token

# Build the auth header
$Header = @{Authorization = "Bearer $Token"}

# Get all users
# If a next link property is returned, use the next link from the previous request as the url for the current request and all the users to the user list.
do {
    # Web request against the users endpoint
    $Result = Invoke-RestMethod -Method "Get" -Uri $GraphAPIUserURL -Headers $Header
    
    # Set the Graph API Query url to the next link value that was passed from the Graph API if there are more pages to iterate over.
    # This value may be blank, this means there are no more pages of data to iterate over.
    $GraphAPIUserURL = $Result."@odata.nextLink"

    # Extract the users from the list
    $UserList += $Result.Value

# Continue looping as long as there are more pages
} while ($Result."@odata.nextLink")


# Get the list of the users in the specified administrative unit
do {
    # Run the query
    $Result = Invoke-RestMethod -Method "Get" -Uri $GraphAPIAdminUnitURL -Headers $Header
    
    # Set the Graph API Query url to the next link value that was passed from the Graph API if there are more pages to iterate over.
    # This value may be blank, this means there are no more pages of data to iterate over.
    $GraphAPIAdminUnitURL = $Result."@odata.nextLink"

    # Extract the GUIDs from the result of the web request
    [GUID[]]$AUUserGuidList += $Result.Value.ID

# Continue looping as long as there are more pages
} while ($Result."@odata.nextLink")

# Loop through each user in the list to ensure they are in the correct AU
foreach ($User in $UserList) {
    # Execute the blob matches on the UPN to ensure it is the correct UPN format.
    if (($User.UserPrincipalName -like $UPNBlobMatchString) -and ($User.UserPrincipalName -NotLike $UPNNegativeBlobMatch)) {
        # Only add users that are not in the AU, as if the user is already in it, it will throw an error.
        if (($User.Id -NotIn $AUUserGuidList) -and ($User.ID -NotIn ($ExcludedUserGUID -split ","))) {
            # Expose the current user's object ID
            $CurrentID = $User.Id

            # Build the body of the web request
            $Body = @"
{
    "@odata.id":"https://graph.microsoft.com/v1.0/users/$CurrentID"
}
"@

            # Add the user to the AU
            Invoke-RestMethod -Method "Post" -Uri "https://graph.microsoft.com/v1.0/directory/administrativeUnits/$AdminUnitID/members/`$ref" -Headers $Header -Body $Body -ContentType "application/json"
        }
    }
}
