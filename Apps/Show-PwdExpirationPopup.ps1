<#
.SYNOPSIS
    Displays a pop up message if the user's password is about to expire
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    System.Int32
    System.String
    System.DateTime
.OUTPUTS
    Output (if any)
.LINK
    https://github.com/elliot-labs/PowerShell-Doodads
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
    [System.Int32]$PopupDaysBeforeCount = 14,
    # Text to display in the form body
    [Parameter(
        Mandatory = $false,
        Position = 1,
        HelpMessage = "Text to display in the form body"
    )]
    [ValidateNotNullOrEmpty()]
    [String]$MessageBody = "Your password is about to expire.`nPlease consider changing it.",
    # Title Bar text to display
    [Parameter(
        Mandatory = $false,
        Position = 2,
        HelpMessage = "Title Bar text to display"
    )]
    [ValidateNotNullOrEmpty()]
    [String]$TitleBarText = "Title Bar Text",
    # Select the icon to be displayed by the message box
    [Parameter(
        Mandatory = $false,
        Position = 3,
        HelpMessage = "Select the icon to be displayed by the message box"
    )]
    [ValidateSet("Information", "Question", "Warning", "Error")]
    [String]$MessageBoxIcon = "Information",
    # Manual input of the expiration date
    [Parameter(
        Mandatory = $false,
        Position = 4,
        HelpMessage = "Specify the expiration date of the password"
    )]
    [ValidateNotNullOrEmpty()]
    [System.DateTime]$PasswordExpirationDate = (&"..\Libraries\AD DS\LDAP\Get-PasswordExpiration.ps1" -CLIMode)
)

# Define the popup function
Function Show-Popup {
    <#
    .SYNOPSIS
        Displays a popup with the specified text and icon
    .DESCRIPTION
        Takes data created with the user's specified data and displays it on a popup.
        The icon is configurable, the title text is configurable, and the message body is configurable.
        The return of this function is void.
    .EXAMPLE
        PS C:\> Show-Popup
        Will display a Windows Form MessageBox to the user with the specified text and icon.
    .INPUTS
        None
    .OUTPUTS
        None
    .NOTES
        $MessageBody, $TitleBarText and $IconObject have to be defined previous to executing this function.
    #>

    # Import the Windows forms assembly
    Add-Type -AssemblyName System.Windows.Forms

    # Display the message box with the specified text and icon
    [System.Windows.Forms.MessageBox]::Show($MessageBody, $TitleBarText, [System.Windows.Forms.MessageBoxButtons]::OK, $IconObject) | Out-Null
}

# If the password does not expire, exit the script
if ($PasswordExpirationDate -eq (0 | Get-Date)) {
    exit
}

# Check if the password has passed the specified expiration prompting period
if ((Get-Date) -gt $PasswordExpirationDate.AddDays(-$PopupDaysBeforeCount)) {
    # Check if the password expired
    if ((Get-Date) -gt $PasswordExpirationDate) {
        # Run this code if the password expired
        # Execute the popup function
        Show-Popup
    } else {
        # Otherwise run this code if the password is within the specified notification period
        # Execute the popup function
        Show-Popup
    }
}
