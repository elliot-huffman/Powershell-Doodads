<#
.SYNOPSIS
    App that decrypts .IntuneWin files and controls logging verbosity levels of Microsoft Endpoint Manager (MEM). 
.DESCRIPTION
    Downloads and decrypts an IntuneWin file based on MEM's Extension's debug level logging info.
    Can also change the debugging level of MEM's Extension to allow for the collection of the decryption data.

    PLEASE NOTE that enabling verbose logging on MEM's Extension will write secrets to the app's log.
    This is a big security risk and should not be performed on a production system.
    If logging level are turned up, please turn them back down to normal levels by using the -Disable parameter.
    After the logging level is turned down again, please clear the logs or reimage the computer to ensure the secrets are cleared off the machine.
    THESE SECRETS COULD BE USED FOR IMPERSONATION OR SYSTEM COMPROMISE, PEASE CLEAR THEM ASAP AFTER FINISHED!!! 
.PARAMETER Decrypt
    When this param is specified, the script will auto parse the Endpoint Manager Extension log files, download and decrypt the specified Intune Apps.
.PARAMETER AppId
    Takes an array of GUIDs that correspond to the MEM app.
    Each app specified will be checked against the local install base and operated upon.
.PARAMETER Path
    Path to the folder where the decrypted IntuneWin files will be placed.
.PARAMETER List
    If this parameter is specified, the decryption process will not take place, only log parsing.
    The app will return a list of app IDs that are found on the local machine that have the required metadata for IntuneWin decryption.
.PARAMETER Enable
    Enables verbose logging for the Intune Management Extension.
    This is a security risk and should not be left on after decryption operation is completed.
    This will restart the IME service as IME only changes log level on service start.
.PARAMETER Disable
    Reverts the settings to the original value for the logging output of the Intune Management Extension.
    This does not disable logging, just reverts the settings back to what they were before this script was run to enable it in the first place.
    This will restart the IME service as IME only changes log level on service start.
.PARAMETER ClearLog
    Clears the IME logs to prevent sensitive info leakage without needing the system to be re-imaged.
    This will restart the IME service as the current log file needs to be unlocked.
.ROLE
    Mobile Device Management Admin
    Endpoint Admin
    Systems Admin
    Systems Engineer
    Reverse Engineer
.COMPONENT
    Microsoft Endpoint Manager
    Intune
.EXAMPLE
    PS C:\> .\Unprotect-IntuneWin.ps1 -Enable
    Enable verbose logging on the MEM Extension and restart the service to ensure that the settings take effect.
.EXAMPLE
    PS C:\> .\Unprotect-IntuneWin.ps1 -Disable
    Disable abd revert to the original settings the verbose logging on the MEM Extension and restart the service to ensure that the settings take effect.
.EXAMPLE
    PS C:\> .\Unprotect-IntuneWin.ps1 -ClearLog
    Stops the MEM Extension and clears the MEM Extension logs.
    This is useful to clear the logs after the decryption process has been completed and the secrets need to be cleared off the system.
.EXAMPLE
    PS C:\> .\Unprotect-IntuneWin.ps1 -Decrypt -List
    Lists out the App IDs that are found on the local system that can be decrypted.
    In most cases, apps that are installed while verbose logging is enabled will be visible in this list.
    The App IDs returned will correspond to the ID of the app in MEM's management portal.
    To find the IDs of your apps, open an app in the MEM portal and look in the address bar or use the Microsoft.Graph PowerShell module to list the apps.
.EXAMPLE
    PS C:\> .\Unprotect-IntuneWin.ps1 -Decrypt -AppId "345a0895-4978-49ad-b030-78b0e1c32599"
    Downloads and decrypts the MEM App that corresponds to "345a0895-4978-49ad-b030-78b0e1c32599" if the decryption info is found on the local system.
    If you have not downloaded and installed it on the local system, it will not be able to download or decrypt the app because the logs won't have the metadata present.
.EXAMPLE
    PS C:\> .\Unprotect-IntuneWin.ps1 -Decrypt -AppId "345a0895-4978-49ad-b030-78b0e1c32599", "14c00b5a-c383-4a79-90a7-82801df25afc"
    Downloads and decrypts the MEM Apps that correspond to "345a0895-4978-49ad-b030-78b0e1c32599" and "14c00b5a-c383-4a79-90a7-82801df25afc" if the decryption info is found on the local system.
    If you have not downloaded and installed them on the local system, they won't be able to be downloaded or decrypted because the logs won't have the metadata present.
.EXAMPLE
    PS C:\> .\Unprotect-IntuneWin.ps1 -Decrypt -AppId "345a0895-4978-49ad-b030-78b0e1c32599" -Path "C:\MEM\ReverseEngineering\"
    Downloads and decrypts the MEM App that corresponds to "345a0895-4978-49ad-b030-78b0e1c32599" if the decryption info is found on the local system.
    If you have not downloaded and installed it on the local system, it will not be able to download or decrypt the app because the logs won't have the metadata present.
    The process will take place in the "C:\MEM\ReverseEngineering\" folder, which means the .IntuneWin and the resultant .Zip files will be placed there after the process has completed.
.INPUTS
    Switch
    System.String
    System.Guid[]
.OUTPUTS
    System.Void
    System.String[]
.LINK
    https://github.com/elliot-huffman/Powershell-Doodads
.NOTES
    Requires Admin rights.
    Required to be run on the machine that downloaded the IntuneWin from the MEM service.
        MEM only gives the decryption cert to the machine that downloaded it.

    Return Codes:
        0 - Program run successfully
        1 - Verbose logging mode is already enabled for IME. If you meant to disable it, please use the "Disable" parameter
        2 - Verbose logging mode is not currently set. It has been disabled already in most cases. If not disabled, something external to this script has modified the value. Please set the setting manually.
#>

# Define system requirements for powershell pre-launch checks to validate
#Requires -RunAsAdministrator

# Enable Cmdlet binding for advanced functionality support
# Also specify the default param set to avoid issues where an error is thrown on insufficient param usage.
[CmdletBinding(
    SupportsShouldProcess = $true,
    DefaultParameterSetName = 'Decrypt'
)]

# Allow dynamic input for increased usability
param(
    [Parameter(ParameterSetName = 'Enable', Mandatory = $true)]
    [Switch]$Enable,
    [Parameter(ParameterSetName = 'Disable', Mandatory = $true)]
    [Switch]$Disable,
    [Parameter(ParameterSetName = 'Clear Log', Mandatory = $true)]
    [Switch]$ClearLog,
    [Parameter(ParameterSetName = 'Decrypt - List', Mandatory = $true)]
    [Parameter(ParameterSetName = 'Decrypt', Mandatory = $true)]
    [Switch]$Decrypt,
    [Parameter(ParameterSetName = 'Decrypt', Mandatory = $true)]
    [System.Guid[]]$AppId,
    [Parameter(ParameterSetName = 'Decrypt')]
    [ValidateScript({ Test-Path -Path $_ -PathType 'Container' })]
    [System.String]$Path = $PWD,
    [Parameter(ParameterSetName = 'Decrypt - List', Mandatory = $true)]
    [Switch]$List
)

#region Settings Init

# Write verbose information about current script processing state
Write-Verbose -Message "Initializing Script Settings"

# Define the location of the settings file for this script
[System.String]$SettingListFilePath = "$env:ProgramData\PSDoodads\Unprotect-IntuneWin\Settings.xml"

# Check if the folder that the settings file resides at is not present
if (-not (Test-Path -Path $env:ProgramData\PSDoodads\Unprotect-IntuneWin\ -PathType 'Container')) {
    # Support command simulation
    if ($PSCmdlet.ShouldProcess("Settings Folder", "Create")) {
        # Create the directory that stores the settings file
        New-Item -Path "$env:ProgramData\PSDoodads\Unprotect-IntuneWin\" -ItemType 'Directory'
    }

    # Support command simulation
    if ($PSCmdlet.ShouldProcess("Settings File", "Create")) {
        # Generate an empty settings file
        @{} | Export-Clixml -Path $SettingListFilePath   
    }
} elseif (-not (Test-Path -Path $SettingListFilePath -PathType 'Leaf')) { # Check if the settings file is not present
    # Support command simulation
    if ($PSCmdlet.ShouldProcess("Settings File", "Create")) {
        # Generate an empty settings file
        @{} | Export-Clixml -Path $SettingListFilePath   
    }
}

# Get the current settings for this app
[System.Collections.Hashtable]$Settings = Import-Clixml -Path $SettingListFilePath

# Write verbose information about current script processing state
Write-Verbose -Message "Finished Script Settings Initialization"

#endregion Settings Init

# Enables verbose logging for IME
if ($Enable) {
    # Write verbose information about current script processing state
    Write-Verbose -Message "Starting enablement of verbose logging level for MEM extension"

    # Get the current .net config of the IME exe
    [XML]$ImeExeConfig = Get-Content -Path "$(${env:ProgramFiles(x86)})\Microsoft Intune Management Extension\Microsoft.Management.Services.IntuneWindowsAgent.exe.config"
    
    # Check to see if verbose mode is already enabled
    if ($ImeExeConfig.configuration.'system.diagnostics'.sources.source.switchValue -eq 'Verbose') {
        # Notify that verbose mode has already been configured for IME
        Write-Error -Message 'Verbose mode is already enabled for the Intune Management Extension'
        
        # Kill script execution and return error 1
        exit 1
    }

    # Capture the current state of the config into the settings object
    $Settings['OriginalSwitchValue'] = $ImeExeConfig.configuration.'system.diagnostics'.sources.source.switchValue

    # Support command simulation
    if ($PSCmdlet.ShouldProcess("Memory", "Change verbosity switch")) {
        # Set the verbose logging configuration for IME in memory
        $ImeExeConfig.configuration.'system.diagnostics'.sources.source.SetAttribute('switchValue', 'Verbose')
    }

    # Warn end user that this config is really risky and should be turned off asap.
    Write-Warning -Message 'Enabling verbose mode on IME is a major security risk!
Secret materials will be written to the log file, which means anyone that has access to this computer will have impersonation rights.
Please shut this off asap!
After disabling verbose mode, please clear the IME log file so the secrets are gone or reimage/reinstall the computer.'

    # Support command simulation
    if ($PSCmdlet.ShouldProcess("MEM Verbosity Config", "Flush memory to disk")) {
        # Save the changes in memory to disk
        $ImeExeConfig.Save("$(${env:ProgramFiles(x86)})\Microsoft Intune Management Extension\Microsoft.Management.Services.IntuneWindowsAgent.exe.config")
    }

    # Support Command simulation
    if ($PSCmdlet.ShouldProcess("Settings File", "Update")) {
        # Save the changes in memory to disk
        $Settings | Export-Clixml -Path $SettingListFilePath
    }

    # Support Command simulation
    if ($PSCmdlet.ShouldProcess("MEM Extension Service", "Restart")) {
        # Restart the IME service for the changes to take effect
        Restart-Service -Name 'IntuneManagementExtension'
    }

    # Write verbose information about current script processing state
    Write-Verbose -Message "Completed enablement of verbose logging level for MEM extension"

    # Exit the script successfully
    exit 0
}

# Turn off verbose logging for IME, reverting to the previous setting if one is present
if ($Disable) {
    # Write verbose information about current script processing state
    Write-Verbose -Message "Starting reverting of verbose logging level for MEM extension"

    # Get the current .net config of the IME exe
    [XML]$ImeExeConfig = Get-Content -Path "$(${env:ProgramFiles(x86)})\Microsoft Intune Management Extension\Microsoft.Management.Services.IntuneWindowsAgent.exe.config"

    # Check to see if verbose mode is not configured
    if ($ImeExeConfig.configuration.'system.diagnostics'.sources.source.switchValue -ne 'Verbose') {
        # Notify that verbose mode is not configured for IME
        Write-Error -Message 'Verbose mode is not configured for the Intune Management Extension'

        # Remove the original switch value node from the settings object
        $Settings.Remove('OriginalSwitchValue')

        # Support Command simulation
        if ($PSCmdlet.ShouldProcess("Settings File", "Update")) {
            # Save the changes in memory to disk
            $Settings | Export-Clixml -Path $SettingListFilePath
        }
        
        # Kill script execution and return error 2
        exit 2
    }

    # Support command simulation
    if ($PSCmdlet.ShouldProcess("Memory", "Change MEM logging level")) {
        # Set the original value in memory to the original logging value
        $ImeExeConfig.configuration.'system.diagnostics'.sources.source.SetAttribute('switchValue', $Settings.OriginalSwitchValue)
    }

    # Remove the original switch value node from the settings object
    $Settings.Remove('OriginalSwitchValue')

    # Warn the end user that the log should be cleared if a reimage is not used.
    Write-Warning -Message 'The log file for IME most likely contains many sensitive authentication secrets.
Please clear the log or reimage the computer if this computer is going to be continued to be used!
You can clear the log automatically by using the -ClearLog parameter.'

    # Support command simulation
    if ($PSCmdlet.ShouldProcess("MEM Verbosity Config", "Flush memory to disk")) {
        # Save the changes in memory to disk
        $ImeExeConfig.Save("$(${env:ProgramFiles(x86)})\Microsoft Intune Management Extension\Microsoft.Management.Services.IntuneWindowsAgent.exe.config")
    }

    # Support Command simulation
    if ($PSCmdlet.ShouldProcess("Settings File", "Update")) {
        # Save the changes in memory to disk
        $Settings | Export-Clixml -Path $SettingListFilePath
    }
    
    # Support Command simulation
    if ($PSCmdlet.ShouldProcess("MEM Extension Service", "Restart")) {
        # Restart the IME service for the changes to take effect
        Restart-Service -Name 'IntuneManagementExtension'
    }

    # Write verbose information about current script processing state
    Write-Verbose -Message "Completed reverting of verbose logging level for MEM extension"

    # Exit the script successfully
    exit 0
}

# Clear the IME logs, including past logs
if ($ClearLog) {
    # Write verbose information about current script processing state
    Write-Verbose -Message "Starting log clear process"
    
    # Stop the IME service to unlock the log file
    Stop-Service -Name 'IntuneManagementExtension'

    # Get a list of log files
    [System.IO.FileInfo[]]$LogFileList = Get-ChildItem -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\" -Filter 'IntuneManagementExtension*.log'
    
    # Remove all the logs detected
    $LogFileList | Remove-Item

    # Start the IME service to bring the system into management again
    Start-Service -Name 'IntuneManagementExtension'

    # Write verbose information about current script processing state
    Write-Verbose -Message "Completed log clear process"

    # Exit the script successfully
    exit 0
}

# Decrypts all apps or the specified app that has been installed during verbose logging
if ($Decrypt) {
    # Write verbose information about current script processing state
    Write-Verbose -Message "Starting log parse process process"

    # List all of the MEM log files
    [System.IO.FileInfo[]]$LogFileList = Get-ChildItem -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\" -Filter 'IntuneManagementExtension*.log'

    # Read all the MEM log content into a single place
    $MemLogContent = Get-Content -Path $LogFileList

    # Initialize a variable to store the App's collected metadata
    # The key is the Endpoint Manager App ID
    # The value is an array where:
    #   Index 0 - Is URL to the MEM CDN endpoint that hosts the IntuneWin file
    #   Index 1 - Is the base64 decoded encryption key used to decrypt the IntuneWin file
    #   Index 2 - Is the base64 decoded initialization vector used to decrypt the IntuneWin file
    [System.Collections.Hashtable]$AppMetaData = @{}

    # Search through the content and extract the app metadata found
    foreach ($Line in $MemLogContent) {
        # Check if a MEM object was returned from MEM
        if ($Line -match '<!\[LOG\[Response from Intune = {') {
            # Move (the enumerator) to the next line and ignore the output
            $ForEach.MoveNext() | Out-Null

            # Check if the current line matches contains the metadata we need and not just some other data
            if (($ForEach.Current -match 'decryptinfo') -and (-not ($ForEach.Current -match 'outbound data:'))) {
                # Take the current line's text and parse it to JSON
                $ParsedRootJson = "{$($ForEach.Current)}" | ConvertFrom-Json

                # Parse the Response Payload property to an object
                $ParsedResponsePayload = $ParsedRootJson.ResponsePayload | ConvertFrom-Json

                # Parse the ContentInfo property into an object
                $ParsedContentInfo = $ParsedResponsePayload.ContentInfo | ConvertFrom-Json

                # Parse the embedded XML into an object, and access teh encrypted property and convert the value from a base 64 string to a byte array
                $ByteArray = [System.Convert]::FromBase64String(([xml]$ParsedResponsePayload.DecryptInfo).EncryptedMessage.EncryptedContent)

                # Instantiate a PKCS CMS container
                $CmsContentInstance = New-Object -TypeName 'Security.Cryptography.Pkcs.EnvelopedCms'

                # Decode the content to the correct decryption format
                $CmsContentInstance.Decode($ByteArray)

                # Run the decryption command against the CMS container
                $CmsContentInstance.Decrypt()

                # Convert the decrypted Byte Array in the CMS container to a UTF8 string then parse the resulting JSON structure to an object
                $ParsedDecryptInfo = [System.Text.Encoding]::UTF8.GetString($CmsContentInstance.ContentInfo.Content) | ConvertFrom-Json

                # Store the identified app's metadata in the app metadata store
                $AppMetaData.($ParsedResponsePayload.ApplicationId) = @([System.Uri]$ParsedContentInfo.UploadLocation, [System.Convert]::FromBase64String($ParsedDecryptInfo.EncryptionKey), [System.Convert]::FromBase64String($ParsedDecryptInfo.IV))
            }
        }
    }

    # Write verbose information about current script processing state
    Write-Verbose -Message "completed log parse process process"

    # Check if list mode is requested
    if ($List) {
        # Return a list of IDs detected in the MEM extension logs
        return $AppMetaData.Keys
    } else {
        # Write verbose information about current script processing state
        Write-Verbose -Message "Starting download and decrypt process"

        # List mode was not requested, run through live decryption
        # Iterate through each specified MEM App GUID and decrypt the requested ID 
        foreach ($Id in $AppId) {
            # Check if the ID exists
            if (-not $AppMetaData -contains $Id) {
                # Skip the requested app as it was not found
                continue
            }

            # Store the original progress bar configuration
            $OriginalProgress = $ProgressPreference

            # Disable the progress bar
            $ProgressPreference = 'SilentlyContinue'

            # Support command simulation
            if ($PSCmdlet.ShouldProcess("IntuneWin on MEM CDN", "Download to specified directory")) {
                # Download the IntuneWin file (with no progress bar)
                Invoke-WebRequest -Uri $AppMetaData."$Id"[0] -OutFile "$Path\$($AppMetaData."$Id"[0].Segments[-1])"
            }

            # Restore the progress bar to the original state
            $ProgressPreference = $OriginalProgress

            # Create an instance of the AES provider subsystem
            $AES = [System.Security.Cryptography.Aes]::Create()

            # Create a decryptor for the specified IntuneWin file
            $DecryptorHelper = $AES.CreateDecryptor($AppMetaData."$Id"[1], $AppMetaData."$Id"[2])

            # Support command simulation
            if ($PSCmdlet.ShouldProcess("Decrypted ZIP File Container", "Create")) {
                # Create a file stream for the new file to be created
                [System.IO.FileStream]$FileStreamOutput = [System.IO.File]::Open("$Path\$($AppMetaData."$Id"[0].Segments[-1]).zip", 'Create', 'ReadWrite', 'None')
            }
            
            # Support command simulation
            if ($PSCmdlet.ShouldProcess("Downloaded IntuneWin file", "Open File Stream")) {
                # Create a file stream for the IntuneWin file that was just downloaded
                [System.IO.FileStream]$FileStreamInput = [System.IO.File]::Open("$Path\$($AppMetaData."$Id"[0].Segments[-1])", 'Open', 'Read', 'None')

                # Move 48 bytes from the beginning to the right to skip a bunch of encryption metadata that is irrelevant.
                $FileStreamInput.Seek(48, 'Begin') | Out-Null
            }

            # Support command simulation
            if ($PSCmdlet.ShouldProcess("File Output Stream", "Connect Crypto Stream")) {
                # Create a crypto stream to facilitate the decryption of the IntuneWin file
                $CryptoStream = [System.Security.Cryptography.CryptoStream]::new($FileStreamOutput, $DecryptorHelper, 'Write')
            }

            # Initialize some scratch space for the decryption process
            [System.Int32]$ScratchSpace = $null
            
            # Loop through all the data in the input stream and decrypt it
            while (($ScratchSpace = $FileStreamInput.ReadByte()) -ne -1) {
                # Support command simulation
                if ($PSCmdlet.ShouldProcess("Crypto Stream", "Decrypt encrypted data and send to output")) {
                    # Decrypt the current set of data and write it to the output stream in memory
                    $CryptoStream.WriteByte([byte]$ScratchSpace)
                }
            }

            # Support command simulation
            if ($PSCmdlet.ShouldProcess("Crypto Stream", "Flush remaining to disk")) {
                # Flush the data to the disk
                $CryptoStream.Flush()

                # Ensure the final data is written to disk from memory
                $CryptoStream.FlushFinalBlock()
            }

            # Support command simulation
            if ($PSCmdlet.ShouldProcess("Sensitive Items", "Clean Up")) {
                # Clear up resources to ensure nothing sensitive is left in memory
                $CryptoStream.Dispose()
                $FileStreamInput.Dispose()
                $FileStreamOutput.Dispose()
                $DecryptorHelper.Dispose()
                $AES.Dispose()
            }
        }
    }

    # Write verbose information about current script processing state
    Write-Verbose -Message "Completed download and decrypt process"

    # Exit the script successfully
    exit 0
}