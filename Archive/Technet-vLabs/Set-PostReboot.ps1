# Works best with:
# Windows Server 2016: Configuring Storage Spaces Direct, Storage Quality of Service, and Storage Replication
# You can find it here: https://www.microsoft.com/handsonlabs/SelfPacedLabs#keywords=windows%20server%202016&page=1&sort=Newest

# Make credentials useable without human interaction.
$User = "Contoso\LabAdmin"
$Password = ConvertTo-SecureString -String "Passw0rd!" -AsPlainText -Force
$Credentials = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $Password

# Initialize DHCP and ADCS.
$DC01 = { param([pscredential]$Credentials)
    # pass
}

# Set up DFS
$FSU = { param([pscredential]$Credentials)
    # Pass
}

Start-Job -ScriptBlock $DC01 -ArgumentList $Credentials
Start-Job -ScriptBlock $FSU -ArgumentList $Credentials

# Print to the consle that it is processing the scripts.
Write-Host "Processing environment setup on all hosts, post reboot. Please wait..."

# Wait for all of the scripts to finish processing.
Get-Job | Wait-Job

# Clear the consle of clutter.
Clear-Host

# Write the success message.
Write-Host "Environment setup has completed successfully!"
