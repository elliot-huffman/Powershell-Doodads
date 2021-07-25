<#
.SYNOPSIS
    Sets up the Shell Launcher feature of Windows 10
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.PARAMETER ComputerName
    The name of the computer to execute this script against.
    If set to local host, no WinRM invocation will happen as the script will intelligently execute outside of a remote session.
.PARAMETER User
    The user account that will have the custom shell settings applied to.
    Do not specify a SID, the system will auto convert the name to a SID for you.

    If no value is specified, it will take the current user's account name as the default setting and apply the specified shell settings to it.
.PARAMETER ShellAction
    This configures the action which will be taken if the shell process is terminated.
    The restart application option will start the application specified in the custom shell settings.
    Restart, shutdown, and do nothing options will all do as named.
.INPUTS
    System.String
.OUTPUTS
    Void
.LINK
    https://github.com/elliot-labs/PowerShell-Doodads
.NOTES
    Requires the Enterprise or Education edition of Windows 10.
    Requires administrative privileges.

    Some applications require a user profile to be created so that data can be stored in the app data location (e.g. Microsoft Edge).
    You may need to log in to the account that is to be designated as the kiosk account before enabling the custom shell.

    If you execute this script against remote computers, the remote computers must be accessible via WinRM using the executing user's credentials.

    Exit codes:
    1 - Incorrect windows edition (required Enterprise or Education to operate)
    2 - Shell Launcher is not enabled in the system
#>

#Requires -RunAsAdministrator

param (
    [System.String]$ComputerName = "localhost",
    [System.String]$User = $env:USERNAME,
    [Parameter(
        Mandatory = $false,
        Position = 2
    )]
    [ValidateSet("Restart Application", "Restart Computer", "Shutdown Computer", "Do Nothing")]
    [System.String]$ShellAction = "Do Nothing"
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

    # Create a script block that can enabled the custom shell launcher on a system.
    [System.Management.Automation.ScriptBlock]$Script_EnableShellLauncher = {
        # Sets up the shell launcher feature on the remote computer
        Enable-WindowsOptionalFeature -Online -FeatureName "Client-EmbeddedShellLauncher" -NoRestart
    }

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
    # If the script is being executed locally, execute the scriptblock locally without invoking WinRM systems.
    # Otherwise use WinRM to execute the optional feature installation.
    if (($ComputerName -eq "localhost") -or ($ComputerName -match "127.[0-9]*.[0-9]*.[0-9]*")) {
        & $Script_EnableShellLauncher
    } else {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock $Script_EnableShellLauncher
    }
    

    # Create a handle to the class instance so we can call the static methods.
    try {
        $ShellLauncherClass = [WMIClass]"\\$ComputerName\root\standardCIMv2\embedded:WESL_UserSetting"
        # Get-CimClass -Namespace "root\standardCIMv2/embedded" -ClassName "WESL_UserSetting"
    }
    catch [Exception] {
        Write-Error $_.Exception.Message;
        Write-Error "Make sure Shell Launcher feature is enabled"
        exit 2
    }

    # Get the SID for a user account named "Cashier". Rename "Cashier" to an existing account on your system to test this script.
    $TargetUserSID = Get-UsernameSID -Account $User

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