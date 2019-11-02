<#
.SYNOPSIS
    This script provides the domain of the specified computer.
.DESCRIPTION
    This script looks up a computer's domain based upon the name of the computer.
.PARAMETER ComputerName
    If specified, a search for the specified name will be executed.
    Default: Use the local computer's name for the search.
.EXAMPLE
    PS C:\> Get-ComputerDomain.ps1
    This will gather the local computer's name and will run a search on the domain for the local computer's name.
    If found then it will output the name of the domain that the computer is currently located in.
.EXAMPLE
    PS C:\> Get-ComputerDomain.ps1 -ComputerName "other-computer"
    This will search all domains in the forrest and will return the domain of the specified computer account.
.INPUTS
    System.String
    System.String[]
.OUTPUTS
    System.String
.LINK
    https://github.com/elliot-labs/Powershell-Doodads
.NOTES
    RSAT's Active Directory powershell needs to be installed and enabled for this script to work.
    Domain controller connectivity needs to be present for the Active directory searches to be successful.
#>

#Requires -Module ActiveDirectory

# Set up the parameter input.
Param(
    [System.String]$ComputerName = $env:ComputerName,
    [System.String[]]$SearchDomain = (Get-ADForest).Domains
)

# Create an empty array for multiple potential matches
$ComputerDN = @()

# Iterate through each domain.
foreach ($Domain in $SearchDomain) {
    $ComputerDN += (Get-ADComputer -Identity $ComputerName -Server $Domain -ErrorAction "SilentlyContinue").DistinguishedName
}

# If no computer is found with the above query, exit the script.
if ($ComputerDN.Count -eq 0) {
    # Write and error
    Write-Error -Message "No computer found, check the computer name and try again."

    # Exit the script
    exit 1
}

# Split each section of the distinguished name into separate entities.
$DCList = $ComputerDN -split "," | Where-Object -FilterScript { $_ -like "DC=*" }

# Join them back together and remove the trailing close currly bracket.
$ComputerDomain = ($DCList -join ".") -replace @("DC=", "")

# Make the output available to other scripts.
Return $ComputerDomain