<#
.SYNOPSIS
    Installs the Non-Priv VM on the PAW.
.DESCRIPTION
    Expands the accompanying/specified ZIP file, and imports the VM into Hyper-V.
    Also places an uninstall script in program data for Endpoint Manager to be able to issue an uninstall command.
.EXAMPLE
    PS C:\> Install-NonPrivVM.ps1
    Installs the VM that is contained in the ZIP file.
.EXAMPLE
    PS C:\> Install-NonPrivVM.ps1 -ZipName "Enterprise VM"
    Installs the specified VM with the zip file named "Enterprise VM.zip".
.PARAMETER ZipName
    The name of the Zip file to be extracted.
    This zip file needs to contain the VM's files
    This will be the name of the zip file as well as the folder in the zip file that contains the machine configs, VHDs, and snapshots.
.INPUTS
    System.String
.OUTPUTS
    Void
.NOTES
    Requires the Hyper-V PS module present
#>

#Requires -Module Hyper-V

[CmdletBinding(SupportsShouldProcess=$true)]

param(
    [ValidateScript({Test-Path -Path ".\$_.zip" -PathType "Leaf"})]
    [System.String]$ZipName = "Enterprise"
)

# Extract the Archive to the local folder to prep for install.
Expand-Archive -Path ".\$ZipName.zip" -DestinationPath ".\"

# Ensure that the specified path exists before executing the import command
if (Test-Path -Path ".\$ZipName\" -PathType "Container") {
    # Import the VM and files to the local hyper-v instance while generating a new unique ID
    Import-VM -Path ".\$ZipName\" -Copy -GenerateNewId
} else {
    # Throw an error stating that the stuff isn't there
    Write-Error -Message "The specified path does not exist during import, ensure that the VM name and the folder in the zip are of the same name."
}

# Ensure that the path is present before placing the uninstall script
if (-not (Test-Path -Path "C:\ProgramData\PSDoodads\NonPrivVM\" -PathType "Container")) {
    # Create the folder if it doesn't exist.
    New-Item -Path "C:\ProgramData\PSDoodads\NonPrivVM\" -ItemType "Directory"
}

# Place the uninstaller in a centrally available location
Copy-Item -Path ".\Uninstall-NonPrivVM.ps1" -Destination "C:\ProgramData\PSDoodads\NonPrivVM\"