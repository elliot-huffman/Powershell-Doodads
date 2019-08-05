# Create the touch command
New-Alias -Name "Touch" -Value "New-Item" -Description "Create touch command similar to Linux"

# Replace the ping command with a modern replacement
New-Alias -Name "Ping" -Value "Test-NetConnection" -Description "Replace the legacy ping command with a modern replacement"

# Create the tail command
function Tail {
    <#
    .SYNOPSIS
        Follows a file in real time
    .DESCRIPTION
        Long description
    .EXAMPLE
        PS C:\> Tail -Path C:\path\to\log\file.log
        Writes the contents of the log file on the console and updates teh console in real time as the file changes.
    .INPUTS
        System.String
        system.Int32
    .OUTPUTS
        Output (if any)
    .LINK
        https://github.com/elliot-labs/Powershell-Doodads
    #>
    param(
        # Specifies a path to one locations
        [Parameter(
            Mandatory=$true,
            Position=0,
            HelpMessage="Path to one location"
        )]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [String]$Path,
        # Specify the amount of lines to follow
        [Parameter(
            Mandatory=$false,
            Position=1,
            HelpMessage="Specify the amount of lines to follow"
        )]
        [Alias("F")]
        [System.Int32]$LinesToFollow = 50

    )

    # Tail a file. Tailing means to update in real time as the file is updated. Useful for log files
    Get-Content -Path $Path -Tail $LinesToFollow
}

# Create the ll command
function ll {
    <#
    .SYNOPSIS
        Lists all of the items in the specified container, including hidden items
    .DESCRIPTION
        Wraps the Get-ChildItem Cmdlet and specifies force to show hidden items in a similar style to linux.
    .EXAMPLE
        PS C:\> ll
        Lists out the items contained in the "C:\" container, including hidden items.
    .EXAMPLE
        PS C:\> ll -Path "C:\Users\"
        Lists out the items contained in the "C:\Users" container, including hidden items.
    .INPUTS
        System.String[]
    .OUTPUTS
        System.IO.DirectoryInfo
        System.IO.FileInfo
        System.String
    .LINK
        https://github.com/elliot-labs/Powershell-Doodads
    #>
    param(
        # Specifies a path to one or more locations.
        [Parameter(
            Position=0,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage="Path to one or more locations."
        )]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path = ".\"
    )

    # Retrieve the items in the current container, including hidden items
    Get-ChildItem -Path $Path -Force
}
