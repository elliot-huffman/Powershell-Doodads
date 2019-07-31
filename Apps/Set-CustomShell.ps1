<#
.SYNOPSIS
    Sets up the Shell Launcher feature of Windows 10
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.PARAMETER ComputerName
    parameter info
.PARAMETER User
    parameter info
.PARAMETER ShellAction
    parameter info
.INPUTS
    System.String
.OUTPUTS
    Output (if any)
.LINK
    https://github.com/elliot-labs/PowerShell-Doodads
.NOTES
    Requires the Enterprise or Education edition of Windows 10.
    Requires administrative privileges.

    Exit codes:
    1 - Incorrect windows edition (required Enterprise or Education to operate)
    2 - Shell Launcher is not enabled in the system
#>

#Requires -RunAsAdministrator

param (
    [string]$ComputerName = "localhost",
    [string]$User = $env:USERNAME,
    [Parameter(
        Mandatory = $false,
        Position = 2
    )]
    [ValidateSet("Restart Application", "Restart Computer", "Shutdown Computer", "Do Nothing")]
    [String]$ShellAction = "Do Nothing"
)

Begin {
    # Check to see if the required Edition of Windows 10 is present.
    # If not, stop execution of the script.
    if ((Get-WindowsEdition -Online).Edition -NotIn "Enterprise", "Education") {

        # Write error to console
        Write-Error "This device doesn't have required license to use Custom Shell"

        # Exit execution
        exit 1
    }

    # Checks the user selected shell action and set the action number to the appropriate integer
    Switch ($ShellAction) {
        "Restart Application" { [Int32]$ShellActionNumber = 0 ; break }
        "Restart Computer" { [Int32]$ShellActionNumber = 1 ; break }
        "Shutdown Computer" { [Int32]$ShellActionNumber = 2 ; break }
        "Do Nothing" { [Int32]$ShellActionNumber = 3 ; break }
        Default { [Int32]$ShellActionNumber = 3 }
    }

    # This well-known security identifier (SID) corresponds to the BUILTIN\Administrators group.
    $AdminSID = "S-1-5-32-544"

    # Create a function to retrieve the SID for a user account on a machine. Works with domain accounts.
    Function Get-UserSID {
        <#
        .SYNOPSIS
            Converts a username to a SID
        .DESCRIPTION
            Takes an NT Account context and converts it to a SID.
            This works on local accounts and domain accounts.
        .EXAMPLE
            PS C:\> Get-UserSID
            Returns the SID for the user account that is executing the function.
        .EXAMPLE
            PS C:\> Get-UserSID -Account "ehuffman"
            Returns the SID for the specified user account.
        .PARAMETER Account
            The account parameter is used to specify a custom account.
            The custom account can be a domain user or a local account.
            This parameter can receive pipeline input.
        .INPUTS
            System.Security.Principal.NTAccount
        .OUTPUTS
            System.String
        #>

        param (
            [Parameter(
                Position = 0,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true
            )]
            [ValidateNotNullOrEmpty()]
            [System.Security.Principal.NTAccount[]]$Account = $env:USERNAME
        )

        # Set up the required variable
        Begin {
            $AccountArray = @()
        }

        # Convert the username to SID
        Process {
            foreach ($User in $Account) {
                # Convert the NT Account context to a SID object
                [System.Security.Principal.SecurityIdentifier]$UserSID = $User.Translate([System.Security.Principal.SecurityIdentifier])
        
                # Return the value of the SID
                $AccountArray += $UserSID.Value
            }
        }

        # Return the results
        End {
            Return $AccountArray
        }
    }
}

Process {
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        # Sets up the shell launcher feature on the remote computer
        dism --% /online /enable-feature /all /featureName:client-EmbeddedShellLauncher /NoRestart
    }

    # Create a handle to the class instance so we can call the static methods.
    try {
        $ShellLauncherClass = [WMIClass]"\\$COMPUTER\root\standardCIMv2\embedded:WESL_UserSetting"
    }
    catch [Exception] {
        Write-Error $_.Exception.Message;
        Write-Error "Make sure Shell Launcher feature is enabled"
        exit 2
    }

    # Get the SID for a user account named "Cashier". Rename "Cashier" to an existing account on your system to test this script.
    $TargetUserSID = Get-UsernameSID($User)

    # Sets the default shell for Windows to explorer and to do nothing if it is closed (this is the default behavior of windows)
    $ShellLauncherClass.SetDefaultShell("explorer.exe", 3)

    # Create launch script
    Set-Content -Path "C:\Start-CustomShellApplication.ps1" -Value 'Start-Process -FilePath "C:\Path\To\File"'

    # Remove current custom shell settings to allow new settings to be applied if settings already exist
    $ShellLauncherClass.removeCustomShell($TargetUserSID) | Out-Null
    $ShellLauncherClass.removeCustomShell($AdminSID) | Out-Null

    # Set Internet Explorer as the shell for "Cashier", and restart the machine if Internet Explorer is closed.
    $ShellLauncherClass.SetCustomShell($TargetUserSID, "PowerShell -WindowStyle Hidden -File C:\Start-CustomShellApplication.ps1", ($null), ($null), $ShellActionNumber)

    # Set Explorer as the shell for administrators.
    $ShellLauncherClass.SetCustomShell($AdminSID, "explorer.exe")

    # Enable Shell Launcher
    $ShellLauncherClass.SetEnabled($TRUE)
}

end {
    # pass
}