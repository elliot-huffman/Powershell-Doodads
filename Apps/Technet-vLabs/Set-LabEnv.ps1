# Works best with:
# Windows Server 2016: Configuring Storage Spaces Direct, Storage Quality of Service, and Storage Replication
# You can find it here: https://www.microsoft.com/handsonlabs/SelfPacedLabs#keywords=windows%20server%202016&page=1&sort=Newest

# Make credentials useable without human interaction.
$User = "Contoso\LabAdmin"
$Password = ConvertTo-SecureString -String "Passw0rd!" -AsPlainText -Force
$Credentials = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $Password

# Configure the Domain controler by installing the ADCS role.
$DC01 = {
    Invoke-Command -ComputerName DC01 -ScriptBlock {
        Install-WindowsFeature -Name ADCS-Cert-Authority -IncludeAllSubFeature
        Restart-Computer
    }
}

# Configure the file server.
# Renames the file server to FSU, from File1
$File1 = { param([pscredential]$Credentials)
    $ScriptBlock = { param([pscredential]$Credentials)
        Install-WindowsFeature -Name FileAndStorage-Services -IncludeAllSubFeature
        Rename-Computer -NewName "FSU" -DomainCredential $Credentials
        $vPool = New-StoragePool -FriendlyName "FSU" -StorageSubsystemFriendlyName "Windows Storage*" -PhysicalDisks (Get-PhysicalDisk -CanPool $true) -ResiliencySettingNameDefault Mirror -ProvisioningTypeDefault Fixed
        $vDisk = New-VirtualDisk -FriendlyName "FSU" -UseMaximumSize -InputObject $vPool
        $InitializedDisk = Initialize-Disk -VirtualDisk $vDisk -PartitionStyle GPT -PassThru
        $Partition = New-Partition -DriveLetter "E" -UseMaximumSize -InputObject $InitializedDisk
        Format-Volume -Partition $Partition -FileSystem ReFS -NewFileSystemLabel "FSU"
        New-Item -ItemType Directory -Path "E:\Shares\FSU"
        New-SmbShare -Name "FSU" -Path "E:\Shares\FSU" -FullAccess "Everyone"
        Restart-Computer
    }
    Invoke-Command -ComputerName File1 -ScriptBlock $ScriptBlock -ArgumentList $Credentials
}

# Configure the second file server.
$File2 = { param([pscredential]$Credentials)
    $ScriptBlock = { param([pscredential]$Credentials)
        Install-WindowsFeature -Name FileAndStorage-Services -IncludeAllSubFeature
        $vPool = New-StoragePool -FriendlyName "FSU" -StorageSubsystemFriendlyName "Windows Storage*" -PhysicalDisks (Get-PhysicalDisk -CanPool $true) -ResiliencySettingNameDefault Mirror -ProvisioningTypeDefault Fixed
        $vDisk = New-VirtualDisk -FriendlyName "FSU" -UseMaximumSize -InputObject $vPool
        $InitializedDisk = Initialize-Disk -VirtualDisk $vDisk -PartitionStyle GPT -PassThru
        $Partition = New-Partition -DriveLetter "E" -UseMaximumSize -InputObject $InitializedDisk
        Format-Volume -Partition $Partition -FileSystem ReFS -NewFileSystemLabel "FSU"
        New-Item -ItemType Directory -Path "E:\Shares\FSU"
        New-SmbShare -Name "FSU" -Path "E:\Shares\FSU" -FullAccess "Everyone"
        Restart-Computer
    }
    Invoke-Command -ComputerName File2 -ScriptBlock $ScriptBlock -ArgumentList $Credentials
}

# configure the third file server.
$File3 = { param([pscredential]$Credentials)
    $ScriptBlock = { param([pscredential]$Credentials)
        Install-WindowsFeature -Name FileAndStorage-Services -IncludeAllSubFeature
        $vPool = New-StoragePool -FriendlyName "FSU" -StorageSubsystemFriendlyName "Windows Storage*" -PhysicalDisks (Get-PhysicalDisk -CanPool $true) -ResiliencySettingNameDefault Mirror -ProvisioningTypeDefault Fixed
        $vDisk = New-VirtualDisk -FriendlyName "FSU" -UseMaximumSize -InputObject $vPool
        $InitializedDisk = Initialize-Disk -VirtualDisk $vDisk -PartitionStyle GPT -PassThru
        $Partition = New-Partition -DriveLetter "E" -UseMaximumSize -InputObject $InitializedDisk
        Format-Volume -Partition $Partition -FileSystem ReFS -NewFileSystemLabel "FSU"
        New-Item -ItemType Directory -Path "E:\Shares\FSU"
        New-SmbShare -Name "FSU" -Path "E:\Shares\FSU" -FullAccess "Everyone"
        Restart-Computer
    }
    Invoke-Command -ComputerName File3 -ScriptBlock $ScriptBlock -ArgumentList $Credentials
}

# Configure the fourth file server.
$File4 = {param([pscredential]$Credentials)
    $ScriptBlock = { param([pscredential]$Credentials)
        Install-WindowsFeature -Name FileAndStorage-Services -IncludeAllSubFeature
        $vPool = New-StoragePool -FriendlyName "FSU" -StorageSubsystemFriendlyName "Windows Storage*" -PhysicalDisks (Get-PhysicalDisk -CanPool $true) -ResiliencySettingNameDefault Mirror -ProvisioningTypeDefault Fixed
        $vDisk = New-VirtualDisk -FriendlyName "FSU" -UseMaximumSize -InputObject $vPool
        $InitializedDisk = Initialize-Disk -VirtualDisk $vDisk -PartitionStyle GPT -PassThru
        $Partition = New-Partition -DriveLetter "E" -UseMaximumSize -InputObject $InitializedDisk
        Format-Volume -Partition $Partition -FileSystem ReFS -NewFileSystemLabel "FSU"
        New-Item -ItemType Directory -Path "E:\Shares\FSU"
        New-SmbShare -Name "FSU" -Path "E:\Shares\FSU" -FullAccess "Everyone"
        Restart-Computer
    }
    Invoke-Command -ComputerName File4 -ScriptBlock $ScriptBlock -ArgumentList $Credentials
}

# Configure the first conmpute headless server
$Compute1 = {
    Invoke-Command -ComputerName Compute1 -ScriptBlock {
        Install-WindowsFeature -Name ADFS-Federation -ComputerName Compute1 -IncludeAllSubFeature
        Restart-Computer
    }
}

# configure the srv01 server.
# Installs all of the remote management tools.
$SRV01 = {
    Invoke-Command -ComputerName localhost -ScriptBlock {
        Update-Help -Force
        Install-WindowsFeature -Name RSAT, web-mgmt-tools -IncludeAllSubFeature
    }
}

# Installs ADFS on the secondary server.
# this is used as the management computer for ADFS as it needs to be on its own dedicated server.
$SRV02 = {
    Invoke-Command -ComputerName SRV02 -ScriptBlock {
        Install-WindowsFeature -Name ADFS-Federation, ADRMS -ComputerName SRV02 -IncludeAllSubFeature -IncludeManagementTools
        Restart-Computer
    }
}


# Asynchronously execute the above commands on the specified computers
Start-Job -ScriptBlock $DC01 -ArgumentList $Credentials
Start-Job -ScriptBlock $File1 -ArgumentList $Credentials
Start-Job -ScriptBlock $File2 -ArgumentList $Credentials
Start-Job -ScriptBlock $File3 -ArgumentList $Credentials
Start-Job -ScriptBlock $File4 -ArgumentList $Credentials
Start-Job -ScriptBlock $Compute1 -ArgumentList $Credentials
Start-Job -ScriptBlock $SRV01 -ArgumentList $Credentials
Start-Job -ScriptBlock $SRV02 -ArgumentList $Credentials

# Print to the consle that it is processing the scripts.
Write-Host "Processing environment setup on all hosts. Please wait..."

# Wait for all of the scripts to finish processing.
Get-Job | Wait-Job

# Restart the current computer after asnyc process has resolved to apply the changes fully.
Restart-Computer
