<#
.SYNOPSIS
This script converts powershell scripts to batch scripts to execute directly on systems.
.DESCRIPTION
This script takes the input powershell script and exports it as a batch script that can be directly run on the system.
This script can be run on the CLI mode or as a GUI mode.
.PARAMETER CLIMode
When set to true the GUI will not be displayed and the other CLI arguments will be used for the required information.
.PARAMETER InputFile
The path to the file that will be used as the source for the outputted batch script.
.PARAMETER OutputFile
The destination and file name that will be used when the source file has finished processing.
.EXAMPLE
Convert-PowershellToBatch.ps1 -CLIMode true -InputFile "C:\Show-AgentToolkit.ps1" -OutputFile "C:\AgentTools.bat"
This will disable GUI mode and take the inputted file and export it as a batch script.
.EXAMPLE
Convert-PowershellToBatch.ps1
This will run the converter in full GUI mode.
.NOTES
This tool is not needed for general use and should only be used when you know you need to change a powershell file into a self contained batch script.
.LINK
https://elliot-labs.com
#>

# Add command line switch/flag support
# Legacy visuals are for people who like the old visual styles.
# by using the switch, the variable becomes true, bypassing the enable modern visuals step.
# CLIMode is used for people who like to use CLI to do everything.
# InputFile is the path to the PowerShell file that needs converted to a batch file.
# OutputFile is the path to the file that will be created after the powershell file has finished processing.
param([switch]$LegacyVisuals = $false, [switch]$CLIMode = $false, [switch]$AdminMode = $false, [string]$InputFile="C:\temp\test.ps1", [string]$OutputFile="C:\temp\test.bat")

# Import required libraries
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Enable pretty interface controls (by default)
# Windows 98 styles are ugly compared to today's standards
if (!$LegacyVisuals) {
    [System.Windows.Forms.Application]::EnableVisualStyles()
}

# Command Line interface mode logic starts here.
Function Convert-File ($InputFile, $OutputFile, [string]$CLIArgument="", $AdminModeRadio=$false, $DisplayTerminal=$false) {
    if (($AdminMode) -or ($AdminModeRadio)) {
        $AdminSubHeader = 'net session >nul 2>&1
if NOT %errorLevel% == 0 (
    echo Please run this script as an administrator.
    pause
    exit
)'
    } else {
        $AdminSubHeader = ''
    }
    if ($DisplayTerminal) {
        $DisplayTerminalCLI = ' -WindowStyle Hidden'
    }
    # Code that will be added to the top of the converted script.
    $BatchHeader = "@echo off
color 0A
cls
cd /d %~dp0
set Script=`"%RANDOM%-%RANDOM%-%RANDOM%-%RANDOM%.ps1`"
$($AdminSubHeader)
("

    # Code that will be added at the bottom of the converted script.
    $BatchFooter = ") > %script%
powershell -ExecutionPolicy Unrestricted$DisplayTerminalCLI -File %Script% $CLIArgument
del %script%"

    # Code that will be added
    $AdminSubHeader = ':CheckAdmin
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Success: Administrative permissions confirmed.
) else (
    echo Please run script as administrator.
    pause
    exit
)
'

    # Create the top of the outputted script.
    $BatchHeader | Out-File -FilePath $OutputFile -Encoding ASCII
    
    # Open the script to be converted and run a sequence of commands upon each line in order from top to bottom.
    Get-Content -Path $InputFile | ForEach-Object {

        # Automatically comments out pipe characters in the current line.
        $fileLine = $_ -replace "\^", "^^"
        $fileLine = $fileLine -replace "\|", "^|"
        $fileLine = $fileLine -replace ">", "^>"
        $fileLine = $fileLine -replace "<", "^<"
        $fileLine = $fileLine -replace "%", "%%"
        $fileLine = $fileLine -replace "&", "^&"
        $fileLine = $fileLine -replace "\(", "^("
        $fileLine = $fileLine -replace "\)", "^)"
        $fileLine = $fileLine -replace '"', '^"'
        
        # If the line is blank then a blank line is generated for the batch file.
        if ($fileLine -match "^\s*$") {
            "echo." | Out-File -FilePath $OutputFile -Append -Encoding ASCII

        # If the line is not blank then the below applies.
        } else {

            # Otherwise just convert the string to a batch export.
            "echo $fileLine" | Out-File -FilePath $OutputFile -Append -Encoding ASCII            
        }
    }

    # Add the footer to the outputted batch file.
    $BatchFooter | Out-File -FilePath $OutputFile -Append -Encoding ASCII

    [System.Windows.Forms.MessageBox]::Show("Recompile completed!", "Finished!")     
}

Function Show-ChangeInput {
    $InputFileGUI = New-Object System.Windows.Forms.OpenFileDialog
    $InputFileGUI.Filter = "PowerShell Script (*.ps1)|*.ps1"
    $GUIResult = $InputFileGUI.ShowDialog()
    if ($GUIResult -eq "OK") {
        $Script:InputFile = $InputFileGUI.FileName
    } else {
        $Script:InputFile = "Canceled"
    }
}

Function Show-ChangeOutput {
    $OutputFileGUI = New-Object System.Windows.Forms.SaveFileDialog
    $OutputFileGUI.Filter = "Batch Script (*.bat)|*.bat"
    $GUIResult = $OutputFileGUI.ShowDialog()
    if ($GUIResult -eq "OK") {
        $Script:OutputFile = $OutputFileGUI.FileName
    } else {
        $Script:OutputFile = "Canceled"
    }
}

# Starts the main interface
Function Show-MainUI ($Icon) {
    # Initialize font setting
    $Label_Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $Argument_Label_Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Regular)
    $Form_Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Regular)

    # Create main form (window)
    $Form = New-Object System.Windows.Forms.Form 
    $Form.Text = "Powershell 2 Batch"
    $Form.MaximizeBox = $false
    $Form.MinimizeBox = $false
    $Form.FormBorderStyle = "FixedSingle"
    $Form.Icon = [System.Drawing.SystemIcons]::Information
    $Form.Size = New-Object System.Drawing.Size(300, 360)
    $Form.StartPosition = "CenterScreen"
    $Form.Font = $Form_Font
    $Form.Topmost = $True

    # Input file current settings.
    $InputFile_Label = New-Object System.Windows.Forms.Label
    $InputFile_Label.Location = New-Object System.Drawing.Point(100, 0)
    $InputFile_Label.Size = New-Object System.Drawing.Size(184, 100)
    $InputFile_Label.BorderStyle = "FixedSingle"
    $InputFile_Label.TextAlign = "MiddleCenter"
    $InputFile_Label.Font = $Label_Font
    $InputFile_Label.Text = "Input File"

    # Output file current settings.
    $OutputFile_Label = New-Object System.Windows.Forms.Label
    $OutputFile_Label.Location = New-Object System.Drawing.Point(100, 101)
    $OutputFile_Label.Size = New-Object System.Drawing.Size(184, 100)
    $OutputFile_Label.BorderStyle = "FixedSingle"
    $OutputFile_Label.TextAlign = "MiddleCenter"
    $OutputFile_Label.Font = $Label_Font
    $OutputFile_Label.Text = "Output File"

    # Argument label.
    $Argument_Label = New-Object System.Windows.Forms.Label
    $Argument_Label.Location = New-Object System.Drawing.Point(0, 160)
    $Argument_Label.Size = New-Object System.Drawing.Size(100, 40)
    $Argument_Label.BorderStyle = "None"
    $Argument_Label.TextAlign = "BottomCenter"
    $Argument_Label.Font = $Argument_Label_Font
    $Argument_Label.Text = "CLI Arg(s):"

    # Add Input File Button
    $Input_Button = New-Object System.Windows.Forms.Button
    $Input_Button.Location = New-Object System.Drawing.Point(0, 0)
    $Input_Button.Size = New-Object System.Drawing.Size(100, 60)
    $Input_Button.Text = "Input File"

    # Add Output File Button
    $Output_Button = New-Object System.Windows.Forms.Button
    $Output_Button.Location = New-Object System.Drawing.Point(0, 100)
    $Output_Button.Size = New-Object System.Drawing.Size(100, 60)
    $Output_Button.Text = "Output File"

    # Argument TextBox
    $Argument_TextBox = New-Object System.Windows.Forms.TextBox
    $Argument_TextBox.Location = New-Object System.Drawing.Point(0, 200)
    $Argument_TextBox.Size = New-Object System.Drawing.Size(284, 10)

    # Yes Radio Button, checked by default
    $Admin_CheckBox = New-Object System.Windows.Forms.CheckBox
    $Admin_CheckBox.Location = New-Object System.Drawing.Point(5, 235)
    $Admin_CheckBox.size = New-Object System.Drawing.Size(140, 20)
    $Admin_CheckBox.Checked = $false 
    $Admin_CheckBox.Text = "Run as admin"

    # No Radio Button, not checked by default
    $HideWindow_CheckBox = New-Object System.Windows.Forms.CheckBox
    $HideWindow_CheckBox.Location = New-Object System.Drawing.Point(150, 235)
    $HideWindow_CheckBox.size = New-Object System.Drawing.Size(160, 20)
    $HideWindow_CheckBox.Checked = $false
    $HideWindow_CheckBox.Text = "Hide Console"
    
    # Add Convert Button
    $Convert_Button = New-Object System.Windows.Forms.Button
    $Convert_Button.Location = New-Object System.Drawing.Point(0, 261)
    $Convert_Button.Size = New-Object System.Drawing.Size(284, 60)
    $Convert_Button.Text = "Convert Powershell 2 Batch"

    # Add Button onClick event listener and logic
    $Convert_Button.Add_Click({
            Convert-File -InputFile $Script:InputFile -OutputFile $Script:OutputFile -CLIArgument $Argument_TextBox.Text -AdminModeRadio $Admin_CheckBox.Checked -DisplayTerminal $HideWindow_CheckBox.Checked
        })
    $Input_Button.Add_Click({Show-ChangeInput
    $InputFile_Label.Text = "$Script:InputFile"})
    $Output_Button.Add_Click({Show-ChangeOutput
    $OutputFile_Label.Text = "$Script:OutputFile"})

    # Add the controls to the form for rendering
    $Form.Controls.Add($Input_Button)
    $Form.Controls.Add($Output_Button)
    $Form.Controls.Add($Argument_TextBox)
    $Form.Controls.Add($Admin_CheckBox)
    $Form.Controls.Add($HideWindow_CheckBox)
    $Form.Controls.Add($Convert_Button)
    $Form.Controls.Add($InputFile_Label)
    $Form.Controls.Add($OutputFile_Label)
    $Form.Controls.Add($Argument_Label)

    # Starts the visual rendering of the form
    $Form.ShowDialog() | Out-Null
}

if ($CLIMode) {
    Convert-File -InputFile $InputFile -OutputFile $OutputFile
} else {
    Show-MainUI
}
