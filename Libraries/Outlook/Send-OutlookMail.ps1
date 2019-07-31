<#
.SYNOPSIS
    Sends and email using outlook
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> Send-OutlookMail.ps1
    Sends an email message to ehuffman@elliot-labs.com with the subject of "subject", and a body of "Your message here<br>HTML Capable!"
.PARAMETER ToAddress
    pass
.PARAMETER Subject
    pass
.PARAMETER Body
    pass
.INPUTS
    System.String
.OUTPUTS
    Void
.LINK
    https://github.com/elliot-labs/Powershell-Doodads
.NOTES
    Outlook is required to be installed for this script to work.
    Exit codes:
    1 - Outlook has not been initialized properly, check to ensure it has been installed.
#>

# Allow the script to be run as part of another script or on the CLI
param(
    [String]$To = "Elliot.Huffman@microsoft.com",
    [String]$Subject = "Subject goes here",
    [String]$Body = "Your message here")

# Create a function that sends emails
Function Send-Email {
    param (
        [String]$To,
        [String]$Subject,
        [String]$Body
    )

    # Initialize outlook
    $Outlook = New-Object -ComObject Outlook.Application

    # Check if the outlook object could be initialized in the first place.
    if ($Outlook -ne $null) {
        # Create the email
        $Mail = $Outlook.CreateItem(0)
        $Mail.To = $To
        $Mail.Subject = $Subject
        $Mail.HTMLBody = $Body
        
        # Put the email in the outbox
        $Mail.Send()

        # Force a send and receive
        $Outlook.GetNameSpace("MAPI").SendAndReceive(1)
        Write-Verbose "Sent!"

        # Clean up the objects that were created
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Outlook) | Out-Null
        $Outlook = $null
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Outlook is required to be installed for this application to work properly!", "Dependency Required!", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
}

# Execute mail function if used as a standalone script.
Send-Email -To $To -Subject $Subject -Body $Body