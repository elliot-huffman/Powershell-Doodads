<#
.SYNOPSIS
    Gets a free Walmart gift card
.DESCRIPTION
    Opens the web browser to a web page to retrieve a walmart gift card.
    If a web browser is not installed or set to open urls by default, errors are caught and handled.
.EXAMPLE
    PS C:\> Get-WalmartGiftCard.ps1
    Retrieves a walmart gift card by using the web browser.
.OUTPUTS
    System.Boolean
.LINK
    https://github.com/elliot-labs/PowerShell-Doodads
.NOTES
    Requires a web browser
    Exit Codes:
    1 - Unable to open URL, this is usually because a web browser is not installed on the machine.
#>

# Cmdlet bind the script
[CmdletBinding()]
param()

process {
    # Write Debugging information
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Launching Web Browser to: https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    
    # Write Verbose information
    Write-Verbose -Message "Launching Web Browser"

    # Check to see if the web browser can be launched
    try {
        # Gets a free wallMart gift card!
        Start-Process -FilePath "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

    # Catch and handel the error
    } catch {
        # Write error
        Write-Error -Message "Unable to open web-browser"

        # Return Value
        $PSCmdlet.WriteObject($false)

        # Exit with error
        exit 1
    }
}

end {
    # Return Value
    $PSCmdlet.WriteObject($true)

    # Exit
    exit 0
}