<#
.SYNOPSIS
    Sends an email dynamically using Outlook as the client.
.DESCRIPTION
    This script sends emails using the installed outlook application on the current system.
    This allows the script to send email that are compliant with company systems.
    By default it will use the current user's outlook context.
    E.G. email address and credentials.
    E.G.2. SMTP, iMAP and POP(3) are disabled for security reasons (the above can be used for MFA bypass), this will hook into Outlook which may be configured for Exchange ActiveSync and send that way.
    This script allows for usage in a pipeline and accepts multiple recipient addresses, as well as customizing the subject and (HTML compatible) body.
.EXAMPLE
    PS C:\> Send-OutlookMail.ps1
    Sends an email message to ehuffman@elliot-labs.com with the subject of "subject", and a body of "Your message here<br>HTML Capable!"
.EXAMPLE
    PS C:\> Send-OutlookMail.ps1
    Sends an email message to ehuffman@elliot-labs.com with the subject of "Powershell DooDads: Send-OutlookMail Test", and a body of:
    Your message here<br>HTML Capable!<br><br>Psst, the test was successful 😎
.EXAMPLE
    PS C:\> Send-OutlookMail.ps1 -To "Elliot.Huffman@Microsoft.com","EHuffman@Elliot-Labs.com"
    Sends an email message to Elliot.Huffman@Microsoft.com and EHuffman@Elliot-Labs.com, with the subject of "Powershell DooDads: Send-OutlookMail Test", and a body of:
    Your message here<br>HTML Capable!<br><br>Psst, the test was successful 😎
.EXAMPLE
    PS C:\> Send-OutlookMail.ps1 -Subject "Hello World!"
    Sends an email message to EHuffman@Elliot-Labs.com, with the subject of "Hello World!", and a body of:
    Your message here<br>HTML Capable!<br><br>Psst, the test was successful 😎
.EXAMPLE
    PS C:\> Send-OutlookMail.ps1 -Body "World!" -Subject "Hello" -To User@Contoso.com
    Sends an email message to user@contoso.com, with the subject of "Hello", and a body of "World!"
.PARAMETER To
    This parameter can take an array of email addresses.
    Each address will have the specified email sent to it.
    By default the email will go to ehuffman@elliot-labs.com
.PARAMETER Subject
    This parameter optionally sets the subject line of the email that is being created.
    The default value is "Powershell DooDads: Send-OutlookMail Test".
    This parameter can only accept standard text, HTML will not be parsed.
.PARAMETER Body
    This parameter sets the value of the body of the email.
    HTML is parsed in this parameter, so you can use standard tags such as <br> for breaks.
    Multi lined strings are also supported.
.INPUTS
    System.String[]
    System.String
.OUTPUTS
    Void
.LINK
    https://github.com/elliot-labs/Powershell-Doodads
.NOTES
    Outlook is required to be installed for this script to work.
    Exit codes:
    1 - Outlook has not been initialized properly, check to ensure it has been installed.
    2 - Outlook process closed while script was running and the script could not recover from this.
        Closing outlook while a COM Object is loaded will clear the COM Object even though the com object is separate from the GUI.
#>

# Bind to the cmdlet interface for common params and behaviors
[CmdletBinding(SupportsShouldProcess = $true)]

# Initialize the parameters
param(
    [Parameter(
        # Parameter can be omitted
        Mandatory = $false,
        # Parameter is the first positional parameter if used positionally
        Position = 0,
        # The below two value from pipeline options make it so that pipeline automatic matching magic happens
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    # Ensures that a user doesn't send a empty value to the parameter (this would cause issues)
    [ValidateNotNullOrEmpty()]
    [String[]]$To = "ehuffman@elliot-labs.com",
    [Parameter(
        # Parameter can be omitted
        Mandatory = $false,
        # Parameter is the first positional parameter if used positionally
        Position = 1,
        # The below two value from pipeline options make it so that pipeline automatic matching magic happens
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    # Ensures that a user doesn't send a empty value to the parameter (this would cause issues)
    [ValidateNotNullOrEmpty()]
    [String]$Subject = "Powershell DooDads: Send-OutlookMail Test",
    [Parameter(
        # Parameter can be omitted
        Mandatory = $false,
        # Parameter is the first positional parameter if used positionally
        Position = 2,
        # The below two value from pipeline options make it so that pipeline automatic matching magic happens
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    # Ensures that a user doesn't send a empty value to the parameter (this would cause issues)
    [ValidateNotNullOrEmpty()]
    [String]$Body = "Your message here<br>HTML Capable!<br><br>Psst, the test was successful 😎"
    # [Parameter(
    #     # Parameter can be omitted
    #     Mandatory = $false,
    #     # Parameter is the first positional parameter if used positionally
    #     Position = 3,
    #     # The below two value from pipeline options make it so that pipeline automatic matching magic happens
    #     ValueFromPipeline = $true,
    #     ValueFromPipelineByPropertyName = $true
    # )]
    # # Ensures that a user doesn't send a empty value to the parameter (this would cause issues)
    # [ValidateNotNullOrEmpty()]
    # [string[]]$CarbonCopy,
    # [Parameter(
    #     # Parameter can be omitted
    #     Mandatory = $false,
    #     # Parameter is the first positional parameter if used positionally
    #     Position = 4,
    #     # The below two value from pipeline options make it so that pipeline automatic matching magic happens
    #     ValueFromPipeline = $true,
    #     ValueFromPipelineByPropertyName = $true
    # )]
    # # Ensures that a user doesn't send a empty value to the parameter (this would cause issues)
    # [ValidateNotNullOrEmpty()]
    # [string[]]$BlindCarbonCopy
) 

# Initialize the script
Begin {

    # Get a copy of the Process ID of the process that is the parent of the powershell instance.
    $ParentID = (Get-CimInstance win32_process | Where-Object processid -eq  $pid).ParentProcessId

    # Set a list of process that can accept object based returns.
    $ListOfProcessHosts = "powershell", "explorer", "conhost", "code"

    # Checks if the name of the process that matches the parent id is present in the list
    if ((Get-Process -id $ParentID).Name -in $ListOfProcessHosts) {
        # If the process is in the list, set the return variable to true
        $SetReturn = $true
    } else {
        # If the process is not in the list, set the return variable to false
        $SetReturn = $false
    }

    Function New-Outlook {
        <#
        .SYNOPSIS
            Returns an Outlook COM Object instance
        .DESCRIPTION
            Initializes outlook and returns a COM instance of it after error checking.
        .EXAMPLE
            PS C:\> New-Outlook
            Return an Outlook COM Object.
        .OUTPUTS
            Microsoft.Office.Interop.Outlook.ApplicationClass
        .LINK
            https://github.com/elliot-labs/Powershell-Doodads
        .NOTES
            Exit Codes:
            1 - Outlook has not been initialized properly, check to ensure it has been installed.
        #>

        Write-Verbose -Message "Instantiating outlook object"

        # Initialize outlook
        $OutlookObject = New-Object -ComObject Outlook.Application

        # Write debug info to the console
        Write-Debug -Message $OutlookObject
        Write-Debug -Message $OutlookObject.Session

        # Check to see if the object has been created properly
        if ($OutlookObject -IsNot [Microsoft.Office.Interop.Outlook.ApplicationClass]) {
            Write-Error "Outlook has not been initialized properly. Check to make sure it is installed."
            Exit 1
        } else {
            # If the Object was created, return it
            Return $OutlookObject
        }
    }

    # Capture the common parameter overrides to inherit the values to all cmdlets
    if (-not $PSBoundParameters.ContainsKey('Debug')) {
        $DebugPreference = $PSCmdlet.SessionState.PSVariable.GetValue('DebugPreference')
    }
    if (-not $PSBoundParameters.ContainsKey('Verbose')) {
        $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
    }
    if (-not $PSBoundParameters.ContainsKey('Confirm')) {
        $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
    }
    if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
        $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
    }

    # Write debug info to the console
    Write-Debug -Message $VerbosePreference
    Write-Debug -Message $ConfirmPreference
    Write-Debug -Message $WhatIfPreference

    # Initialize the email counter
    [int]$EmailsSent = 0

    # Write debug info to the console
    Write-Debug -Message $EmailsSent

    # Instantiate Outlook's COM Object
    $Outlook = New-Outlook
}

# Create emails and place them in the outbox of outlook
Process {
    # Write verbose info to the console
    Write-Verbose -Message "Incrementing email sent counter"

    # Increment the emails sent counter
    $EmailsSent++

    # Write debug info to the console
    Write-Debug -Message $EmailsSent

    # Check to see if outlook was terminated while the script was running.
    # If the ComObject is empty, the script will try to re-init the object. If the re-init fails, the script exits unsuccessfully.
    if ($null -eq $Outlook.Application) {

        # Write verbose info to the console
        Write-Verbose -Message "Outlook is not currently initialized, re-initializing outlook"
        
        # Re-init the Outlook object
        $Outlook = New-Outlook

        # Check if the Outlook Object is still null.
        if ($null -eq $Outlook.Application) {
            # Write debug info to the console
            Write-Debug -Message $Outlook

            # Write an error message to the PS host
            Write-Error -Message "The Outlook application was closed while the script was running!"
            
            # Exit script unsuccessfully
            exit 2
        }
    }

    # Check for WhatIf common parameter
    if ($PSCmdlet.ShouldProcess("Memory", "Create eMail")) {
        # Write verbose info to the console
        Write-Verbose -Message "Composing message to $To"

        # Create the email
        $Mail = $Outlook.CreateItem(0)
        # Take the array of addresses to email to and join it into a single string of addresses separated by a semicolon, outlook style.
        $Mail.To = $To -join ";"
        # Set the subject of the email
        $Mail.Subject = $Subject
        # Set the body of the email
        $Mail.HTMLBody = $Body

        # Write debug info to the console
        Write-Debug -Message $Mail

        # Write verbose info to the console
        Write-Verbose -Message "Placing email in outbox"
    }

    # Check for WhatIf common parameter
    if ($PSCmdlet.ShouldProcess("Outbox", "Write eMail")) {
        # Put the email in the outbox
        $Mail.Send()
    }
}

# Clean up after execution has completed
End {
    if ($PSCmdlet.ShouldProcess("Outlook", "Send and Receive")) {
        # Write verbose info to the console
        Write-Verbose -Message "Forcing a send and receive to process emails in outbox"

        # Force a send and receive
        $Outlook.GetNameSpace("MAPI").SendAndReceive(1)   
    }
    
    # Write verbose info to the console
    Write-Verbose -Message "Releasing Outlook COM object instance from memory"

    # Clean up the objects that were created
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Outlook) | Out-Null
    $Outlook = $Null

    if ($PSCmdlet.ShouldProcess("$EmailsSent eMails", "Simulated send")) {
        # Write verbose info to the console
        Write-Verbose -Message "Sent $EmailsSent emails"
    }
}