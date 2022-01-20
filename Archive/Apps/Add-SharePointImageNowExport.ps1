<#
.SYNOPSIS
    Bulk uploads files from an image now export CSV file to the specified SharePoint document library
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    System.String
    System.URI
.OUTPUTS
    Void
.NOTES
    Requires the PnP.PowerShell module to be installed before execution.
#>

#Requires -Module PnP.PowerShell

# Set up the parameters
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.Uri]$SiteURL,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.String]$DocumentLibrary,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Test-Path -Path $_ -PathType "Leaf" })]
    [System.String]$CSVPath
)

# Log into the specified SharePoint site using MFA
Connect-PnPOnline -Url $SiteURL -Interactive

# Import the specified CSV file
$CSVList = Import-Csv -Path $CSVPath

# Loop through the imported CSV and add
foreach ($File in $CSVList) {

    # Initialize the metadata hash table
    $MetaData = @{}

    # Loop through the imported metadata properties and convert it to a hash table describing the file.
    foreach ($Property in $File.PSObject.Properties) {
        # Build the hash table key and value for the current csv column
        $MetaData[$Property.Name] = $Property.Value
    }
    

    # Upload the file to the specified document library with the CSV provided metadata
    Add-PnPFile -Path $File.LocalPathColumnNameHere -Folder $DocumentLibrary -Values $MetaData
}