<#
.SYNOPSIS
    Remove duplicate files based on text input from CCleaner.
.DESCRIPTION
    Deletes all but the original copy of the duplicates returned by CCleaner's duplicate detector.
    Original copies are designated as the first file in each duplicate section. Subsequent files are considered non-original.
    -Verbose and -WhatIf support is baked into the script for simulation and debugging.
.EXAMPLE
    PS C:\> Remove-DuplicateFile.ps1
    Uses the CCleaner Export.txt file in the same directory and deletes all but the originals in the exported file.
.EXAMPLE
    PS C:\> Remove-DuplicateFile.ps1 -Path C:\Duplicates.txt
    Uses the duplicates.txt file in the root drive directory and deletes all but the originals as specified in the exported file.
.EXAMPLE
    PS C:\> Remove-DuplicateFile.ps1 -Path C:\Duplicates.txt -All
    Uses the duplicates.txt file in the root drive directory and deletes all the CCleaner designated files.
.EXAMPLE
    PS C:\> Remove-DuplicateFile.ps1 -All
    Uses the CCleaner Export.txt file in the same directory and deletes all the CCleaner designated files.
.PARAMETER Path
    Path to the txt file that CCleaner generates from its duplicate detector tool.
    Relative paths and full paths are supported.
    Example:
    C:\Users\Public\Documents\Duplicates.txt

    Another Example:
    .\Duplicates.txt
.PARAMETER All
    When this switch parameter is specified, all files are deleted.
    The originals are also purged.
.INPUTS
    System.String
.OUTPUTS
    Void
.LINK
    https://github.com/elliot-labs/PowerShell-Doodads
.NOTES
    The expected text is from CCleaner's duplicate detector.
#>

# cmdlet bind the script for simulation support
[CmdletBinding(SupportsShouldProcess=$true)]

param(
    [ValidateScript({Test-Path -Path $_ -PathType "Leaf"})]
    [System.String]$Path=".\CCleaner Export.txt",
    [Switch]$All
)

# Ingest the RAW CCleaner data
[System.String[]]$RawDuplicateList = Get-Content -Path $Path

# Initialize the current item list
[System.String[]]$CurrentItemList = @()

# Loop through each line of the list
foreach ($Line in $RawDuplicateList) {

    # Write extra info for troubleshooting
    Write-Verbose -Message "Current Line:"
    Write-Verbose -Message $Line

    # Check to see if the line is a list separator
    if ($Line -eq '------------------------------------------------------------------------------------------------------------------------------------------------------') {
        # Tell the delete loop to skip the current item
        [System.Boolean]$SkipItem = $true

        # Loop through each file that needs to be deleted
        foreach ($ToDelete in $CurrentItemList) {

            # Check if the current item should be skipped
            if ((-not $All) -and $SkipItem) {
                # Indicate that the current item should be skipped 
                $SkipItem = $false

                # Write extra info for troubleshooting
                Write-Verbose -Message "Skipping the current item"

                # Skip the first line and move on to the next
                continue
            }

            # Write extra info for troubleshooting
            Write-Verbose -Message "Deleting:"
            Write-Verbose -Message $ToDelete

            # Simulate the delete command or execute it if no deletion is necessary
            if ($PSCmdlet.ShouldProcess("File: $ToDelete", "Delete")) {
                # Delete the specified file
                Remove-Item -Path $ToDelete
            }
        }

        # Reset the current item list
        $CurrentItemList = @()

        # Move to next line
        continue
    } else {
        # Write extra info for troubleshooting
        Write-Verbose -Message "File container:"
        Write-Verbose -Message ($Line -split "`t")[1]

        Write-Verbose -Message "File Leaf:"
        Write-Verbose -Message ($Line -split "`t")[0]

        Write-Verbose -Message "Computed Line:"
        Write-Verbose -Message "$(($Line -split "`t")[1])\$(($Line -split "`t")[0])"

        # Add the current item to the list after parsing
        $CurrentItemList += "$(($Line -split "`t")[1])\$(($Line -split "`t")[0])"
    }
}
