<#
.SYNOPSIS
This script provides the domain of the specified computer.
.DESCRIPTION
This script looks up a computer's domain based upon the name of the computer.
.PARAMETER UserName
If specified, a search for the specified name will be executed. Default: Use the local computer's name for the search.
.EXAMPLE
Get-UserDomain
This will gather the local user's NT Alias and will run a search on the domain for the users's domain.
If found then it will output the name of the domain that the user is currently located in.
.EXAMPLE
Get-UserDomain -UserName "other-computer"
This will search all domains in the forrest and will return the domain of the specified computer account.
.NOTES
RSAT's Active directory powershell needs to be installed and enabled for this script to work.
Domain controller connectivity needs to be present for the Active directory searches to be successful.
.LINK
https://github.com/elliot-labs/Powershell-Doodads
#>

# Set up the parameter input.
Param([string]$UserName=$env:UserName)

# Get a list of all domains.
$Domains = (Get-ADForest).Domains

# Iterate through each domain.
foreach ($Domain in $Domains) {
    # Use a try catch block to silence errors.
    try {
        # Record the results of the computer lookup for the curent domain.
        $ComputerData = Get-ADUser -Identity $ComputerName -Server $Domain | Select-Object DistinguishedName
    } catch {} # Do nothing
}

# Split each section of the distinguishd name into seperate entitities.
$ComputerDomain = $ComputerData -split "," | Where-Object {$_ -like "DC=*"}
# Join them back together and remove the trailing close currly bracket.
$ComputerDomain = ($ComputerDomain -join "." -replace ("DC=", "")).TrimEnd("}")
# Make the output available to other scripts.
Write-Output $ComputerDomain
