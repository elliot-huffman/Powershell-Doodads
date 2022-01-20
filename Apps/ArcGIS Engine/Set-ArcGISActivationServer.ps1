#Requires -RunAsAdministrator

# Cmdlet bind the script to support command simulation
[CmdletBinding(SupportsShouldProcess=$true)]

param(
    [System.String]$ComputerName = "S-911cad01.nc-cherokee.com",
    [System.String]$EngineVersion = "10.8"
);

# Set the registery location that the license server key is located
$RegLocation = "HKLM:\SOFTWARE\WOW6432Node\ESRI\License$EngineVersion\"

# Check to make sure that the path exists
if (-not (Test-Path -Path $RegLocation -PathType "Container")) {
    # If a simulation is requested, simulate the command
    if ($PSCmdlet.ShouldProcess("Registry", "Create License Key")) {
        # Create the required key incase it doesn't exist
        New-Item -Path $RegLocation   
    }
}

# If a simulation is requested, simulate the command
if ($PSCmdlet.ShouldProcess("LICENSE_SERVER Property", "Set value")) {
    # Set the license server value for the ArcGIS License Manager
    Set-ItemProperty -Path $RegLocation -Name "LICENSE_SERVER" -value $ComputerName
}