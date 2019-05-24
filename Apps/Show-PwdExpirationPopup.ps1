<#
.SYNOPSIS
    Displays a pop up message if the user's password is about to expire
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    System.DateTime
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>

# Add command line parameter/argument support.
# Each parameter is detailed in the above help documentation.
[OutputType($null)]
param(
    # Days before expiration to display the popup
    [Parameter(
        Mandatory = $false,
        Position = 0,
        HelpMessage = "Days before expiration to display the popup"
    )]
    [ValidateNotNullOrEmpty()]
    [int]$PopupDaysBeforeCount = 14,
    # Text to display in the form body
    [Parameter(
        Mandatory = $false,
        Position = 1,
        HelpMessage = "Text to display in the form body"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$MessageBody = "Your password is about to expire.`nPlease consider changing it.",
    # Title Bar text to display
    [Parameter(
        Mandatory = $false,
        Position = 2,
        HelpMessage = "Title Bar text to display"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$TitleBarText = "Title Bar Text",
    # Select the icon to be displayed by the message box
    [Parameter(
        Mandatory = $false,
        Position = 3,
        HelpMessage = "Select the icon to be displayed by the message box"
    )]
    [ValidateSet("Information","Question","Warning","Error")]
    [string]$MessageBoxIcon = "Information"
)

# Import the Windows forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Retrieve the expiration date of the current user
$ExpirationDate = &"..\Libraries\AD DS\LDAP\Get-PasswordExpiration.ps1" -CLIMode

# Set the message box icon variable to the appropriate value based upon the input
switch ($MessageBoxIcon) {
    "Information" { $IconObject = [System.Windows.Forms.MessageBoxIcon]::Information }
    "Question" { $IconObject = [System.Windows.Forms.MessageBoxIcon]::Question }
    "Warning" { $IconObject = [System.Windows.Forms.MessageBoxIcon]::Warning }
    "Error" { $IconObject = [System.Windows.Forms.MessageBoxIcon]::Error }
    Default { $IconObject = [System.Windows.Forms.MessageBoxIcon]::Information }
}

if ((Get-Date) -gt $ExpirationDate.AddDays(-$PopupDaysBeforeCount)) {
    # Check if the password expired
    if ((Get-Date) -gt $ExpirationDate) {
        # Run this code if the password expired
        # Display a popup with a pre-configured title bar text, message body and icon
        [System.Windows.Forms.MessageBox]::Show($MessageBody, $TitleBarText, [System.Windows.Forms.MessageBoxButtons]::OK, $IconObject) | Out-Null
    } else {
        # Otherwise run this code if the password is within the specified notification period
        # Display a popup with a pre-configured title bar text, message body and icon
        [System.Windows.Forms.MessageBox]::Show($MessageBody, $TitleBarText, [System.Windows.Forms.MessageBoxButtons]::OK, $IconObject) | Out-Null
    }
}

# Temporary for testing
[System.Windows.Forms.MessageBox]::Show($MessageBody, $TitleBarText, [System.Windows.Forms.MessageBoxButtons]::OK, $IconObject) | Out-Null
