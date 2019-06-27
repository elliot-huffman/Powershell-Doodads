#Requires -RunAsAdministrator

# Check to see if microsoft edge is installed
if (!(Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe")) {
    Write-Error -Message "Microsoft Edge Dev needs to be installed to run this script!"
    exit
}

# Currently installed version of MS Edge Dev
$EdgeVersion = (Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe').'(Default)').VersionInfo.ProductVersion

# Check the CPU to see if ti si supported
if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
    $CPUArch = 64
} elseif ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
    $CPUArch = 32
} else {
    Write-Error -Message "CPU not supported"
    exit
}

# Grab the edge dev web driver executable
if (!(Test-Path -Path "C:\Edge")) {
    New-Item -Path "C:\Edge" -ItemType Directory

    # Execute commands relative to the edge folder (should already exist with the edge web driver renamed to chromedriver.exe)
    Set-Location -Path C:\Edge

    # Download the correct version of the web driver based upon the currently installed version of EdgeDev
    # Download the latest version of NuGet
    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -Uri "https://msedgedriver.azureedge.net/$EdgeVersion/edgedriver_win$CPUArch.zip" -OutFile "WebDriver.zip"
    Invoke-WebRequest "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile .\NuGet.exe
    $ProgressPreference = "Continue"

    # Load teh file compression lib
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $CurrentDir = Resolve-Path -Path .\
    # Extract the downloaded zip file to the current directory
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$CurrentDir\WebDriver.zip", "$CurrentDir\")

    # Clean up after extraction
    Remove-Item -Path .\WebDriver.zip

    # Rename the driver to the one selenium is expecting
    Rename-Item -Path .\msedgedriver.exe -NewName chromedriver.exe

    # Install selenium lib
    .\NuGet.exe install Selenium.WebDriver

} else {
    # Execute commands relative to the edge folder (should already exist with the edge web driver renamed to chromedriver.exe)
    Set-Location -Path C:\Edge
}
# Web driver needs to be on the system path
$env:Path += ";C:\Edge\"

# Edge binary needs to be on the system path
$env:Path += ";C:\Program Files (x86)\Microsoft\Edge Dev\Application"

# import the selenium lib
Add-Type -Path .\Selenium.WebDriver.3.141.0\lib\net45\WebDriver.dll

# Instantiate a web driver instance
$Driver = [OpenQA.Selenium.Chrome.ChromeDriver]::new()

# Navigate to awesomeness
$Driver.Navigate().GoToUrl("https://github.com/elliot-labs")

# Prevent instant browser close after navigation
Read-Host -Prompt "Press enter to continue" | Out-Null

# close the web browser
$Driver.Close()

# Close the driver session to allow for a clean exit instead of a hang on script completion
$Driver.Dispose()