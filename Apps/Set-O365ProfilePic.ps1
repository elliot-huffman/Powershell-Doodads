# Add command line switch/flag support
# Legacy visuals are for people who like the old visual styles.
# by using the switch, the variable becomes true, bypassing the enable modern visuals step
param([switch]$LegacyVisuals = $false, [string]$UserName)

# Import required libraries
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Enable pretty interface controls (by default)
# Windows 98 styles are ugly compared to today's standards
if (!$LegacyVisuals) {
    [System.Windows.Forms.Application]::EnableVisualStyles()
}

# Set the IsSelected global to false initially.
$global:IsSelected = $false

# Starts the main interface
Function Show-MainUI {
    # Initialize font settings
    $Label_Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $Selected_Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $Form_Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Regular)
    $Credit_Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)

    # Create the main form (window)
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "o365 Profile Pic Changer"
    $Form.MaximizeBox = $false
    $Form.MinimizeBox = $false
    $Form.FormBorderStyle = "FixedSingle"
    $Form.Icon = [System.Drawing.SystemIcons]::Question
    $Form.Size = New-Object System.Drawing.Size(300, 200)
    $Form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")
    $Form.StartPosition = "CenterScreen"
    $Form.Font = $Form_Font
    $Form.Topmost = $True

    # Add a status pane to the top of the application.
    $Status_Label = New-Object System.Windows.Forms.Label
    $Status_Label.Location = New-Object System.Drawing.Point(0, 0)
    $Status_Label.Size = New-Object System.Drawing.Size(284, 60)
    $Status_Label.BorderStyle = "FixedSingle"
    $Status_Label.TextAlign = "MiddleCenter"
    $Status_Label.Font = $Label_Font
    $Status_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
    $Status_Label.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#c62828")
    $Status_Label.Text = "Not Selected"

    # Add credits to the center of the application.
    $Email_Indicator = New-Object System.Windows.Forms.Label
    $Email_Indicator.Location = New-Object System.Drawing.Point(0, 61)
    $Email_Indicator.Size = New-Object System.Drawing.Size(283, 40)
    $Email_Indicator.TextAlign = "MiddleCenter"
    $Email_Indicator.Font = $Credit_Font
    $Email_Indicator.Text = "Created by elliot.huffman@microsoft.com"

    # Add a change button to the bottom of the form.
    $Change_Button = New-Object System.Windows.Forms.Button
    $Change_Button.Location = New-Object System.Drawing.Point(0, 101)
    $Change_Button.Size = New-Object System.Drawing.Size(284, 60)
    $Change_Button.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
    $Change_Button.Text = "Select Profile Picture"

    # Add Button onClick event listener.
    $Change_Button.Add_Click( {
        # If the picture is already selected, start th changing process.
        if ($global:IsSelected) {
            # Get the log in credentials from the user.
            $global:LoginCredentials = Get-UserLogin
            # If the user does not cancel the credential prompt, run the change process with the authorization the user gave.
            if ($global:LoginCredentials -ne $false) {
                # Change the status label text to "Changing"
                $Status_Label.Text = "Changing"
                # Disable the change button
                $Change_Button.Enabled = $false
                # Change the cursor for the form to a wait cursor.
                $Form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
                # Return the font to the standard font.
                $Status_Label.Font = $Label_Font
                # Change the text and background color of the status indicator.
                $Status_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#000000")
                $Status_Label.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#ffc107")
                # Execute the change process on the office 365 cloud environment.
                if ((Set-ProfilePictureViaPS $global:LoginCredentials $global:PicturePath) -ne $false) {
                    # Show a notification that the picture has been updated.
                    # If the session could not connect show an error message. Otherwise notify the user of the success.
                    [System.Windows.Forms.MessageBox]::Show("Picture Updated!")
                } else {
                    # Show an error message with details on how to debug.
                    [System.Windows.Forms.MessageBox]::Show("Could not connect to the cloud server. Please try again. Debug info can be gathered if launched from the PS command line.", "Could not connect", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
                }
            }
            # Change the variable in charge of flow control to false.
            $global:IsSelected = $false
            # Re-enable the change button.
            $Change_Button.Enabled = $true
            # Set the status label font back to standard.
            $Status_Label.Font = $Label_Font
            # Change the mouse cursor back to the system default.
            $Form.Cursor = [System.Windows.Forms.Cursors]::Default
            # Change the text on the change button back to "select profile picture".
            $Change_Button.Text = "Select Profile Picture"
            # Change the label text back to the original settings.
            $Status_Label.Text = "Not Selected"
            $Status_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
            $Status_Label.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#c62828")
        }
        # Otherwise go through the process of selecting the new picture.
        else {
            # Set a global variable with the picture path.
            # It is global because some of the functions that need the path are not part of the current scope.
            $global:PicturePath = Get-NewPicture
            # Set the tool to the next stage if the user does not cancel the selection process.
            if ($global:PicturePath -ne $false) {
                # Set the global routing variable to true.
                $global:IsSelected = $true
                # Change the font of the label to allow more text in the status area.
                $Status_Label.Font = $Selected_Font
                # Change the button text to "Submit to server".
                $Change_Button.Text = "Submit to server"
                # Set the status label to the path of the picture.
                $Status_Label.Text = "Selected photo: $($PicturePath)"
                # Change the background color of the status label.
                $Status_Label.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2e7d32")
            }
        }
    })

    # Add the controls to the form for rendering.
    $Form.Controls.Add($Status_Label)
    $Form.Controls.Add($Email_Indicator)
    $Form.Controls.Add($Change_Button)

    # Starts the visual rendering of the form.
    $Form.ShowDialog() | Out-Null
}

# Get the user's log in credentials and return a secure string.
Function Get-UserLogin() {
    $SecureCredentials = Get-Credential -UserName $UserName -Message "Please provide your UserName@company.com and its password:"
    if ($null -eq $SecureCredentials) {
        [System.Windows.Forms.MessageBox]::Show("Login canceled, canceling operation.", "Stopping operations", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return $false
    } else {
        return $SecureCredentials
    }
}

# Return the path to the selected picture.
Function Get-NewPicture() {
    # Capture the results of opening an open file dialog box.
    $Results = Open-FileDialog
    # If the user cancels the operation, show a notice stating that and return false.
    if ($Results -eq $false) {
        [System.Windows.Forms.MessageBox]::Show("File open canceled. To continue, you will need to select a picture", "Dialog was canceled...", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return $false
    }
    # Otherwise return the file path.
    else {
        return $Results
    }
}

# Connects to the Office 365 cloud server and executes the profile pic update.
Function Set-ProfilePictureViaPS($Credentials, [string]$PicturePathString) {
    # Set up a try/catch block to catch errors for error handling.
    try {
        # Connect to the Office 365 cloud server environment.
        $RemoteSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/?proxymethod=rps -Credential $Credentials -Authentication Basic -AllowRedirection -ErrorAction Stop
    }
    # If the connection attempt fails, dump the results to the console and return false.
    catch {
        Write-Host -Object $_ -ForegroundColor Red -BackgroundColor Black
        return $false
    }
    # Import the commands that are useable.
    Import-PSSession $RemoteSession
    # Set the user profile picture.
    Set-UserPhoto -Identity $Credentials.UserName -PictureData ([System.IO.File]::ReadAllBytes($PicturePathString)) -Confirm:$false
    # Close the Office 365 server connection and clean up the environment.
    Remove-PSSession $RemoteSession
}

# Displays a save dialog to the user and returns the file path selected by the user.
Function Open-FileDialog() {
    # Create a open file dialog box and set the accepted file types.
    $OpenDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenDialog.Filter = "JPEGs|*.jpg;*.jpeg|PNG|*.png|All files (*.*)|*.*"
    $OpenDialog.FilterIndex = 1
    $OpenDialog.RestoreDirectory = $true
    # Show the dialog box and capture the results.
    $Result = $OpenDialog.ShowDialog()

    # If the user selected a file return the file path.
    if ($Result -eq [System.Windows.Forms.DialogResult]::OK) {
        Return $OpenDialog.OpenFile().Name
    }
    # Otherwise return false.
    else {
        Return $false
    }
}

# Start the fun!
Show-MainUI
