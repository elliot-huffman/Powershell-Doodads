<#
.SYNOPSIS
    This script converts PowerShell scripts to batch scripts to execute directly on systems.
.DESCRIPTION
    This script takes the input PowerShell script and exports it as a batch script that can be directly run on the system.
    This script can be run on the CLI mode or as a GUI mode.
.PARAMETER LegacyVisuals
    When this flag is specified, the user interface will render with the Windows 98 reminiscent visual styles of the classic theme.
    This parameter is only useable when the UI is used.
    This flag does nothing if used with the CLIMode flag.
.PARAMETER CLIMode
    When this flag is set, the GUI will not be displayed and the other CLI arguments will be used for the required information.
.PARAMETER InputFile
    The path to the file that will be used as the source for the outputted batch script.
    Only used with the CLIMode flag. This parameter is required.
.PARAMETER OutputFile
    The destination and file name that will be used when the source file has finished processing.
    If this parameter is not specified, the same file path to the input file is used and the ".bat" file extension is added to the file.
    This parameter is only used with the CLIMode flag.
.PARAMETER AdminMode
    When this flag is specified a header will be added to the batch boot-strapper that checks to see fi the script is being run as admin.
    This parameter is only used with the CLIMode flag.
.PARAMETER SelfDelete
    When this flag is specified a line of code will be added to the end of the boot-strapper that will self delete the batch script.
    This parameter is only used with the CLIMode flag.
.PARAMETER HideTerminal
    When this flag is specified The launch parameter fo the PowerShell script is modified to include a parameter that disabled the terminal from being displayed.
    This parameter is only used with the CLIMode flag.
.PARAMETER CLIArgument
    Arguments to be included in the execution of the PowerShell code.
    This parameter is only used with the CLIMode flag.
.EXAMPLE
    Convert-PowerShellToBatch.ps1
    This will run the converter in full GUI mode.

    OUTPUT:
    User interface with graphical options to configure the operation of this script.
.EXAMPLE
    Convert-PowerShellToBatch.ps1 -CLIMode -InputFile "C:\Get-UserNAP.ps1"
    This will disable GUI mode and take the inputted file and export it as a batch script with the same path and file name with ".bat" appended to it.
.EXAMPLE
    Convert-PowerShellToBatch.ps1 -CLIMode -InputFile "C:\Get-UserNAP.ps1" -OutputFile "C:\Get-UserNAP.bat" -SelfDelete
    This will disable GUI mode and take the inputted file and export it as a batch script that will self delete after execution has completed.
.LINK
    https://github.com/elliot-labs/PowerShell-Doodads
.NOTES
    This tool is not needed for general use and should only be used when you know you need to change a PowerShell file into a self contained batch script.
#>

#Requires -Version 5.0

# Add command line switch/flag support.
# Each parameter is detailed in the above help documentation.
param(
    # Parameters for GUI.
    [Parameter(
        ParameterSetName = 'GUI'
    )]
    [switch]$LegacyVisuals = $False,

    # Parameters for CLI.
    [Parameter(
        ParameterSetName = 'CLI',
        Position = 0,
        Mandatory = $true
    )]
    [switch]$CLIMode,
    [Parameter(
        ParameterSetName = 'CLI',
        Position = 1,
        Mandatory = $true
    )]
    [string]$InputFile,
    [Parameter(
        ParameterSetName = 'CLI'
    )]
    [string]$OutputFile,
    [Parameter(
        ParameterSetName = 'CLI'
    )]
    [switch]$AdminMode,
    [Parameter(
        ParameterSetName = 'CLI'
    )]
    [switch]$SelfDelete,
    [Parameter(
        ParameterSetName = 'CLI'
    )]
    [switch]$HideTerminal,
    [Parameter(
        ParameterSetName = 'CLI'
    )]
    [string[]]$CLIArgument = ""
)

# If the app is running in GUI mode (not CLI mode), execute the below.
# If the app is running in CLI mode, don't execute the below
if (-not $CLIMode) {
    # Import required libraries
    Add-Type -AssemblyName "System.Windows.Forms"
    Add-Type -AssemblyName "System.Drawing"

    # Enable pretty interface controls (by default)
    # Windows 98 styles are ugly compared to today's standards
    if (-not $LegacyVisuals) { [System.Windows.Forms.Application]::EnableVisualStyles() }
}

# The core class of the transpiler
class AppConfig {
    [System.String]$InputFile
    [System.String]$OutputFile
    [System.Boolean]$RunAsAdmin
    [System.Boolean]$SelfDelete
    [System.Boolean]$HideTerminal
    [System.String[]]$ArgumentList
    hidden [System.String]$BatchHeader
    hidden [System.String]$AdminHeader
    hidden [System.String]$HideTerminalParam
    hidden [System.String]$BatchFooter
    hidden [System.String]$SelfDeleteFooter

    AppConfig() {
        $this.InputFile = ""
        $this.OutputFile = ""
        $this.RunAsAdmin = $False
        $this.SelfDelete = $False
        $this.HideTerminal = $False
        $this.ArgumentList = @()
        $this.BatchHeader = @"
@echo off
color 0A
cls
cd /d %~dp0
set Script="%Temp%\%RANDOM%-%RANDOM%-%RANDOM%-%RANDOM%.ps1"
# TODO: Header admin code goes here
(
"@
        $this.AdminHeader = ':CheckAdmin
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Success: Administrative permissions confirmed.
) else (
    echo Please run script as administrator.
    pause
    exit
)
'
        $this.HideTerminalParam = "-WindowStyle Hidden"
        $this.BatchFooter = ") > %Script%
PowerShell -ExecutionPolicy Unrestricted -File %Script%
del %Script%"
        $this.SelfDeleteFooter = "(goto) 2>nul & del `"%~f0`""
    }

    # Process the parameter data into the app config data structure
    [Void]ProcessParameters (
        [System.String]$InputFile,
        [System.String]$OutputFile,
        [System.Boolean]$RunAsAdmin,
        [System.Boolean]$SelfDelete,
        [System.Boolean]$HideTerminal,
        [System.String[]]$ArgumentList
        ) {
            $this.InputFile = $InputFile
            $this.OutputFile = $OutputFile
            $this.RunAsAdmin = $RunAsAdmin
            $this.SelfDelete = $SelfDelete
            $this.HideTerminal = $HideTerminal
            $this.ArgumentList = $ArgumentList

            # Process the input path and update it to be the output path with modifications.
            if ($this.OutputFile -eq "") {$this.OutputFile = $this.InputFile + ".bat"}
        }
    [Void]WriteFile([System.String]$DataToWrite) {
        # Append the specified data to the bottom of the output file in ASCII format.
        Out-File -FilePath $this.OutputFile -Encoding "ASCII" -Append -InputObject $DataToWrite
    }
    [Void]WriteFile([System.String]$DataToWrite, [System.Boolean]$Delete = $true) {
        # If the delete parameter is specified and is $true
        if ($Delete) {
            # Overwrite any existing file data with the new specified data in ASCII format.
            Out-File -FilePath $this.OutputFile -Encoding "ASCII" -InputObject $DataToWrite
        } else {
            # Append the specified data to the bottom of the output file in ASCII format.
            Out-File -FilePath $this.OutputFile -Encoding "ASCII" -InputObject $DataToWrite -Append
        }
    }

    # A method that updates the batch header property to contain the expected values for the file write operation
    [Void]ComputeBatchHeaderOptions() {
        # Set the baseline for the batch script's header section
        $this.BatchHeader = @"
@echo off
color 0A
cls
cd /d %~dp0
set Script="%Temp%\%RANDOM%-%RANDOM%-%RANDOM%-%RANDOM%.ps1"
"@
        # If the run as admin option is set, add the run as admin header section to the baseline
        if ($this.RunAsAdmin) { $this.BatchHeader += "`n$($this.AdminHeader)" }

        # Add the necessary open parentheses to the batch header
        $this.BatchHeader += "`n("
    }

    # Opens the input file, automatically escapes special chars and writes the results to the destination file
    [Void]ProcessScriptBody() {
        # Open the script to be converted and run a sequence of commands upon each line in order from top to bottom.
        Get-Content -Path $this.InputFile | ForEach-Object {

            # Automatically comments out special characters in the current line.
            $fileLine = $_ -replace "\^", "^^"
            $fileLine = $fileLine -replace "\|", "^|"
            $fileLine = $fileLine -replace ">", "^>"
            $fileLine = $fileLine -replace "<", "^<"
            $fileLine = $fileLine -replace "%", "%%"
            $fileLine = $fileLine -replace "&", "^&"
            $fileLine = $fileLine -replace "\(", "^("
            $fileLine = $fileLine -replace "\)", "^)"
            $fileLine = $fileLine -replace '"', '^"'
            
            # If the current input file's line is blank.
            if ($fileLine -match "^\s*$") {
                # Enter a blank echo which is an echo with a period, this generates a line of nothing in the batch processor
                $this.WriteFile("echo.")
            } else { # If the line is not blank then the below applies.
                # Directly write the line of converted code to the specified file while appending an echo command which will write the line contents to a file.
                $this.WriteFile("echo $fileLine")            
            }
        }
    }

    # A method that updates the batch footer property to contain the expected values for the file write operation
    [Void]ComputeBatchFooterOptions() {
        # Build the batch script's footer dynamically
        $this.BatchFooter = ") > %Script%
PowerShell -ExecutionPolicy Unrestricted $(if ($this.HideTerminal) {$this.HideTerminalParam}) -File %Script% $($this.ArgumentList)
del %Script%"

        # If the self delete option is selected, add the self delete footer to the batch footer
        if ($this.SelfDelete) { $this.BatchFooter += "`n$($this.SelfDeleteFooter)" }
    }

    # Executes the correct transpilation process in the correct order. Aka, the business logic portion of the app.
    [System.Boolean]ExecuteConversion() {
        # Compute the batch file's header to be written
        $this.ComputeBatchHeaderOptions()

        # Write the specified header to the batch file
        $this.WriteFile($this.BatchHeader, $true)

        # Execute the main conversion of the powershell script to the batch script file
        $this.ProcessScriptBody()

        # Compute the batch file's footer to be written
        $this.ComputeBatchFooterOptions()

        # Write the specified footer to the batch file
        $this.WriteFile($this.BatchFooter)

        # Return true for a successful conversion
        return $true
    }
}

# Instantiate the config engine
$appConfigInstance = New-Object -TypeName "AppConfig"

# Create input file dialog function
function Show-ChangeInput {
    <#
    .SYNOPSIS
        Have user select file via GUI
    .DESCRIPTION
        Create an open file dialog that only accepts powershell scripts and returns the specified file path.
    .EXAMPLE
        Show-ChangeInput
        The function will display a dialog box for the user to select a file.
        The file types that will be visible will be restricted to powershell files.
        If the user cancels the dialog, it will return false.
        Example successful return:
        "C:\PowerShell-Doodads\Apps\Food\Get-WalmartGiftCard.ps1"
    .OUTPUTS
        System.String
        System.Boolean
    .LINK
        https://github.com/elliot-labs/PowerShell-Doodads
    .NOTES
        The function will return a string if successful, it will return false if unsuccessful. E.g. user cancels the dialog.
        This function requires PS Desktop as it uses windows forms.
    #>

    # Cmdlet bind the function for advanced functionality
    [CmdletBinding()]

    # Empty params as no input is necessary, this is so that cmdlet binding can take place
    param()

    # Write Verbose info
    Write-Verbose -Message "Initializing Type (OpenFileDialog)"

    # Initialize the OpenFileDialog type
    $InputFileGUI = New-Object -TypeName "System.Windows.Forms.OpenFileDialog"

    # Write Verbose info
    Write-Verbose -Message "Setting dialog settings (file type and title)"

    # Set the file selector filter
    $InputFileGUI.Filter = "PowerShell Script (*.ps1)|*.ps1"

    # Set the dialog's Window title
    $InputFileGUI.Title = "Select a PowerShell File"

    # Write Verbose info
    Write-Verbose -Message "Rendering Open File Dialog"

    # Render the dialog for the end user
    $GUIResult = $InputFileGUI.ShowDialog()

    # Write debug info
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Dialog info:"
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$GUIResult: $GUIResult"
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$InputFileGUI.FileName: ${$InputFileGUI.FileName}"

    # Check to see if the user has provided input
    if ($GUIResult -eq "OK") {
        # Return the user's selected file
        return $InputFileGUI.FileName
    } else {
        # Return false for failure
        return $false
    }
}

function Show-ChangeOutput {
    <#
    .SYNOPSIS
        Have a user select file location via GUI.
    .DESCRIPTION
        Create an save file dialog that only allows batch scripts and returns the file path selected by the user.
    .EXAMPLE
        Show-ChangeOutput
        The function will display a dialog box for the user to save a file.
        The file types that will be able to be saved is restricted to batch files.
        If the user cancels the dialog, it will return false.
        Example successful return:
        "C:\PowerShell-Doodads\Apps\Food\Get-WalmartGiftCard.bat"
    .OUTPUTS
        System.String
        System.Boolean
    .LINK
        https://github.com/elliot-labs/PowerShell-Doodads
    .NOTES
        The function will return a string if successful, it will return false if unsuccessful. E.g. user cancels the dialog.
        This function requires PS Desktop as it uses windows forms.
    #>

    # Cmdlet bind the function for advanced functionality
    [CmdletBinding()]

    # Empty params as no input is necessary, this is so that cmdlet binding can take place
    param()

    # Write Verbose info
    Write-Verbose -Message "Initializing Type (SaveFileDialog)"

    # Initialize the SaveFileDialog class
    $OutputFileGUI = New-Object -TypeName "System.Windows.Forms.SaveFileDialog"

    # Write Verbose info
    Write-Verbose -Message "Setting dialog settings (file type and title)"

    # Set the file type to be saved as a Batch Script
    $OutputFileGUI.Filter = "Batch Script (*.bat)|*.bat"

    # Configure the title of the file save dialog
    $OutputFileGUI.Title = "Save as"

    # Write Verbose info
    Write-Verbose -Message "Rendering Save File Dialog"

    # Render the dialog for the end user.
    $GUIResult = $OutputFileGUI.ShowDialog()

    # Write debug info
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - Dialog info:"
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$GUIResult: $GUIResult"
    Write-Debug -Message "$(Get-Date -Format "HH:mm:ss") - `$OutputFileGUI.FileName: ${$OutputFileGUI.FileName}"

    # Check to see if the user has provided input
    if ($GUIResult -eq "OK") {
        # Return the user's specified file path
        return $OutputFileGUI.FileName
    } else {
        # Return false for failure
        return $false
    }
}

# Starts the main interface
Function Show-MainUI {
    # Process the command line parameters that were provided to the app during launch
    $appConfigInstance.ProcessParameters($InputFile, $OutputFile, $RunAsAdmin, $SelfDelete, $HideTerminal, $ArgumentList)

    # Initialize font setting
    $Label_Font = New-Object -TypeName System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $Argument_Label_Font = New-Object -TypeName System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Regular)
    $Form_Font = New-Object -TypeName System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Regular)

    # Create main form (window)
    $Form = New-Object -TypeName "System.Windows.Forms.Form" 
    $Form.Text = "PowerShell 2 Batch"
    $Form.MaximizeBox = $false
    $Form.MinimizeBox = $false
    $Form.FormBorderStyle = "FixedSingle"
    $Form.Icon = [System.Drawing.SystemIcons]::Information
    $Form.Size = New-Object -TypeName "System.Drawing.Size(300, 380)"
    $Form.StartPosition = "CenterScreen"
    $Form.Font = $Form_Font
    $Form.Topmost = $True

    # Input file current settings.
    $InputFile_Label = New-Object -TypeName "System.Windows.Forms.Label"
    $InputFile_Label.Location = New-Object -TypeName "System.Drawing.Point(100, 0)"
    $InputFile_Label.Size = New-Object -TypeName "System.Drawing.Size(184, 100)"
    $InputFile_Label.BorderStyle = "FixedSingle"
    $InputFile_Label.TextAlign = "MiddleCenter"
    $InputFile_Label.Font = $Label_Font
    $InputFile_Label.Text = "Input File"

    # Output file current settings.
    $OutputFile_Label = New-Object -TypeName "System.Windows.Forms.Label"
    $OutputFile_Label.Location = New-Object -TypeName "System.Drawing.Point(100, 101)"
    $OutputFile_Label.Size = New-Object -TypeName "System.Drawing.Size(184, 100)"
    $OutputFile_Label.BorderStyle = "FixedSingle"
    $OutputFile_Label.TextAlign = "MiddleCenter"
    $OutputFile_Label.Font = $Label_Font
    $OutputFile_Label.Text = "Output File"

    # Argument label.
    $Argument_Label = New-Object -TypeName "System.Windows.Forms.Label"
    $Argument_Label.Location = New-Object -TypeName "System.Drawing.Point(0, 160)"
    $Argument_Label.Size = New-Object -TypeName "System.Drawing.Size(100, 40)"
    $Argument_Label.BorderStyle = "None"
    $Argument_Label.TextAlign = "BottomCenter"
    $Argument_Label.Font = $Argument_Label_Font
    $Argument_Label.Text = "CLI Arg(s):"

    # Add Input File Button
    $Input_Button = New-Object -TypeName "System.Windows.Forms.Button"
    $Input_Button.Location = New-Object -TypeName "System.Drawing.Point(0, 0)"
    $Input_Button.Size = New-Object -TypeName "System.Drawing.Size(100, 60)"
    $Input_Button.Text = "Input File"

    # Add Output File Button
    $Output_Button = New-Object -TypeName "System.Windows.Forms.Button"
    $Output_Button.Location = New-Object -TypeName "System.Drawing.Point(0, 100)"
    $Output_Button.Size = New-Object -TypeName "System.Drawing.Size(100, 60)"
    $Output_Button.Text = "Output File"

    # Argument TextBox
    $Argument_TextBox = New-Object -TypeName "System.Windows.Forms.TextBox"
    $Argument_TextBox.Location = New-Object -TypeName "System.Drawing.Point(0, 200)"
    $Argument_TextBox.Size = New-Object -TypeName "System.Drawing.Size(284, 10)"

    # Yes Radio Button, checked by default
    $Admin_CheckBox = New-Object -TypeName "System.Windows.Forms.CheckBox"
    $Admin_CheckBox.Location = New-Object -TypeName "System.Drawing.Point(5, 235)"
    $Admin_CheckBox.size = New-Object -TypeName "System.Drawing.Size(140, 20)"
    $Admin_CheckBox.Checked = $false 
    $Admin_CheckBox.Text = "Run as admin"

    # No Radio Button, not checked by default
    $HideWindow_CheckBox = New-Object -TypeName "System.Windows.Forms.CheckBox"
    $HideWindow_CheckBox.Location = New-Object -TypeName "System.Drawing.Point(150, 235)"
    $HideWindow_CheckBox.size = New-Object -TypeName "System.Drawing.Size(160, 20)"
    $HideWindow_CheckBox.Checked = $false
    $HideWindow_CheckBox.Text = "Hide Console"

    # Yes Radio Button, checked by default
    $SelfDelete_CheckBox = New-Object -TypeName "System.Windows.Forms.CheckBox"
    $SelfDelete_CheckBox.Location = New-Object -TypeName "System.Drawing.Point(5, 258)"
    $SelfDelete_CheckBox.size = New-Object -TypeName "System.Drawing.Size(140, 20)"
    $SelfDelete_CheckBox.Checked = $false 
    $SelfDelete_CheckBox.Text = "Self Delete"
    
    # Add Convert Button
    $Convert_Button = New-Object -TypeName "System.Windows.Forms.Button"
    $Convert_Button.Location = New-Object -TypeName "System.Drawing.Point(0, 281)"
    $Convert_Button.Size = New-Object -TypeName "System.Drawing.Size(284, 60)"
    $Convert_Button.Text = "Convert PowerShell 2 Batch"

    # Add Button onClick event listener and logic
    $Convert_Button.Add_Click(
        {
            $appConfigInstance.ArgumentList = $Argument_TextBox.Text
            $appConfigInstance.RunAsAdmin = $Admin_CheckBox.Checked
            $appConfigInstance.HideTerminal = $HideWindow_CheckBox.Checked
            $appConfigInstance.SelfDelete = $SelfDelete_CheckBox.Checked
            $appConfigInstance.ExecuteConversion()
        })
    $Input_Button.Add_Click(
        {
            $InputSelection = Show-ChangeInput
            $InputFile_Label.Text = $InputSelection
            $appConfigInstance.InputFile = $InputSelection
        })
    $Output_Button.Add_Click(
        {
            $OutputSelection = Show-ChangeOutput
            $OutputFile_Label.Text = $OutputSelection
            $appConfigInstance.OutputFile = $OutputSelection
        })

    # Add the controls to the form for rendering
    $Form.Controls.Add($Input_Button)
    $Form.Controls.Add($Output_Button)
    $Form.Controls.Add($Argument_TextBox)
    $Form.Controls.Add($Admin_CheckBox)
    $Form.Controls.Add($SelfDelete_CheckBox)
    $Form.Controls.Add($HideWindow_CheckBox)
    $Form.Controls.Add($Convert_Button)
    $Form.Controls.Add($InputFile_Label)
    $Form.Controls.Add($OutputFile_Label)
    $Form.Controls.Add($Argument_Label)

    # Starts the visual rendering of the form
    $Form.ShowDialog() | Out-Null
}

# TODO: add automatic dot sourcing support '$MyInvocation.Line -NotMatch "^\.\s"'

# If the CLI Mode param was specified, execute conversion directly without rendering the main UI.
if ($CLIMode) {
    # Process the parameters specified into the class object
    $appConfigInstance.ProcessParameters($InputFile, $OutputFile, $RunAsAdmin, $SelfDelete, $HideTerminal, $ArgumentList)

    # Execute the conversion process
    $appConfigInstance.ExecuteConversion()
} else { # if the CLI mode param was not specified
    # Start the Main UI renderer
    Show-MainUI
}