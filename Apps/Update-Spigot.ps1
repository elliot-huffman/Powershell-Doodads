param([string]$Verbosity="Normal", [string]$WindowName = "Spigot Server", [string]$ServerDir = "C:\Some\Path\", [string]$ServerStartScript = "Start Server.bat", [string]$BuildDir = "C:/Some/Other/Path/", [string]$BuildVersion = "latest", [string]$GitBashLocation = "C:\Program Files\Git\bin\bash.exe")

# Acceptable Verbosity levels are:
# Debug (for the logging of everything)
# Normal (for standard operation, errors and finish only logged) - default
# None (for completely silent operation, no log file)


# Variables
# $WindowName = "Spigot Server" # Name of process to stop gracefully
# $ServerDir = "C:\Some\Path\" # Directory where your Spigot installation is located
# $ServerStartScript = "Start Server.bat" # Name of the script that starts the Spigot server. Needs to be in same dir as the spigot executable.
# $BuildDir = "C:/Some/Other/Path/" # Directory where the BuildTools.jar will be downloaded and executed. Path needs to use unix style dir slashes for the build tools execution to work.
# USE A UNIX STYLE PATH FOR BUILD DIR!!!!!!!!!!!!
# $BuildVersion = "latest" # Accepts MC version flags defined here: https://www.spigotmc.org/wiki/buildtools/#versions
# $GitBashLocation = "C:\Program Files\Git\bin\bash.exe" # Path to your local msysgit installation's bash exe.

$wshell = New-Object -ComObject wscript.shell; # Imports the wscript, shell library.


Add-Type -AssemblyName System.Windows.Forms


Function Get-Prerequisites {
    If (Test-CommandExists ("java.exe")) {
        If ($Verbosity -eq "Debug") {
            $TimeStamp = Get-Date
            "At $TimeStamp Found Java." | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
        }
    }
    Else {
        If ($Verbosity -eq "Normal" -or $Verbosity -eq "Debug"){
            $TimeStamp = Get-Date
            "At $TimeStamp Unable to find Java." | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
        }
        Exit-Script -ErrorsOnFinish
    }
    If (Test-Path $GitBashLocation) {
        If ($Verbosity -eq "Debug") {
            $TimeStamp = Get-Date
            "At $TimeStamp Found Git Bash." | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
        }
    }
    Else {
        If ($Verbosity -eq "Normal" -or $Verbosity -eq "Debug"){
            $TimeStamp = Get-Date
            "At $TimeStamp Unable to find Git Bash." | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
        }
        Exit-Script -ErrorsOnFinish
    }
    $JavaArchTest = java -d64 -version 2>&1
    If ($JavaArchTest -like "Error: *"){
        $Script:JavaArch = " -d32"
    }
    else {
        $Script:JavaArch = " -d64"
    }
}

Function Test-CommandExists ($command) {
    Try {If(Get-Command $command -ErrorAction stop){RETURN $true}}
    Catch {Write-Host “$command does not exist”; RETURN $false}
    # Adapted and optimized from https://blogs.technet.microsoft.com/heyscriptingguy/2013/02/19/use-a-powershell-function-to-see-If-a-command-exists/
}

Function Get-PIdByWindowTitle ($WindowTitle) {
    $ProcessID = Get-Process | Where-Object {$_.MainWindowTitle -eq $WindowTitle}
    Return $ProcessID.Id
}

Function Get-BuildTools {
    Remove-Item -Path $BuildDir\* -Recurse -Force
    Try {
        # Download the lastSuccessfulBuild of BuildTools
        Invoke-WebRequest https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar -OutFile "$BuildDir\BuildTools.jar" -ErrorAction Stop
        If ($Verbosity -eq "Debug") {
            $TimeStamp = Get-Date
            "At $TimeStamp Download of build tools succeeded" | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
        }
    }
    Catch [System.Exception] {
        write-host "Could not download the latest build tools"
        If ($Verbosity -eq "Normal" -or $Verbosity -eq "Debug"){
            $TimeStamp = Get-Date
            "At $TimeStamp Download of build tools failed" | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
        }
        Exit-Script -ErrorsOnFinish
    } 
}

Function New-SpigotServer {
    cd $BuildDir
    & $GitBashLocation "--login", "-i", "-c", "java$Script:JavaArch -jar `"$BuildDir/BuildTools.jar`" --rev $BuildVersion" | Out-Null # Creates a lot of noise otherwise...
    $BuildSuccessfulCheck = Test-Path "$BuildDir\spigot-*.jar"
    If ($BuildSuccessfulCheck -eq $True) {
        If ($Verbosity -eq "Debug") {
            $TimeStamp = Get-Date
            "At $TimeStamp Spigot server build succeeded." | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
        }
    }
    else {
        Write-Host "Failed to build new version of Spigot server."
        If ($Verbosity -eq "Normal" -or $Verbosity -eq "Debug"){
            $TimeStamp = Get-Date
            "At $TimeStamp Spigot server build was unsuccessful." | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
        }
        Exit-Script -ErrorsOnFinish
    }
}

Function Stop-SpigotServer {
    $wshell.AppActivate($WindowName) | Out-Null # This command seems to output false every time it runs correctly or not, so it was muted.
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait('~stop~');
    Wait-Process -Id (Get-PIdByWindowTitle ($WindowName))
}

Function Update-ServerExecutable {
    $ServerExists = Test-Path "$ServerDir\spigot-*.jar"
    If ($ServerExists -eq "True") {
        Try {
            Remove-Item $ServerDir\spigot-*.jar
            If ($Verbosity -eq "Debug") {
                $TimeStamp = Get-Date
                "At $TimeStamp Removed old Spigot server executable successfully." | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
            }
        }
        Catch [System.Exception] {
            If ($Verbosity -eq "Normal" -or $Verbosity -eq "Debug"){
                $TimeStamp = Get-Date
                "At $TimeStamp Failed to remove old server executable." | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
            }
            Exit-Script -ErrorsOnFinish
        }
    }
    Try {
        Move-Item $BuildDir\Spigot-*.jar $ServerDir -ErrorAction Stop
        If ($Verbosity -eq "Debug") {
            $TimeStamp = Get-Date
            "At $TimeStamp Moved new server executable successfully into position." | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
        }
    }
    Catch [System.Exception] {
        Write-Host "Failed to move new server executable to specified server directory."
        If ($Verbosity -eq "Normal" -or $Verbosity -eq "Debug"){
            $TimeStamp = Get-Date
            "At $TimeStamp Failed to move new server executable into position." | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
        }
        Exit-Script -ErrorsOnFinish
    }
}

Function Start-Server {
    Try {
        Start-Process "$ServerDir\$ServerStartScript"
        If ($Verbosity -eq "Debug") {
            $TimeStamp = Get-Date
            "At $TimeStamp Server start succeeded." | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
        }
    }
    Catch [System.Exception] {
        Write-Host "Server failed to start."
        If ($Verbosity -eq "Normal" -or $Verbosity -eq "Debug"){
            $TimeStamp = Get-Date
            "At $TimeStamp Start of server failed." | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
        }
        Exit-Script -ErrorsOnFinish
    }
}

Function Exit-Script ([Switch]$ErrorsOnFinish) {
    If ($ErrorsOnFinish) {
        If ($Verbosity -eq "Normal" -or $Verbosity -eq "Debug"){
            $TimeStamp = Get-Date
            "At $TimeStamp Variable dump:" | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
            '$WindowName = ' + $WindowName | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
            '$ServerDir = ' + $ServerDir | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
            '$BuildDir = ' + $BuildDir | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
            '$BuildVersion = ' + $BuildVersion | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
            '$GitBashLocation = ' + $GitBashLocation | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
            $TimeStamp = Get-Date
            "At $TimeStamp The script finished unsuccessfully." | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
            Write-Host "At $TimeStamp The script finished unsuccessfully."
        }
    }
    ElseIf (-Not $ErrorsOnFinish) {
        If ($Verbosity -eq "Normal" -or $Verbosity -eq "Debug"){
            $TimeStamp = Get-Date
            "At $TimeStamp The script finished successfully." | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
            Write-Host "At $TimeStamp The script finished successfully."
        }
    }
    Else {
       If ($Verbosity -eq "Normal" -or $Verbosity -eq "Debug"){
            $TimeStamp = Get-Date
            "At $TimeStamp The script finished in an unknown state." | Out-File -FilePath "$ServerDir\Auto-Update.log" -Append
            Write-Host "At $TimeStamp The script finished with an unknown state."
        }
    }
    Exit
}


Write-Progress -Activity "Update Progress" -Status "Checking that prerequisites exist" -PercentComplete (0)
Get-Prerequisites
Write-Progress -Activity "Update Progress" -Status "Downloading BuildTools.jar" -PercentComplete (10)
Get-BuildTools
Write-Progress -Activity "Update Progress" -Status "Compiling new Spigot Server version" -PercentComplete (20)
New-SpigotServer
Write-Progress -Activity "Update Progress" -Status "Stopping current Spigot Server" -PercentComplete (70)
Stop-SpigotServer
Write-Progress -Activity "Update Progress" -Status "Moving new Spigot server executable into place." -PercentComplete (80)
Update-ServerExecutable
Write-Progress -Activity "Update Progress" -Status "Starting new spigot server." -PercentComplete (90)
Start-Server
Write-Progress -Activity "Update Progress" -Status "Finished!" -PercentComplete (100)
Exit-Script
