<#
.SYNOPSIS
    Generate mock data for dev environments
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.PARAMETER MsmDevice
    Generates MSM managed device objects. These objects are what are returned when requesting a list of devices from the REST API.
.PARAMETER AutopilotDevice
    Generates the list of autopilot devices form the MS Graph API through the MSM server's rest API.
.PARAMETER Count
    Number of mock devices to generate.
.PARAMETER Path
    Directory to output the JSON file.
.LINK
    https://mootinc.com
#>

param(
    [Parameter(ParameterSetName = 'Unmanaged')]
    [switch]$Unmanaged,
    [int64]$Count = 50,
    [System.String]$Path = '.\DeviceObjectList.json'
)

begin {
    function New-MsmDevice {
        # Array that contains a list of names to prefix the device name with
        [System.String[]]$NamePrefixList = 'Ops', 'Fin', 'IT', 'Exec', 'Mgmt', 'HR', 'Mkt', 'Sale', 'RD'

        # Create the base structure of the simulated device object
        $DeviceObject = @{
            'DisplayName' = "$(Get-Random -InputObject $NamePrefixList)-$(Get-Random -Maximum 999999)"
            'Id'          = (New-Guid).Guid
        }

        # Check if unmanaged devices are requested
        if ($Unmanaged) {
            # Set the device type to unmanaged
            $DeviceObject.Type = 'Unmanaged'

            # Set the null UUID as the unique group if it is unmanned. Since it is unmanned, it will not have a unique group.
            $DeviceObject.UniqueGroup = '00000000-0000-0000-0000-000000000000'

            # Set the device object to a the beginning of epoch time
            $DeviceObject.CommissionedDate = (Get-Date -Year 1970 -Day 1 -Month 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')

        } else {
            # Generate a 50/50 (coin flip) scenario that determines if the device has a parent device
            if ((Get-Random -Minimum 0 -Maximum 11) -ge 5) {
                # Add a parent device ID to the managed device object
                $DeviceObject.ParentDevice = (New-Guid).Guid
            }

            # Set the null UUID as the unique group if it is unmanned. Since it is unmanned, it will not have a unique group.
            $DeviceObject.UniqueGroup = (New-Guid).Guid

            # Set the device object to a random commission date
            $DeviceObject.CommissionedDate = (Get-Date -Year 2023 -Day (Get-Random -Maximum 29 -Minimum 1) -Month (Get-Random -Minimum 1 -Maximum 12)).ToString('yyyy-MM-ddTHH:mm:ss.fffZ') 

            # Randomly select a management type for the managed device
            switch (Get-Random -Maximum 4 -Minimum 1) {
                1 { $DeviceObject.Type = 'Privileged' }
                2 { $DeviceObject.Type = 'Specialized' }
                3 { $DeviceObject.Type = 'Enterprise' }
            }

            # Operate only if the device is a privileged device
            if ($DeviceObject.Type -eq 'Privileged') {
                $DeviceObject.DisplayName = 'Priv-' + $DeviceObject.DisplayName

                # Set the group and user assignments
                $DeviceObject.GroupAssignment = (New-Guid).Guid
                $DeviceObject.UserAssignment = (New-Guid).Guid  
            }
        }

        # Return the computed sample device object
        return $DeviceObject
    }
}

process {
    # Iterate the requested number of times to generate the requested number of devices
    $DeviceArray = 1..$Count | ForEach-Object -Process { New-MsmDevice }
    
    # Save the data to disk from memory
    $DeviceArray | ConvertTo-Json | Out-File -FilePath $Path
}
