<#
.SYNOPSIS
    Placeholder
.DESCRIPTION
    Placeholder
.PARAMETER PingDestination
    Placeholder
.PARAMETER OutputFile
    Placeholder
.PARAMETER LoopRounds
    Placeholder
.EXAMPLE
    Placeholder
.EXAMPLE
    Placeholder
.LINK
    https://github.com/elliot-labs/PowerShell-Doodads
.NOTES
    Placeholder
#>

# Allow command line automation.
param(
    [string]$PingDestination = "bing.com",
    [string]$OutputFile = "Internet Stress Test.log",
    [int]$LoopRounds = 0
)

# Set the loop counter to 0.
$loop_counter = 0

# Loop the same code untill the loop counter hist the specified rounds.
while ($loop_counter -lt $LoopRounds) {
    # Ping the specified server and write the results to a file.
    Test-Connection $PingDestination | Out-File $OutputFile -Append
    # Add one to the loop counter.
    $loop_counter ++
    # Write to the command line and pipe to an external file specified by the parameter.
    Write-Host "Number of ping batches: $loop_counter" | Out-File $OutputFile -Append
    # Stop processing script for 60 seconds.
    Start-Sleep -Seconds 60
}
