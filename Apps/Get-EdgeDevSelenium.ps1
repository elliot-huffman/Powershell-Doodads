#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess=$true)]
[OutputType([Void])]
param(
    [System.String]$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe",
    [System.String]$SeleniumDirectory = "C:\EdgeSelenium"
)

# Check to see if Microsoft Edge is installed
if (-not (Test-Path -Path $RegistryPath)) {
    # Write an error if Edge was not found
    Write-Error -Message "Microsoft Edge Chrome needs to be installed to run this script!"
    
    # Exit the script and set a return code
    exit 1
}

# Get the currently installed version of MS Edge Chrome
$EdgeVersion = (Get-Item (Get-ItemProperty $RegistryPath).'(Default)').VersionInfo.ProductVersion

# Check the CPU architecture to see if it is supported
switch ($env:PROCESSOR_ARCHITECTURE) {
    "AMD64" { $CPUArch = 64; break }
    "x86" { $CPUArch = 32; break }
    Default {
        Write-Error -Message "CPU not supported"
        exit 2
    }
}

# Grab the edge chrome web driver executable
if ( -not (Test-Path -Path $SeleniumDirectory)) {
    New-Item -Path $SeleniumDirectory -ItemType "Directory"

    # Execute commands relative to the Edge folder that was just created
    Set-Location -Path $SeleniumDirectory

    # Download the correct version of the web driver based upon the currently installed version of EdgeDev
    # Download the latest version of NuGet
    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -Uri "https://msedgedriver.azureedge.net/$EdgeVersion/edgedriver_win$CPUArch.zip" -OutFile "WebDriver.zip"
    Invoke-WebRequest "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile .\NuGet.exe
    $ProgressPreference = "Continue"

    # Load the file compression lib
    Add-Type -AssemblyName "System.IO.Compression.FileSystem"

    $CurrentDir = Resolve-Path -Path ".\"
    # Extract the downloaded zip file to the current directory
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$CurrentDir\WebDriver.zip", "$CurrentDir\")

    # Clean up after extraction
    Remove-Item -Path ".\WebDriver.zip"

    # Rename the driver to the one selenium is expecting
    Rename-Item -Path ".\msedgedriver.exe" -NewName "chromedriver.exe"

    # Install selenium lib
    .\NuGet.exe --% install Selenium.WebDriver

} else {
    # Execute commands relative to the edge folder (should already exist with the edge web driver renamed to chromedriver.exe)
    Set-Location -Path $SeleniumDirectory
}
# Web driver needs to be on the system path
$env:Path += ";$SeleniumDirectory"

# Edge binary needs to be on the system path
$env:Path += ";$(((Get-ItemProperty $RegistryPath).'(Default)' | Split-Path -Parent) + `"\`")"

# import the selenium lib
Add-Type -Path ".\Selenium.WebDriver.3.141.0\lib\net45\WebDriver.dll"

# Instantiate a web driver instance
$Driver = [OpenQA.Selenium.Chrome.ChromeDriver]::new()

# Navigate to awesomeness
$Driver.Navigate().GoToUrl("https://github.com/elliot-labs/PowerShell-Doodads")

# Prevent instant browser close after navigation
Read-Host -Prompt "Press enter to continue" | Out-Null

# Close the web browser
$Driver.Close()

# Close the driver session to allow for a clean exit instead of a hang on script completion
$Driver.Dispose()