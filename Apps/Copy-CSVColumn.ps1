<#
.SYNOPSIS
    Copies a column to another CSV file.
.DESCRIPTION
    Copies a column from a source CSV file to a destination CSV file.
    The script check the source and destination for compatibility before copying the column to the destination.
    The script will return $true for success and $false for failure.
    If there is a failure, the system will write an error to the console and return $false.
.PARAMETER Source
    The path to the source CSV file. Wild cards are not permitted.
.PARAMETER Destination
    The path to the destination CSV file. Wild cards are not permitted.
.PARAMETER ColumnName
    Name of the column in the source file to copy to the destination file.
.EXAMPLE
    PS C:\> Copy-CSVColumn.ps1 -Source .\Source.csv -Destination .\Destination.csv -ColumnName "Foo Bar"
    Copies the column named "Foo Bar" from the source.csv file and makes a new column in the file named Destination.csv with the same values and column name that were present in the source file.
.INPUTS
    System.String
.OUTPUTS
    Copy-CSVColumn returns $true if execution is successful, and $false if it is unsuccessful.
.LINK
    https://github.com/elliot-labs/PowerShell-Doodads
    Export-CSV
    Import-CSV
.NOTES
    You must ensure that the destination file has an equal amount or more rows than the source file.
    The script also checks if the column name in the source exists. If it doesn't it will write an error and return false.
    If the column already exists in the destination, it will write an error and return false.
    Otherwise the script will halt and return $false.

    Exit Codes:
        1 - The column name does not exist in the specified source file.
        2 - The column name already exists in the specified destination CSV file.
        3 - The source CSV file cannot have more rows than the destination CSV file.
#>

# Accept command line parameters.
[CmdletBinding(SupportsShouldProcess=$true)]
[OutputType([System.String])]
param(
    [Parameter(
        Mandatory = $true,
        Position = 0,
        ParameterSetName = "CLI",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [Alias("PSPath","SourceCSVPath")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_ -PathType "Leaf" -Include "*.csv"})]
    [System.String]$Source,
    [Parameter(
        Mandatory = $true,
        Position = 1,
        ParameterSetName = "CLI",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [Alias("DestinationCSVPath")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_ -PathType "Leaf" -Include "*.csv"})]
    [System.String]$Destination,
    [Parameter(
        Mandatory = $true,
        Position = 2,
        ParameterSetName = "CLI",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [Alias("Property","Name")]
    [ValidateNotNullOrEmpty()]
    [System.String]$ColumnName
)

# Import the CSV files into memory.
$SourceCSV = Import-Csv -Path $SourceCSVPath
$DestinationCSV = Import-Csv -Path $DestinationCSVPath

# If the source doesn't have the specified column or the destination already has it, write an error and return.
if ($SourceCSV.$ColumnName -eq $null) {
    Write-Error -Message "The source column does not exist!"
    return $false
} elseif ($DestinationCSV.$ColumnName -ne $null) {
    Write-Error -Message "The column already exists in the destination!"
    return $false
} 

# Add the column to be populated with data.
$DestinationCSV | Add-Member -MemberType NoteProperty -Name $ColumnName -Value $null

# Export the destination CSV with the new column name.
$DestinationCSV | Export-Csv -Path $DestinationCSVPath

# Re-import the Destination CSV with the new column name for easy manipulation.
$DestinationCSV = Import-Csv -Path $DestinationCSVPath

<#
For the future: Build a system that can make new rows to support a source that is larger than the destination.
Below is header isolation for a potential row generator. Header isolation is successful. Row creation is currently unsuccessful.

# Create a definition of the destination schema.
$DestinationCSVDefinition = (Get-Content -Path $DestinationCSVPath)[0,1]
if ($DestinationCSVDefinition[0] -cMatch "^#TYPE") {
    $DestinationCSVDefinition = $DestinationCSVDefinition[1]
} else {
    $DestinationCSVDefinition = $DestinationCSVDefinition[0]
}
$DestinationCSVDefinition = $DestinationCSVDefinition -split ","

#>

# Check to see if the destination can handle all of the rows of the source CSV and throw and error if it can't.
if ($SourceCSV.Count -gt $DestinationCSV.Count) {
    # Write an error to the console.
    Write-Error -Message "Cannot have a source file that has more rows than the destination file!"
    
    # Stop execution and return that execution was not successful.
    return $false
} else {
    # Loop through the source CSV file.
    for ($i = 0; $i -lt $SourceCSV.Count; $i++) {
        # Check if data exists, and if it doesn't set it to an empty string.
        if ($null -eq $SourceCSV[$i].$ColumnName) {
            $DestinationCSV[$i].$ColumnName = ""
        } else {
            # If there is data, set it to the data that is found.
            $DestinationCSV[$i].$ColumnName = $SourceCSV[$i].$ColumnName
        }
    }
    # Save in memory work to disk.
    $DestinationCSV | Export-Csv -Path $DestinationCSVPath

    # Stop execution and return that efforts were successful.
    return $true
}
