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

[CmdletBinding(SupportsShouldProcess = $true)]
# Allow the script to be run as part of another script or on the CLI
param(
    [String[]]$ToAddress = "ehuffman@elliot-labs.com",
    [String]$Subject = "Subject",
    [String]$Body = "Your message here<br>HTML Capable!"
    # [string[]]$CarbonCopy,
    # [string[]]$BlindCarbonCopy
)

Begin {
    # Capture the common parameter overrides to inherit the values to all cmdlets
    if (-not $PSBoundParameters.ContainsKey('Verbose')) {
        $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
    }
    if (-not $PSBoundParameters.ContainsKey('Confirm')) {
        $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
    }
    if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
        $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
    }

    # Initialize the email counter
    [int]$EmailsSent = 0
    Write-Verbose -Message "Instantiating outlook object"

    # Initialize outlook
    $Outlook = New-Object -ComObject Outlook.Application

    # Check to see if the object has been created properly
    if ($Outlook -IsNot [Microsoft.Office.Interop.Outlook.ApplicationClass]) {
        Write-Error "Outlook has not been initialized properly. Check to make sure it is installed."
        Exit 1
    }
}

Process {
    Write-Verbose -Message "Incrementing email sent counter"
    $EmailsSent++

    # Check for WhatIf common parameter
    if ($PSCmdlet.ShouldProcess("Memory", "Create eMail")) {
        Write-Verbose -Message "Composing message to $ToAddress"

        # Create the email
        $Mail = $Outlook.CreateItem(0)
        $Mail.To = $ToAddress -join ";"
        $Mail.Subject = $Subject
        $Mail.HTMLBody = $Body

        Write-Verbose -Message "Placing email in outbox"
    }

    # Check for WhatIf common parameter
    if ($PSCmdlet.ShouldProcess("Outbox", "Write eMail")) {
        # Put the email in the outbox
        $Mail.Send()
    }
}

End {
    if ($PSCmdlet.ShouldProcess("Outlook", "Send and Receive")) {
        Write-Verbose -Message "Forcing a send and receive to process emails in outbox"

        # Force a send and receive
        $Outlook.GetNameSpace("MAPI").SendAndReceive(1)   
    }
    
    Write-Verbose -Message "Releasing outlook instance from memory"

    # Clean up the objects that were created
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Outlook) | Out-Null
    $Outlook = $null

    if ($PSCmdlet.ShouldProcess("$EmailsSent eMails", "Simulated send")) {
        Write-Verbose -Message "Sent $EmailsSent emails"
    }
}