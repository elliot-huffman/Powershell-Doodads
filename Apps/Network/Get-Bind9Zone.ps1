<#
.SYNOPSIS
    Returns a well defined object structure for DNS records from BIND9 zone files.
.DESCRIPTION
    Parses all of the db.* files in the current directory unless otherwise specified.
    When parsing the files, the contents are enumerated into memory data structures and then returned.

    The data structure is in the format of a PowerShell hashtable.
    The Key is in the name of the zone and the value is an array of PS Custom Objects where each object is a different resource record.

    This version of the script supports only internet records and does not support PTR records.
    This script was primarily designed to parse the zone file configs of BIND9 DNS servers and output an object structure that is easy to migrate to Azure DNS.

    A parameter allows for this script to point to other directories rather than the current working directory.
.EXAMPLE
    PS C:\> Get-Bind9Zone.ps1
    Parses all of the db.* files in the current working and returns objects representing the data in the files.

    Example output:
    Name            Value
    ----            -----
    contoso.com.    {@{Host=contoso.com.; Type=SOA; Class=IN; TTL=14400; PrimaryNS=ns1.contoso.com...
.EXAMPLE
    PS C:\> Get-Bind9Zone.ps1 -Path "~\Desktop\NorthWindTraders"
    Parses all of the db.* files in the current working and returns objects representing the data in the files.

    Example output:
    Name                Value
    ----                -----
    northwind.com.      {@{Host=northwind.com.; Type=SOA; Class=IN; TTL=14500; PrimaryNS=name1.northwind.com...
.PARAMETER Path
    Path to the folder containing the BIND/NameD zone files to be parsed and converted to .net objects.
.INPUTS
    System.String
.OUTPUTS
    System.Collections.Hashtable
.NOTES
    Only IN records are supported.
    HS and CH records are not supported and will throw a warning and the line will be ignored.
    IN PTR records are not supported either
    A warning will be thrown and the line will be ignored.
#>

# Cmdlet bind for additional PS capabilities
[CmdletBinding()]

param(
    [ValidateScript({ Test-Path -Path $_ -PathType "Container" })]
    [System.String]$Path = ".\"
)

# Run this section only once before script processing starts
begin {
    # Initialize helper function for DNS record structure
    function New-DNSRecord {
        <#
        .SYNOPSIS
            Generates a new DNS record hash table
        .DESCRIPTION
            Creates a hash table with the specified inputs.
            This function is meant to create well defined DNS records for use in other functions or data structures.
            This generator function only generates types that Azure Public/External DNS supports
        .EXAMPLE
            PS C:\> New-DNSRecord
            Explanation of what the example does
        .INPUTS
            System.String
        .OUTPUTS
            System.Collections.Hashtable
        .NOTES
            Record Schema:
            fqdn name: string
            Type: string
            Value: RecordData (HashTable)
            TTL: number

            Record Data Schema:
            Data type of data schema - HashTable
            Left side of equals is key name, right side is data type or data
            SOA:

            A:
            Type = "A"
            Host = <>
            AAAA:
            Type = "AAAA"
            CNAME:
            Type = "CNAME"
            Pointer = <string>
            TXT:
        #>

        param (
            [ValidateSet("SOA", "A", "AAAA", "CNAME", "CAA", "MX", "NS", "TXT", "SRV")]
            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory = $true)]
            [System.String]$Type,
            [ValidateSet("IN", "HS", "CH")]
            [System.String]$Class = "IN",
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [System.String]$HostName,
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [System.Int64]$TTL,
            [Parameter(Mandatory = $true, ParameterSetName = 'SOA')]
            [ValidateNotNullOrEmpty()]
            [System.Int64]$Serial,
            [Parameter(Mandatory = $true, ParameterSetName = 'SOA')]
            [ValidateNotNullOrEmpty()]
            [System.Int64]$Refresh,
            [Parameter(Mandatory = $true, ParameterSetName = 'SOA')]
            [ValidateNotNullOrEmpty()]
            [System.Int64]$Retry,
            [Parameter(Mandatory = $true, ParameterSetName = 'SOA')]
            [ValidateNotNullOrEmpty()]
            [System.Int64]$Expire,
            [Parameter(Mandatory = $true, ParameterSetName = 'SOA')]
            [ValidateNotNullOrEmpty()]
            [System.Int64]$Minimum,
            [Parameter(Mandatory = $true, ParameterSetName = 'SOA')]
            [ValidateNotNullOrEmpty()]
            [System.String]$ZoneContact,
            [Parameter(Mandatory = $true, ParameterSetName = 'SOA')]
            [ValidateNotNullOrEmpty()]
            [System.String]$PrimaryNameServer,
            [Parameter(Mandatory = $true, ParameterSetName = 'IP')]
            [ValidateNotNullOrEmpty()]
            [System.Net.IPAddress[]]$IP,
            [Parameter(Mandatory = $true, ParameterSetName = 'CAA')]
            [ValidateSet(0, 1)]
            [ValidateNotNullOrEmpty()]
            [System.Int64]$Flag,
            [Parameter(Mandatory = $true, ParameterSetName = 'CAA')]
            [ValidateSet("issue", "issuewild", "iodef")]
            [ValidateNotNullOrEmpty()]
            [System.String]$Tag,
            [Parameter(Mandatory = $true, ParameterSetName = 'CAA')]
            [Parameter(Mandatory = $true, ParameterSetName = 'NameValue')]
            [Parameter(Mandatory = $true, ParameterSetName = 'MX')]
            [Parameter(Mandatory = $true, ParameterSetName = 'SRV')]
            [ValidateNotNullOrEmpty()]
            [System.String[]]$Value,
            [Parameter(Mandatory = $true, ParameterSetName = 'MX')]
            [Parameter(Mandatory = $true, ParameterSetName = 'SRV')]
            [ValidateNotNullOrEmpty()]
            [System.Int64[]]$Priority,
            [Parameter(Mandatory = $true, ParameterSetName = 'SRV')]
            [ValidateNotNullOrEmpty()]
            [System.Int64[]]$Weight,
            [Parameter(Mandatory = $true, ParameterSetName = 'SRV')]
            [ValidateNotNullOrEmpty()]
            [System.Int64[]]$Port

        )
        
        # Change execution flow based on the type of DNS record
        switch ($Type) {
            "SOA" {
                # Return a SOA record
                return [PSCustomObject]@{
                    "Host"      = $HostName;
                    "Type"      = $Type;
                    "Class"     = $Class;
                    "TTL"       = $TTL;
                    "PrimaryNS" = $PrimaryNameServer;
                    "Serial"    = $Serial;
                    "Refresh"   = $Refresh;
                    "Retry"     = $Retry;
                    "Expire"    = $Expire;
                    "Minimum"   = $Minimum;
                    "Contact"   = $ZoneContact
                }
            }
            { ($_ -eq "A") -or ($_ -eq "AAAA") } {
                return [PSCustomObject]@{
                    "Host"  = $HostName;
                    "Type"  = $Type;
                    "Class" = $Class;
                    "TTL"   = $TTL;
                    "IP"    = $IP;
                }
            }
            "CNAME" {
                return [PSCustomObject]@{
                    "Host"  = $HostName;
                    "Type"  = $Type;
                    "Class" = $Class;
                    "TTL"   = $TTL;
                    "Value" = $Value;
                }
            }
            "CAA" {
                return [PSCustomObject]@{
                    "Host"  = $HostName;
                    "Type"  = $Type;
                    "Class" = $Class;
                    "TTL"   = $TTL;
                    "Flag"  = $Flag;
                    "Tag"   = $Tag;
                    "Value" = $Value;
                }
            }
            "MX" {
                return [PSCustomObject]@{
                    "Host"     = $HostName;
                    "Type"     = $Type;
                    "Class"    = $Class;
                    "TTL"      = $TTL;
                    "Priority" = $Priority;
                    "Value"    = $Value;
                }
            }
            "NS" {
                return [PSCustomObject]@{
                    "Host"  = $HostName;
                    "Type"  = $Type;
                    "Class" = $Class;
                    "TTL"   = $TTL;
                    "Value" = $Value;
                }
            }
            "TXT" {
                return [PSCustomObject]@{
                    "Host"  = $HostName;
                    "Type"  = $Type;
                    "Class" = $Class;
                    "TTL"   = $TTL;
                    "Value" = $Value;
                }
            }
            "SRV" {
                return [PSCustomObject]@{
                    "Host"     = $HostName;
                    "Type"     = $Type;
                    "Class"    = $Class;
                    "Priority" = $Priority;
                    "Weight"   = $Weight;
                    "Port"     = $Port;
                    "Value"    = $Value;
                }
            }
        }
    }

    # Initialize an array of zones where the key is the zone name and the value is the array of records in that zone
    [System.Collections.Hashtable]$ZoneList = @{}
}

# Process each object passed
process {
    # List all of the files in the specified directory and filter them only to domain names
    [System.IO.FileInfo[]]$ConfigList = Get-ChildItem -Path $Path -Filter "db.*" -File | Where-Object -FilterScript { $_.Name -NotLike "*in-addr.arpa*" }

    # Initialize the dictionary that will contain each config's contents for later use
    $LoadedFileList = @{}

    # open and read each file to memory
    foreach ($ConfigFile in $ConfigList) {
        # Open the file and save its value to the LoadedFileList dictionary
        $LoadedFileList["$($ConfigFile.FullName)"] = Get-Content -Path $ConfigFile.FullName
    }

    # Iterate through each loaded file
    foreach ($LoadedFile in $LoadedFileList.GetEnumerator()) {

        # Write verbose info to console
        Write-Verbose -Message "----------------"
        Write-Verbose -Message "Operating on file:"
        Write-Verbose -Message $LoadedFile.Name
        Write-Verbose -Message "----------------"

        # Initialize parser variables
        [System.Int64]$CurrentTTL = 0               # The TTL that the current section runs at
        [System.String]$CurrentOrigin = "."         # The origin is the suffix of the FQDN that the record's name will use
        [System.String]$CurrentHost = ""            # The current host name for the record set that is currently being operated on
        [System.Boolean]$InParentheses = $false     # Keeps track if the current line is in a parentheses set
        [System.String[]]$SOAConfig = @()           # Array of SOA configs in order of scan from the Zone
        [PSCustomObject[]]$RecordList = @()         # List of records in the specified zone

        # Iterate through each line
        foreach ($Line in $LoadedFile.Value) {
            # Remove a comment in a line if it exists and remove any extra whitespace that may be left over because of the comment removal
            [System.String]$NoCommentLine = ($Line -split ";")[0].TrimEnd()

            # Write verbose info to console
            Write-Verbose -Message "================"
            Write-Verbose -Message "No comment line:"
            Write-Verbose -Message $NoCommentLine
            Write-Verbose -Message "Line length: $($NoCommentLine.Length)"
            Write-Verbose -Message "================"

            # Check if the record set is in parentheses
            if ($InParentheses) {
                if ($NoCommentLine -match "(?<=\s+|^)(?<SOAValue>[0-9smhdw]+)") {
                    # Capture all matches, not just the first
                    [System.Text.RegularExpressions.Match[]]$RegexMatchList = [regex]::Matches($NoCommentLine, "(?<=\s+|^)(?<SOAValue>[0-9smhdw]+)", "IgnoreCase")

                    # Write verbose info to console
                    Write-Verbose -Message "SOA Config Matches:"
                    foreach ($Value in $RegexMatchList) { Write-Verbose -Message $Value.Value }

                    # Add the current matches to the SOA config
                    $SOAConfig += $Value.Value
                }

                # Check to see if the line in question also is the end of the parentheses set
                if ($NoCommentLine.Trim() -like "*)*") {
                    # Disable parentheses mode
                    $InParentheses = $false

                    # Write verbose info to console
                    Write-Verbose -Message "Changed parentheses mode to:"
                    Write-Verbose -Message $InParentheses

                    # Set the parameters of the new DNS record function in a hashtable for splatting
                    [System.Collections.Hashtable]$ParamSplat = @{
                        Type              = "SOA"
                        HostName          = "$($CurrentHost + $CurrentOrigin)"
                        TTL               = $CurrentTTL
                        PrimaryNameServer = $SoaPrimaryServer
                        ZoneContact       = $SoaContact
                        Serial            = $SOAConfig[0]
                        Refresh           = $SOAConfig[1]
                        Retry             = $SOAConfig[2]
                        Expire            = $SOAConfig[3]
                        Minimum           = $SOAConfig[4]
                    }

                    # Create the new DNS Record object
                    $RecordList += New-DNSRecord @ParamSplat

                    # Write verbose info to console
                    Write-Verbose -Message "List of Records for the current zone:"
                    foreach ($Record in $RecordList) { Write-Verbose -Message $Record }
                }

                # Continue to the next Value
                continue
            }
            else {
                # Check to see if the current contains is a command
                if ($NoCommentLine -like '`$ORIGIN*') {
                    # If it is

                    # Remove the origin prefix, any trailing white space, and set the current origin to the computed origin
                    $CurrentOrigin = ($NoCommentLine -replace '^\$origin\s*', "").Trim()

                    # If the current origin isn't a single dot, add a prefix dot so that other host names are added in properly and won't merge with non dot origins.
                    if ($CurrentOrigin -ne ".") { $CurrentOrigin = "." + $CurrentOrigin }

                    # Write verbose info to console
                    Write-Verbose -Message "Changed current origin to:"
                    Write-Verbose -Message $CurrentOrigin

                    # Move onto the next line
                    continue
                }
                elseif ($NoCommentLine -like '`$TTL*') {
                    # If the line is a TTL command

                    # Remove the TTL prefix, any trailing white space, and set the current TTL to the computed TTL
                    $CurrentTTL = ($NoCommentLine -replace '^\$TTL\s*', "").Trim()

                    # Write verbose info to console
                    Write-Verbose -Message "Changed current TTL to:"
                    Write-Verbose -Message $CurrentTTL

                    # Move onto the next line
                    continue
                }
                elseif ($NoCommentLine -match "^(?<CurrentHost>[\w+.]+)") {
                    # Capture the current host value and set the current host value to the current host record
                    $CurrentHost = $Matches.CurrentHost

                    # Write verbose info to console
                    Write-Verbose -Message "Changed current host to:"
                    Write-Verbose -Message $CurrentHost
                }
            }

            # Check the current record is an SOA and if it is, get what type of SOA is being used
            if ($NoCommentLine -match "(?<=\w+\s+)(?<Class>IN|HS|CH)\s+(?:SOA)") {
                # Get the SOA Server and the SOA Contact info from the SOA record and silently continue
                $NoCommentLine -match "(?<=SOA)\s+(?<primaryServer>[\w\.]+)\s+(?<contact>[\w\.]+)?" | Out-Null
                [System.Text.RegularExpressions.Match[]]$RegexMatchList = [regex]::Matches($NoCommentLine, "(?<=SOA)\s+(?<primaryServer>[\w\.]+)\s+(?<contact>[\w\.]+)?", "IgnoreCase")

                
                # Set the SOA settings to be consumed by the DNS record builder for SOA records
                [System.String]$SoaPrimaryServer = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq "primaryServer" }).Value
                [System.String]$SoaContact = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq "contact" }).Value

                # Check parentheses mode toggling
                if ($NoCommentLine -like "*(*") {
                    # if a line triggers a parentheses set
                    # Enable parentheses mode
                    $InParentheses = $true

                    # Write verbose info to console
                    Write-Verbose -Message "Changed parentheses mode to:"
                    Write-Verbose -Message $InParentheses

                    # Extract the match info if any exist for the initial parentheses set
                    if (($NoCommentLine -split "\(")[1] -match "(?<=\s+|^)(?<SOAValue>[0-9smhdw]+)") {
                        # Capture all matches, not just the first
                        [System.Text.RegularExpressions.Match[]]$RegexMatchList = [regex]::Matches(($NoCommentLine -split "\(")[1], "(?<=\s+|^)(?<SOAValue>[0-9smhdw]+)", "IgnoreCase")

                        # Write verbose info to console
                        Write-Verbose -Message "SOA Config Matches:"
                        foreach ($Match in $RegexMatchList) { Write-Verbose -Message $Match }

                        # Iterate through the match list and store the results in the SOA Config
                        foreach ($Match in $RegexMatchList) { $SOAConfig += $Match.Value }

                        # Check to see if the line in question also is the end of the parentheses set
                        if ($NoCommentLine.Trim() -like "*)*") {
                            # Disable parentheses mode
                            $InParentheses = $false

                            # Write verbose info to console
                            Write-Verbose -Message "Changed parentheses mode to:"
                            Write-Verbose -Message $InParentheses

                            # Set the parameters of the new DNS record function in a hashtable for splatting
                            [System.Collections.Hashtable]$ParamSplat = @{
                                Type              = "SOA"
                                HostName          = "$($CurrentHost + $CurrentOrigin)"
                                TTL               = $CurrentTTL
                                PrimaryNameServer = $SoaPrimaryServer
                                ZoneContact       = $SoaContact
                                Serial            = $SOAConfig[0]
                                Refresh           = $SOAConfig[1]
                                Retry             = $SOAConfig[2]
                                Expire            = $SOAConfig[3]
                                Minimum           = $SOAConfig[4]
                            }

                            # Create the new DNS Record object
                            $RecordList += New-DNSRecord @ParamSplat

                            # Write verbose info to console
                            Write-Verbose -Message "List of Records for the current zone:"
                            foreach ($Record in $RecordList) { Write-Verbose -Message $Record }
                        }

                        # Continue to the next Value
                        continue
                    }
                }
            }

            # Check to make sure a Chaos or Hesiod record isn't used
            elseif ($NoCommentLine -match "(?<=CH\s+|HS\s+)(A|AAAA|CNAME|CAA|MX|NS|TXT|SRV|PTR)(?=\s+)") {
                # Write a warning to the console for audit purposes
                Write-Warning -Message "CH and HS records are not supported, only IN records are supported."
                
                # Continue to the next line
                continue
            }

            # If it is not an SOA, get the info about the resource record
            elseif ($NoCommentLine -match "(?<=(IN)?\s+)(?<RecordType>A|AAAA|CNAME|CAA|MX|NS|TXT|SRV|PTR)(?=\s+)") {
                # Multi class-support for record matching: (?<=(?<Class>IN|CH|HS)?\s+)(?<Type>SOA|A|AAAA|CNAME|CAA|MX|NS|TXT|SRV|PTR)(?=\s+)

                # Check for the type of the resource record being used
                switch ($Matches.RecordType) {
                    "A" {
                        # Run a match on the current line
                        $NoCommentLine -match "(?<=(?:IN)?\s+A\s+)(?<Value>[\w+\.]+)" | Out-Null

                        # Write verbose info to console
                        Write-Verbose -Message "Current A record IP matches:"
                        Write-Verbose -Message $Matches.value

                        # Create the AAAA record in the record list
                        $RecordList += New-DNSRecord -Type "A" -HostName ($CurrentHost + $CurrentOrigin) -TTL $CurrentTTL -IP $Matches.Value
                    }
                    "AAAA" {
                        # Run a match on the current line
                        $NoCommentLine -match "(?<=(?:IN)?\s+AAAA\s+)(?<Value>[\w+\.]+)" | Out-Null

                        # Write verbose info to console
                        Write-Verbose -Message "Current AAAA record IP matches:"
                        Write-Verbose -Message $Matches.value

                        # Create the AAAA record in the record list
                        $RecordList += New-DNSRecord -Type "AAAA" -HostName ($CurrentHost + $CurrentOrigin) -TTL $CurrentTTL -IP $Matches.Value
                    }
                    "CNAME" {
                        # Run a match on the current line
                        $NoCommentLine -match "(?<=(?:IN)?\s+CNAME\s+)(?<Value>[\w+-\.]+)" | Out-Null

                        # Write verbose info to console
                        Write-Verbose -Message "Current CNAME value matches:"
                        Write-Verbose -Message $Matches.value

                        # Create the AAAA record in the record list
                        $RecordList += New-DNSRecord -Type "CNAME" -HostName ($CurrentHost + $CurrentOrigin) -TTL $CurrentTTL -Value $Matches.Value
                    }
                    "CAA" {
                        # Get the CAA Resource Record's configs
                        [System.Text.RegularExpressions.Match[]]$RegexMatchList = [regex]::Matches($NoCommentLine, "(?<=(?:IN)?\s+CAA\s+)(?<Value>[\w+\.]+)(?:\s+)(?<Type>\w+)(?:\s+\`")(?<Target>.+)(?:\`")", "IgnoreCase")

                
                        # Set the SOA settings to be consumed by the DNS record builder for SOA records
                        [System.String]$CaaValue = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq "Value" }).Value
                        [System.String]$CaaType = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq "Type" }).Value
                        [System.String]$CaaTarget = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq "Target" }).Value

                        # Create the CAA record in the zone's record list
                        $RecordList += New-DNSRecord -Type "CAA" -HostName ($CurrentHost + $CurrentOrigin) -TTL $CurrentTTL -Flag $CaaValue -Tag $CaaType -Value $CaaTarget
                    }
                    "MX" {
                        # Get the MX Resource Record's configs
                        [System.Text.RegularExpressions.Match[]]$RegexMatchList = [regex]::Matches($NoCommentLine, "(?<=(?:IN)?\s+MX\s+)(?<Priority>[\d+]+)(?:\s+)(?<Value>\S+)", "IgnoreCase")

                
                        # Set the MX settings to be consumed by the DNS record builder for MX records
                        [System.String]$MxPriority = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq "Priority" }).Value
                        [System.String]$MxValue = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq "Value" }).Value
                        
                        # Create the MX record in the zone's record list
                        $RecordList += New-DNSRecord -Type "MX" -HostName ($CurrentHost + $CurrentOrigin) -TTL $CurrentTTL -Priority $MxPriority -Value $MxValue
                    }
                    "NS" {
                        # Run a match on the current line
                        $NoCommentLine -match "(?<=(?:IN)?\s+NS\s+)(?<Value>[\w+-\.]+)" | Out-Null

                        # Write verbose info to console
                        Write-Verbose -Message "Current NS value matches:"
                        Write-Verbose -Message $Matches.value
                                                
                        # Create the AAAA record in the record list
                        $RecordList += New-DNSRecord -Type "NS" -HostName ($CurrentHost + $CurrentOrigin) -TTL $CurrentTTL -Value $Matches.Value 
                    }
                    "TXT" {
                        # Run a match on the current line
                        $NoCommentLine -match "(?<=(?:IN)?\s+TXT\s+\`")(?<Value>.+)(?:\`")" | Out-Null

                        # Write verbose info to console
                        Write-Verbose -Message "Current TXT value matches:"
                        Write-Verbose -Message $Matches.value
                        
                        # Create the AAAA record in the record list
                        $RecordList += New-DNSRecord -Type "TXT" -HostName ($CurrentHost + $CurrentOrigin) -TTL $CurrentTTL -Value $Matches.Value
                    }
                    "SRV" {
                        # Get the SRV Resource Record's configs
                        [System.Text.RegularExpressions.Match[]]$RegexMatchList = [regex]::Matches($NoCommentLine, "(?<=(?:IN)?\s+SRV\s+)(?<Priority>[\d+]+)(?:\s+)(?<Weight>\d+)(?:\s+)(?<Port>\d+)(?:\s+)(?<Target>\S+)", "IgnoreCase")

                        # Set the SRV settings to be consumed by the DNS record builder for SRV records
                        [System.String]$SrvPriority = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq "Priority" }).Value
                        [System.String]$SrvWeight = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq "Weight" }).Value
                        [System.String]$SrvPort = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq "Port" }).Value
                        [System.String]$SrvTarget = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq "Target" }).Value
                                                
                        # Create the SRV record in the zone's record list
                        $RecordList += New-DNSRecord -Type "SRV" -HostName ($CurrentHost + $CurrentOrigin) -TTL $CurrentTTL -Priority $SrvPriority -Weight $SrvWeight -Port $SrvPort -Value $SrvTarget
                    }
                    "PTR" {
                        # Warn the user that PTR records are not supported
                        Write-Warning -Message "PTR records are currently not supported!"
    
                        # Move onto the next line
                        continue
                    }
                }
            }
        }

        # Capture the record list and make a new Zone object containing the configurations for that zone
        $ZoneList.($RecordList[0].Host) = $RecordList
    }
}

# Run this section only once after script processing has completed
end {
    # Return the processed data for each zone to the caller
    return $ZoneList
}