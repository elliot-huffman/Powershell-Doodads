<#
.SYNOPSIS
    Compares AutoPilot CSV files to see which serial numbers differ.
.DESCRIPTION
    Aggregates multiple CSV files into a single list then runs a comparison against the list to find serial numbers that do not match the old and new hash lists.
.PARAMETER OldHash
    This parameter excepts an array of paths that point to one or more CSV files containing a list of original CSV files with autopilot formatted CSV data.
.PARAMETER NewHash
    This parameter excepts an array of paths that point to one or more CSV files that need to be compared to a list of existing Intune (endpoint Manager) Autopilot CSV files.
.PARAMETER ExportPath
    This is the folder where the comparison operation results will be saved.
    The results will be saved as "Comparison Results.txt" in the specified directory.
    The default value is the current working directory.
.EXAMPLE
    PS C:\> Compare-AutoPilotSerial.ps1 -OldHash ".\IBA Hash 1.4 A.csv" -NewHash ".\NewHash.csv" -ExportPath ".\"
    This specifies the Reference Object as the "IBA hash 1.4 A.csv" and the Difference Object as the "NewHash.csv" file. the results are going to be saved in the current working directory.

    Results returned to the command line and written to the output file:
    Device Serial Number SideIndicator
    -------------------- -------------
    006005201237         =>
    006006101237         =>
    6005201237           <=
    6006101237           <=
.INPUTS
    System.String[]
    System.String
.OUTPUTS
    System.Management.Automation.PSCustomObject
#>

param(
    [ValidateScript({
        Test-Path -Path $_ -PathType "Leaf"
    })]
    [ValidateNotNullOrEmpty()]
    [System.String[]]$OldHash,
    [ValidateScript({
        Test-Path -Path $_ -PathType "Leaf"
    })]
    [ValidateNotNullOrEmpty()]
    [System.String[]]$NewHash,
    [ValidateScript({
        Test-Path -Path $_ -PathType "Container"
    })]
    [ValidateNotNullOrEmpty()]
    [System.String]$ExportPath = ".\"
)

# Initialize variables
$HashListOld = @()
$HashListNew = @()

# Merge all hash lists together as a single list to process for all old and new hashes
foreach ($CSVPath in $OldHash) {$HashListOld += Import-Csv -Path $CSVPath}
foreach ($CSVPath in $NewHash) {$HashListNew += Import-Csv -Path $CSVPath}

# Compare the two objects
$Results = Compare-Object -ReferenceObject $HashListOld -DifferenceObject $HashListNew -Property "Device Serial Number"

# Write the output to a file for later consumption of the resulting data.
$Results | Out-File -FilePath "$ExportPath\Comparison Results.txt"

# Return the data to the calling party incase this script was run in a series of scripts
return $Results
