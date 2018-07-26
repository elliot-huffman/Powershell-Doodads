# Gitlab file URLs
$InitialScript = "https://raw.githubusercontent.com/elliot-labs/Powershell-Doodads/master/Apps/Technet-vLabs/Set-LabEnv.ps1"
$PostRestartScript = "https://raw.githubusercontent.com/elliot-labs/Powershell-Doodads/master/Apps/Technet-vLabs/Set-PostReboot.ps1"

# Download the script files.
Invoke-WebRequest -Uri $InitialScript -OutFile $env:TEMP\Set-LabEnv.ps1
Invoke-WebRequest -Uri $PostRestartScript -OutFile $env:TEMP\Set-PostReboot.ps1

# Set the location for script execution
Set-Location $env:TEMP

# Start the initial Script.
.\Set-LabEnv.ps1

# Prep post restart script to run after reboot.
    # Placeholder
