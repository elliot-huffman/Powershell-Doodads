<#
.SYNOPSIS
    Copies a column to another CSV file.
.DESCRIPTION
    Copies a column from a source CSV file to a destination CSV file.
    The script checks the source and the destination for compatibility before copying the column to the destination.
    The script will return $true for success and $false for failure.
    If there is a failure, the system will write an error to the console, set an exit code and return $false.
.PARAMETER Source
    The path to the source CSV file. Wild cards are not permitted.
.PARAMETER Destination
    The path to the destination CSV file. Wild cards are not permitted.
.PARAMETER ColumnName
    Name of the column in the source file to copy to the destination file.
    This parameter is case sensitive.
.EXAMPLE
    PS C:\> Copy-CSVColumn.ps1 -Source .\Source.csv -Destination .\Destination.csv -ColumnName "Foo Bar"
    Copies the column named "Foo Bar" from the source.csv file and makes a new column in the file named Destination.csv with the same values and column name that were present in the source file.
.INPUTS
    System.String
.OUTPUTS
    System.Boolean
.LINK
    https://github.com/elliot-labs/PowerShell-Doodads
    Export-CSV
    Import-CSV
    ConvertFrom-Csv
    ConvertTo-Csv
.NOTES
    The script checks if the column name in the source exists.
    If it doesn't it will write an error and return false.
    If the column already exists in the destination, it will write an error and return false.
    Otherwise the script will halt and return $false.

    Exit Codes:
        1 - The column name does not exist in the specified source file.
        2 - The column name already exists in the specified destination CSV file.
#>

# Accept command line parameters.
[CmdletBinding(SupportsShouldProcess = $true)]
[OutputType([System.String])]
param (
    [Parameter(
        Mandatory = $true,
        Position = 0,
        ParameterSetName = "CLI",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [Alias("PSPath", "SourceCSVPath")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Test-Path -Path $_ -PathType "Leaf" -Include "*.csv" })]
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
    [ValidateScript( { Test-Path -Path $_ -PathType "Leaf" -Include "*.csv" })]
    [System.String]$Destination,
    [Parameter(
        Mandatory = $true,
        Position = 2,
        ParameterSetName = "CLI",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [Alias("Property", "Name")]
    [ValidateNotNullOrEmpty()]
    [System.String]$ColumnName
)

# If debug is enabled. Do not ask for user input.
if ($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }

# Write debugging info
Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Parameter info:"
Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$Source: $Source"
Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$Destination: $Destination"
Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$ColumnName: $ColumnName"

# Import the CSV files into memory.
$SourceCSV = Import-Csv -Path $Source
$DestinationCSV = Import-Csv -Path $Destination

# Write debugging info
Write-Debug -Message "============================ Source CSV First Two Rows ============================"
# Write the first two rows to the debug output if debug mode is specified
$SourceCSV | Select-Object -First 2 | ForEach-Object -Process {Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - $_"}
Write-Debug -Message "============================ Destination CSV First Two Rows ======================="
$DestinationCSV | Select-Object -First 2 | ForEach-Object -Process { Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - $_"}

# If the source doesn't have the specified column or the destination already has it, write an error, return and exit.
if ($null -eq $SourceCSV[0].$ColumnName) {

    # Write debugging info
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Failure occurred, variable data at if statement:"
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$SourceCSV[0].`$ColumnName: $($SourceCSV[0].$ColumnName)"
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - The above debug statement won't have a value if the source does not exist"

    # Write an error message to stderr (this is non-terminating)
    Write-Error -Message "The source column does not exist!"

    # Return $False for a failed copy
    $PSCmdlet.WriteObject($false)

    # Exit Script execution unsuccessfully
    exit 1
} elseif ($null -ne $DestinationCSV[0].$ColumnName) {

    # Write debugging info
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Failure occurred, variable data at if statement:"
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$DestinationCSV[0].`$ColumnName: $($DestinationCSV[0].$ColumnName)"
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Column data type: $($DestinationCSV[0].$ColumnName.GetType().FullName)"

    # Write an error message to stderr (this is non-terminating)
    Write-Error -Message "The column already exists in the destination!"

    # Return $False for a failed copy
    $PSCmdlet.WriteObject($false)

    # Exit Script execution unsuccessfully
    exit 2
}

# If there are more rows in the source file than the destination file, prep the headers list
if ($SourceCSV.Count -gt $DestinationCSV.Count) {
    # Get a list of columns in the Destination file
    $Headers = $DestinationCSV[0].PSObject.Properties.Name

    # Write verbose information
    Write-Verbose -Message "Creating new rows for destination CSV file"

    # Write debugging info
    Write-Debug -Message "============================ Header list =========================================="
    $Headers | ForEach-Object -Process { Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - $_"}
}

# Write debugging info
Write-Debug -Message "============================ Column Copy started =================================="

# Loop through the source CSV file
for ($i = 0; $i -lt $SourceCSV.Count; $i++) {
    # If the destination CSV file doesn't have any more rows, create new rows
    if ($null -ne $DestinationCSV[$i]) {
        # Write debug info
        Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Adding data to existing row [$i]: $($SourceCSV[$i].$ColumnName) "

        # Add the column and date to the destination CSV file
        $DestinationCSV[$i] | Add-Member -MemberType "NoteProperty" -Name $ColumnName -Value $SourceCSV[$i].$ColumnName
    } else {
        # Write debug info
        Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Creating new row [$i]"

        # The reason that the HashTable is not created fresh in each loop is that only the one column of data is updated.
        # It is updated *every* time to the value of the source file, so if it is blank, it will be blank, it will not be the previous value.

        # This creates a blank HashTable.
        $HeaderHashTable = @{ }

        # Loop through the list of headers and make a table of them
        foreach ($Header in $Headers) {
            # Set each column of data to blank for the additional rows
            $HeaderHashTable[$Header] = ""
        }

        # Add the new column to the Header HashTable
        $HeaderHashTable[$ColumnName] = ""

        # Convert the HashTable to a PSCustomObject
        $NewRow = [PSCustomObject]$HeaderHashTable

        # Write debug info
        Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Injecting data into new row [$i]: $($SourceCSV[$i].$ColumnName)"

        # Replace the row data with the appropriate new row data so that old data is not reused
        $NewRow.$ColumnName = $SourceCSV[$i].$ColumnName

        # Add the new row to the DestinationCSV file
        $DestinationCSV += $NewRow
    }
}

# Check if WhatIf/Confirm is specified, implement risk mitigation
if ($PSCmdlet.ShouldProcess("Disk", "Write CSV")) {

    # Write Debug info
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Writing CSV to disk"

    # Save in memory work to disk
    $DestinationCSV | Export-Csv -Path $Destination

    # Write debug info
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - CSV write completed"
}

# Stop execution and return that efforts were successful.
return $true