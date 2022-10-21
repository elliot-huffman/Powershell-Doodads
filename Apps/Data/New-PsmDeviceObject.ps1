<#
.SYNOPSIS
    Generate mock data for dev environments
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.PARAMETER PsmDevice
    Generates PSM managed device objects. These objects are what are returned when requesting a list of devices from the REST API.
.PARAMETER AutopilotDevice
    Generates the list of autopilot devices form the MS Graph API through the PSM server's rest API.
.PARAMETER Count
    Number of mock devices to generate.
.PARAMETER Path
    Directory to output the JSON file.
.LINK
    https://mootinc.com
#>

param(
    [Parameter(
        ParameterSetName = 'PsmDevice',
        Mandatory = $true
    )]
    [switch]$PsmDevice,
    [Parameter(
        ParameterSetName = 'Autopilot',
        Mandatory = $true
    )]
    [switch]$AutopilotDevice,
    [int64]$Count = 50,
    [System.String]$Path = '.\DeviceObjectList.json'
)

begin {
    function New-PsmDevice {
        $DeviceObject = @{
            'id'               = [guid]::NewGuid();
            'DisplayName'      = "PAW - $(Get-Random)"
            'ParentGroup'      = [guid]::NewGuid();
            'CommissionedDate' = (Get-Date -Year 2021 -Day (Get-Random -Maximum 29 -Minimum 1) -Month (Get-Random -Minimum 1 -Maximum 12)).ToString('yyyy-MM-ddTHH:mm:ss.fffZ');
            'GroupAssignment'  = [guid]::NewGuid();
            'UserAssignment'   = [guid]::NewGuid();
            
        }
        if ((Get-Random -Minimum 0 -Maximum 11) -ge 5) {
            $DeviceObject.ParentDevice = [guid]::NewGuid();
        }
        switch (Get-Random -Maximum 4 -Minimum 1) {
            1 { $DeviceObject.Type = 'Privileged' }
            2 { $DeviceObject.Type = 'Developer' }
            3 { $DeviceObject.Type = 'Tactical' }
        }
        return $DeviceObject
    }
    
    function New-PsmAutopilotDevice {
        # Generate a unique GUID for the AAD Device ID Fields
        $AADDeviceID = [guid]::NewGuid()

        # Create the base object structure for the Autopilot Device Object
        $DeviceObject = @{
            'azureActiveDirectoryDeviceId' = $AADDeviceID;
            'azureAdDeviceId'              = $AADDeviceID;
            'serialNumber'                 = -join ((97..122) | Get-Random -Count (Get-Random -Maximum 11 -Minimum 5) | ForEach-Object -Process { [char]$_ });
        }

        # Randomly assign a computer name to the device.
        # Devices may or may not have a computer name assigned.
        if ((Get-Random -Minimum 0 -Maximum 11) -ge 5) {
            $DeviceObject.displayName = 'Desktop-' + -join ((97..122) | Get-Random -Count 7 | ForEach-Object -Process { [char]$_ });
        }

        # Return the generated device object to the caller
        return $DeviceObject
    }
}

process {
    $DeviceArray = 1..$Count | ForEach-Object -Process {
        if ($PsmDevice) {
            New-PsmDevice
        }
        elseif ($AutopilotDevice) {
            New-PsmAutopilotDevice
        }
        else {
            Write-Error -Message 'Mandatory switch parameter not found at generation time!'
        }
    }
    $DeviceArray | ConvertTo-Json | Out-File -FilePath $Path
}
