<#
.SYNOPSIS
    Sets the Windows NT registration.
.DESCRIPTION
    Sets and or clears the user or organization registration information.
    This can be executed remotely to bulk apply information across an organization.
    If executed remotely, powershell will need to be installed on the target machine.

    Both the Owner and Organization information can be set independently or at the same time.
    Administrative rights are required for any registration changes as teh registration is stored in the HKLM hive.
.PARAMETER Clear
    When the clear parameter is used it will set the data to "", an empty string.
    This means that it will clear the registration data.
    This is the default parameter and is what will be executed if the user does not specify a parameter.
    If the user does not specify -Clear, it will ask for user input as Clear is marked as mandatory in the metadata.
    This will essentially render the script useless unless the user specified a parameter as users can't manually enter the clear data.
.PARAMETER Owner
    The -Owner parameter is used to set the registered user/licensee information.
    This field can exist independently from the organization field.
    This field can take any string and can contain special characters.
    The path in the system registry entry that is being modified is:
        HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\RegisteredOwner
    The Registry value being stored is a string value.
.PARAMETER Organization
    The -Organization parameter is used to set the registered organization information.
    This field can exist independently from the Owner field.
    This field can take any string and can contain special characters.
    The path in the system registry entry that is being modified is:
        HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\RegisteredOrganization
    The Registry value being stored is a string value.
.PARAMETER ComputerName
    The -ComputerName parameter is used to allow for the remote execution of this code.
    It can set the owner and organization value remotely if the appropriate rights are present.
    This field can take an array of computer names and executes the operation(s) in parallel for max performance.
    The remote execution uses the "Invoke-Command" cmdlet to execute remotely.
    Powershell will need to be installed on the target machines because of the above implementation.
.EXAMPLE
    PS C:\> Set-NTRegistration -Clear
    Clears the registration data of the Windows Operating system.
    The registered field will be blank.
    To validate that registration was cleared, check "Winver.exe" "licensed to" field.
.EXAMPLE
    PS C:\> Set-NTRegistration -Owner "Elliot Huffman"
    Sets the owner registration for the local system to "Elliot Huffman".
    To validate that registration was set, check "Winver.exe" "licensed to" field.
.EXAMPLE
    PS C:\> Set-NTRegistration -Organization "Elliot Labs LLC"
    Sets the organization registration for the local system to "Elliot Labs LLC".
    To validate that registration was set, check "Winver.exe" "licensed to" field.
.EXAMPLE
    PS C:\> Set-NTRegistration -Clear -ComputerName "Test-DC","Test-Admin"
    Clears the registration data of the Windows Operating system.
    This operates on the remote computers, "Test-Admin" and "Test-DC".
    This uses the WS-MAN protocol, which requires Powershell to be installed on the target.
    The registered field will be blank.
    To validate that registration was cleared, check "Winver.exe" "licensed to" field on each target.
.EXAMPLE
    PS C:\> Set-NTRegistration -Owner "Elliot Huffman" -ComputerName "Test-DC","Test-Admin"
    Sets the owner registration for the local system to "Elliot Huffman".
    This operates on the remote computers, "Test-Admin" and "Test-DC".
    This uses the WS-MAN protocol, which requires Powershell to be installed on the target.
    To validate that registration was cleared, check "Winver.exe" "licensed to" field on each target.
.EXAMPLE
    PS C:\> Set-NTRegistration -Organization "Elliot Labs LLC" -ComputerName "Test-DC","Test-Admin"
    Sets the organization registration for the local system to "Elliot Labs LLC".
    This operates on the remote computers, "Test-Admin" and "Test-DC".
    This uses the WS-MAN protocol, which requires Powershell to be installed on the target.
    To validate that registration was cleared, check "Winver.exe" "licensed to" field on each target.
.INPUTS
    Switch
    System.String
    System.String[]
.OUTPUTS
    Void
.LINK
    https://github.com/elliot-labs/PowerShell-Doodads
.NOTES
    Requirements:
        Rights to edit the HKEY_Local_Machine registry hive; This is usually administrator rights.
        This applies to both local and remote targets.
#>

#Requires -RunAsAdministrator

# Cmdlet bind the script to enable advanced functions
# Set ShouldProcess to $true to enable the capability to use -WhatIf and -Confirm
[CmdletBinding(
    SupportsShouldProcess=$true,
    DefaultParameterSetName='Clear'
)]

Param (
    # Create the Clear parameter and set metadata
    # It is its own param set and should not be used with any other param combos
    [Parameter(
        Mandatory=$true,
        ParameterSetName="Clear"
    )]
    [Switch]$Clear,

    # Create the Owner parameter and set metadata
    [Parameter(
        Mandatory=$false,
        Position=0,
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='Set-Data'
    )]
    [ValidateNotNullOrEmpty()]
    [System.String]$Owner,

    # Create the Organization parameter and set metadata
    [Parameter(
        Mandatory=$false,
        Position=1,
        ValueFromPipelineByPropertyName=$true,
        ParameterSetName='Set-Data'
    )]
    [ValidateNotNullOrEmpty()]
    [System.String]$Organization,

    # Validate that the computer(s) is/are accessible
    [ValidateScript({Test-Connection -ComputerName $_ -Quiet})]
    # Ensure that the data is not empty
    [ValidateNotNullOrEmpty()]
    [Parameter(
        Mandatory=$false,
        ValueFromPipelineByPropertyName=$true
    )]
    [System.String[]]$ComputerName
)

function Set-NTRegistration {
    <#
    .SYNOPSIS
        Sets the Windows NT registration.
    .DESCRIPTION
        Sets and or clears the user or organization registration information.
        This can be executed remotely to bulk apply information across an organization.
        If executed remotely, powershell will need to be installed on the target machine.

        Both the Owner and Organization information can be set independently or at the same time.
        Administrative rights are required for any registration changes as teh registration is stored in the HKLM hive.
    .PARAMETER Clear
        When the clear parameter is used it will set the data to "", an empty string.
        This means that it will clear the registration data.
        This is the default parameter and is what will be executed if the user does not specify a parameter.
        If the user does not specify -Clear, it will ask for user input as Clear is marked as mandatory in the metadata.
        This will essentially render the script useless unless the user specified a parameter as users can't manually enter the clear data.
    .PARAMETER Owner
        The -Owner parameter is used to set the registered user/licensee information.
        This field can exist independently from the organization field.
        This field can take any string and can contain special characters.
        The path in the system registry entry that is being modified is:
            HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\RegisteredOwner
        The Registry value being stored is a string value.
    .PARAMETER Organization
        The -Organization parameter is used to set the registered organization information.
        This field can exist independently from the Owner field.
        This field can take any string and can contain special characters.
        The path in the system registry entry that is being modified is:
            HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\RegisteredOrganization
        The Registry value being stored is a string value.
    .PARAMETER ComputerName
        The -ComputerName parameter is used to allow for the remote execution of this code.
        It can set the owner and organization value remotely if the appropriate rights are present.
        This field can take an array of computer names and executes the operation(s) in parallel for max performance.
        The remote execution uses the "Invoke-Command" cmdlet to execute remotely.
        Powershell will need to be installed on the target machines because of the above implementation.
    .EXAMPLE
        PS C:\> Set-NTRegistration -Clear
        Clears the registration data of the Windows Operating system.
        The registered field will be blank.
        To validate that registration was cleared, check "Winver.exe" "licensed to" field.
    .EXAMPLE
        PS C:\> Set-NTRegistration -Owner "Elliot Huffman"
        Sets the owner registration for the local system to "Elliot Huffman".
        To validate that registration was set, check "Winver.exe" "licensed to" field.
    .EXAMPLE
        PS C:\> Set-NTRegistration -Organization "Elliot Labs LLC"
        Sets the organization registration for the local system to "Elliot Labs LLC".
        To validate that registration was set, check "Winver.exe" "licensed to" field.
    .EXAMPLE
        PS C:\> Set-NTRegistration -Clear -ComputerName "Test-DC","Test-Admin"
        Clears the registration data of the Windows Operating system.
        This operates on the remote computers, "Test-Admin" and "Test-DC".
        This uses the WS-MAN protocol, which requires Powershell to be installed on the target.
        The registered field will be blank.
        To validate that registration was cleared, check "Winver.exe" "licensed to" field on each target.
    .EXAMPLE
        PS C:\> Set-NTRegistration -Owner "Elliot Huffman" -ComputerName "Test-DC","Test-Admin"
        Sets the owner registration for the local system to "Elliot Huffman".
        This operates on the remote computers, "Test-Admin" and "Test-DC".
        This uses the WS-MAN protocol, which requires Powershell to be installed on the target.
        To validate that registration was cleared, check "Winver.exe" "licensed to" field on each target.
    .EXAMPLE
        PS C:\> Set-NTRegistration -Organization "Elliot Labs LLC" -ComputerName "Test-DC","Test-Admin"
        Sets the organization registration for the local system to "Elliot Labs LLC".
        This operates on the remote computers, "Test-Admin" and "Test-DC".
        This uses the WS-MAN protocol, which requires Powershell to be installed on the target.
        To validate that registration was cleared, check "Winver.exe" "licensed to" field on each target.
    .INPUTS
        Switch
        System.String
        System.String[]
    .OUTPUTS
        Void
    .LINK
        https://github.com/elliot-labs/PowerShell-Doodads
    .NOTES
        Requirements:
            Rights to edit the HKEY_Local_Machine registry hive; This is usually administrator rights.
            This applies to both local and remote targets.
    #>

    #Requires -RunAsAdministrator

    # Cmdlet bind the script to enable advanced functions
    # Set ShouldProcess to $true to enable the capability to use -WhatIf and -Confirm
    [CmdletBinding(
        SupportsShouldProcess=$true,
        DefaultParameterSetName='Clear'
    )]

    Param (
        # Create the Clear parameter and set metadata
        # It is its own param set and should not be used with any other param combos
        [Parameter(
            Mandatory=$true,
            ParameterSetName="Clear"
        )]
        [Switch]$Clear,

        # Create the Owner parameter and set metadata
        [Parameter(
            Mandatory=$false,
            Position=0,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName='Set-Data'
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]$Owner,

        # Create the Organization parameter and set metadata
        [Parameter(
            Mandatory=$false,
            Position=1,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName='Set-Data'
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]$Organization,

        # Validate that the computer(s) is/are accessible
        [ValidateScript({Test-Connection -ComputerName $_ -Quiet})]
        # Ensure that the data is not empty
        [ValidateNotNullOrEmpty()]
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [System.String[]]$ComputerName
    )

    # Run the begin block once for init
    begin {
        # Create the script block for remote execution, this stores the code to be executed remotely
        $ScriptBlock = {
            # Accept parameter values
            param(
                # Only two different strings are allowed for the name parameter
                [ValidateSet("RegisteredOwner", "RegisteredOrganization")]
                [System.String]$Name,
                # The value can have anything, as long as it is a string, if value is specified, it cannot be empty
                [System.String]$Value = ""
            )

            # Set the registry value for the system registration information
            Set-ItemProperty -Name $Name -Value $Value -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\"            
        }
    }

    # Run the end block once after pipeline completes
    end {
        # Create the dynamic parameters HashTable for the owner registration
        $OwnerParams = @{
            # The scriptblock property is used to store the script block that will be executed remotely
            ScriptBlock = $ScriptBlock
        }

        # Create the dynamic parameters HashTable for the organization registration
        $OrganizationParams = @{
            # The scriptblock property is used to store the script block that will be executed remotely
            ScriptBlock = $ScriptBlock
        }

        # Create the dynamic parameters HashTable for the organization registration
        $ClearParams = @{
            # The scriptblock property is used to store the script block that will be executed remotely
            ScriptBlock = $ScriptBlock
        }

        # If the script is to execute remotely, set up the computer name parameter
        if ($ComputerName.Count -gt 0) {
            # If there are remote computers, add them to the computer name property of the HashTables
            $OwnerParams.ComputerName = $ComputerName
            $OrganizationParams.ComputerName = $ComputerName
            $ClearParams.ComputerName = $ComputerName
        }

        # If the owner parameter is specified, build the params
        if ($Owner) {
            # Add the registered owner string to the param list in array form
            $OwnerParams.ArgumentList = @("RegisteredOwner")

            # Add the owner registration value to the list of arguments for the script block
            $OwnerParams.ArgumentList += $Owner

            # implement -WhatIf and -Confirm support (Should process)s
            if ($PSCmdlet.ShouldProcess("Registry", "Change owner")) {
                # Parameter splat (use @ instead of $ for HashTable) the cmdlet with dynamically built parameters
                Invoke-Command @OwnerParams
            }
        }

        # Check to see if the Organization parameter is specified
        if ($Organization) {
            # Add the registered organization string to the param list in array form
            $OrganizationParams.ArgumentList = @("RegisteredOrganization")

            # Add the organization registration value to the list of arguments for the script block
            $OrganizationParams.ArgumentList += $Organization

            # implement -WhatIf and -Confirm support (Should process)
            if ($PSCmdlet.ShouldProcess("Registry", "Change organization")) {
                # Parameter splat (use @ instead of $ for HashTable) the cmdlet with dynamically built parameters
                Invoke-Command @OrganizationParams
            }
        # If the clear parameter is specified, remove the registration.
        # Only if the Organization and Owner parameters are not specified, the organization check is implied via elseif
        } elseif ($Clear -and (-not $Owner)) {
            # implement -WhatIf and -Confirm support (Should process)
            if ($PSCmdlet.ShouldProcess("Registry", "Clear Owner Registration")) {
                # Set the clear parameters to Owner mode
                $ClearParams.ArgumentList = "RegisteredOwner"

                # Execute the clear command against owner
                Invoke-Command @ClearParams
            }
            # implement -WhatIf and -Confirm support (Should process)
            if ($PSCmdlet.ShouldProcess("Registry", "Clear Organization Registration")) {
                # Set the clear parameters to Owner mode
                $ClearParams.ArgumentList = "RegisteredOrganization"

                # Execute the clear command against organization
                Invoke-Command @ClearParams
            }            
        }
    }
}

# Execute script as standalone if not dot-sourced
if ($MyInvocation.Line -NotMatch "^\.\s") {
    # Param splat the parameters
    Set-NTRegistration @PSBoundParameters
}