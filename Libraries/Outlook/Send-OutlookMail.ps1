<#
.SYNOPSIS
This script sends emails using outlook.
.DESCRIPTION
This script sends emails using outlook and the logged in user's email account. The operator of this script can specify who receives the email,
what the subject is and what the body of the email contains.
.PARAMETER To
When set to true the GUI will not be displayed and the other CLI arguments will be used for the required information.
.PARAMETER Subject
The path to the file that will be used as the source for the outputted batch script.
.PARAMETER Body
The destination and file name that will be used when the source file has finished processing. This field accepts HTML tags for formatting.
.EXAMPLE
Send-Email.ps1 -To "v-elhuff@microsoft.com" -Subject "Outbound Call Report" -Body "Outbound call report:<br><br>Start time: 12:34<br>Stop time: 16:56"
This will send an email to v-elhuff@microsoft.com with a subject line of "Outbound call report" and a content of:
Outbound Call report:

Start Time: 12:34
Stop Time: 15:45
.EXAMPLE
Send-Email.ps1 -To "user@example.com"
this will send a message to user@example.com with the subject of Subject goes here and the content of Your message here.
.NOTES
This tool is not needed for general use and should only be used when you need to add email functionality to a powershell script.
.LINK
https://microsoft-my.sharepoint.com/:f:/r/personal/v-elhuff_microsoft_com/_layouts/15/guestaccess.aspx?share=Evxz8UfsAppDmnOYjI-7YXoBLd9ngWVAObpBOfOBF98jFQ
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
        Write-Host "Sent!"

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