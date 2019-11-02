<#
.SYNOPSIS
    This script provides the domain of the specified computer.
.DESCRIPTION
    This script looks up a computer's domain based upon the name of the computer.
.PARAMETER ComputerName
    If specified, a search for the specified name will be executed. Default: Use the local computer's name for the search.
.EXAMPLE
    Get-ComputerDomain
    This will gather the local computer's name and will run a search on the domain for the local computer's name.
    If found then it will output the name of the domain that the computer is currently located in.
.EXAMPLE
    Get-ComputerDomain -ComputerName "other-computer"
    This will search all domains in the forrest and will return the domain of the specified computer account.
.NOTES
    RSAT's Active directory powershell needs to be installed and enabled for this script to work.
    Domain controller connectivity needs to be present for the Active directory searches to be successful.
.LINK
    https://github.com/elliot-labs/Powershell-Doodads
#>

# Set up the parameter input.
Param(
    [System.String]$ComputerName = $env:ComputerName,
    [System.String[]]$SearchDomain = (Get-ADForest).Domains
)

# Iterate through each domain.
foreach ($Domain in $SearchDomain) {
    # Use a try catch block to silence errors.
    try {
        # Record the results of the computer lookup for the current domain.
        $ComputerDN = (Get-ADComputer -Identity $ComputerName -Server $Domain).DistinguishedName 
    } catch { } # Do nothing
}

# Split each section of the distinguished name into separate entities.
$DCList = $ComputerDN -split "," | Where-Object -FilterScript { $_ -like "DC=*" }

# Join them back together and remove the trailing close currly bracket.
$ComputerDomain = ($DCList -join ".") -replace @("dc=", "")

# Make the output available to other scripts.
Return $ComputerDomain