#Requires -Module WindowsAutoPilotIntune
#Requires -Module Microsoft.Graph.Intune

[CmdletBinding(SupportsShouldProcess = $true)]

param(
    [ValidateScript({
            Test-Path -Path $_ -PathType "Leaf"
        })]
    [ValidateNotNullOrEmpty()]
    [System.String[]]$AutopilotCSV = ".\"
)

# Log into Autopilot, this requires human interaction
Connect-MSGraph

# Initialize variables
$HashList = @()
$AutopilotDeviceList = @()

# Merge all hash lists together as a single list to process for all old and new hashes
foreach ($CSVPath in $AutopilotCSV) { $HashList += Import-Csv -Path $CSVPath }

# Iterate through the list of device hashes to create a list of autopilot devices to remove
foreach ($Hash in $HashList) {
    # Compile a list of devices to iterate over
    $AutopilotDeviceList += Get-AutopilotDevice -serial $Hash."Device Serial Number"
}

# Remove each specified device
foreach ($Device in $AutopilotDeviceList) {
    # Support action simulation
    if ($PSCmdlet.ShouldProcess("Autopilot", "Remove ${$Device.serialNumber}")) {
        # Remove the devices from Endpoint Manager's Autopilot
        Remove-AutopilotDevice -id $Device.id -serialNumber $Device.serialNumber   
    }
}