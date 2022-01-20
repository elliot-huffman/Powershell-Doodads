<#
.SYNOPSIS
    This script provides the domain of the specified computer.
.DESCRIPTION
    This script looks up a computer's domain based upon the name of the computer.
.PARAMETER ComputerName
    If specified, a search for the specified name will be executed.
    Default:
    Use the local computer's name for the search.
.PARAMETER SearchDomain
    The search domain parameter is a way to manually specify which domains are to be searched for the specified computer name.
    Default:
    The domains that are in the current forrest.
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

    Exit Code:
    1 - No computer found, check the computer name and try again.
#>

#Requires -Module ActiveDirectory

# Cmdlet bind the script for advanced functionality
[CmdletBinding()]

# Set up the parameter input
Param(
    [Parameter(
        Mandatory=$false,
        Position=0,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true
    )]
    [ValidateNotNullOrEmpty()]
    [System.String]$ComputerName = $env:ComputerName,
    [Parameter(
        Mandatory=$false,
        Position=1,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true
    )]
    [ValidateNotNullOrEmpty()]
    [System.String[]]$SearchDomain = (Get-ADForest).Domains
)

# Allow the script to be run in a pipeline
process {
    # Write debugging info
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Parameter info:"
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$ComputerName: $ComputerName"
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$SearchDomain: $SearchDomain"

    # Create an empty array for multiple potential matches
    $ComputerDN = @()

    # Iterate through each domain
    foreach ($Domain in $SearchDomain) {
        # Write verbose info
        Write-Verbose -Message "Running domain controller query for computer: $ComputerName"
        
        # Write debug info
        Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Executing query against $Domain for $ComputerName"

        # Query the specified domain for the specified computer and extract the distinguished name
        $ComputerDN += (Get-ADComputer -Identity $ComputerName -Server $Domain -ErrorAction "SilentlyContinue").DistinguishedName
    }

    # Write debug info
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - List of DNs for $ComputerName`:"
    $ComputerDN | ForEach-Object -Process {Write-Debug -Message "$_"}

    # If no computer is found with the above query, exit the script
    if ($ComputerDN.Count -eq 0) {
        # Write and error
        Write-Error -Message "No computer found, check the computer name and try again."

        # Exit the script
        exit 1
    }

    # Write Verbose info
    Write-Verbose -Message "Converting found DNs to FQDNs and returning"

    # Loop through each set of Distinguished names
    foreach ($DN in $ComputerDN) {
        # Split each section of the distinguished name into separate entities
        $SplitDN = $DN -Split "," | Where-Object -FilterScript { $_ -like "DC=*" }

        # Write debug info
        Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - List of split DNs for $DN`:"
        $SplitDN | ForEach-Object -Process {Write-Debug -Message "$_"}

        # Join them back together and remove the trailing close currly bracket
        $FQDN = ($SplitDN -join ".") -Replace @("DC=", "")

        # Write debug info
        Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - FQDN: $FQDN"

        # Make the output available to other scripts
        $PSCmdlet.WriteObject($FQDN)
    }
}