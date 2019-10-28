<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.PARAMETER Owner
    Blah
.PARAMETER Organization
    Blah
.PARAMETER Clear
    Blah
.PARAMETER ComputerName
    Blah
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    General notes
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
        Short description
    .DESCRIPTION
        Long description
    .EXAMPLE
        PS C:\> <example usage>
        Explanation of what the example does
    .INPUTS
        Inputs (if any)
    .OUTPUTS
        Output (if any)
    .NOTES
        General notes
    #>
    #Requires -RunAsAdministrator
    [CmdletBinding(
        SupportsShouldProcess=$true,
        DefaultParameterSetName='Clear'
    )]
    Param (
        [Parameter(
            Mandatory=$true,
            ParameterSetName="Clear"
        )]
        [Switch]$Clear,

        [Parameter(
            Mandatory=$false,
            Position=0,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName='Set-Data'
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]$Owner,

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

            # Enable -WhatIf and -Confirm support
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

            # Enable -WhatIf and -Confirm support
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