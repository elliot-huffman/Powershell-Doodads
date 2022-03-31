<#
.SYNOPSIS
    Returns a well defined object structure for DNS records from BIND9 zone files.
.DESCRIPTION
    Parses all of the db.* files in the current directory unless otherwise specified.
    When parsing the files, the contents are enumerated into memory data structures and then returned.

    The data structure is in the format of a PowerShell hashtable.
    The Key is in the name of the zone and the value is an array of PS Custom Objects where each object is a different resource record.

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

#>

# Cmdlet bind for additional PS capabilities
[CmdletBinding()]

param(
    [ValidateScript({ Test-Path -Path $_ -PathType 'Container' })]
    [System.String]$Path = '.\'
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
            [ValidateSet('SOA', 'A', 'AAAA', 'CNAME', 'CAA', 'MX', 'NS', 'TXT', 'SRV', 'PTR')]
            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory = $true)]
            [System.String]$Type,
            [ValidateSet('IN', 'HS', 'CH')]
            [System.String]$Class = 'IN',
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
            [ValidateSet('issue', 'issuewild', 'iodef')]
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
            'SOA' {
                # Return a SOA record
                return [PSCustomObject]@{
                    'Host'      = $HostName;
                    'Type'      = $Type;
                    'Class'     = $Class;
                    'TTL'       = $TTL;
                    'PrimaryNS' = $PrimaryNameServer;
                    'Serial'    = $Serial;
                    'Refresh'   = $Refresh;
                    'Retry'     = $Retry;
                    'Expire'    = $Expire;
                    'Minimum'   = $Minimum;
                    'Contact'   = $ZoneContact
                }
            }
            { ($_ -eq 'A') -or ($_ -eq 'AAAA') } {
                return [PSCustomObject]@{
                    'Host'  = $HostName;
                    'Type'  = $Type;
                    'Class' = $Class;
                    'TTL'   = $TTL;
                    'IP'    = $IP;
                }
            }
            'CNAME' {
                return [PSCustomObject]@{
                    'Host'  = $HostName;
                    'Type'  = $Type;
                    'Class' = $Class;
                    'TTL'   = $TTL;
                    'Value' = $Value;
                }
            }
            'CAA' {
                return [PSCustomObject]@{
                    'Host'  = $HostName;
                    'Type'  = $Type;
                    'Class' = $Class;
                    'TTL'   = $TTL;
                    'Flag'  = $Flag;
                    'Tag'   = $Tag;
                    'Value' = $Value;
                }
            }
            'MX' {
                return [PSCustomObject]@{
                    'Host'     = $HostName;
                    'Type'     = $Type;
                    'Class'    = $Class;
                    'TTL'      = $TTL;
                    'Priority' = $Priority;
                    'Value'    = $Value;
                }
            }
            'NS' {
                return [PSCustomObject]@{
                    'Host'  = $HostName;
                    'Type'  = $Type;
                    'Class' = $Class;
                    'TTL'   = $TTL;
                    'Value' = $Value;
                }
            }
            'TXT' {
                return [PSCustomObject]@{
                    'Host'  = $HostName;
                    'Type'  = $Type;
                    'Class' = $Class;
                    'TTL'   = $TTL;
                    'Value' = $Value;
                }
            }
            'SRV' {
                return [PSCustomObject]@{
                    'Host'     = $HostName;
                    'Type'     = $Type;
                    'Class'    = $Class;
                    'TTL'      = $TTL;
                    'Priority' = $Priority;
                    'Weight'   = $Weight;
                    'Port'     = $Port;
                    'Value'    = $Value;
                }
            }
            'PTR' {
                return [PSCustomObject]@{
                    'Host'  = $HostName;
                    'Type'  = $Type;
                    'Class' = $Class;
                    'TTL'   = $TTL;
                    'Value' = $Value;
                }
            }
        }
    }

    # Initialize an array of zones where the key is the zone name and the value is the array of records in that zone
    [System.Collections.Hashtable]$ZoneList = @{}
}

# Process each object passed
process {
    # List all of the zone files in the specified directory
    [System.IO.FileInfo[]]$ConfigList = Get-ChildItem -Path $Path -Filter 'db.*' -File

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
        Write-Verbose -Message '----------------'
        Write-Verbose -Message 'Operating on file:'
        Write-Verbose -Message $LoadedFile.Name
        Write-Verbose -Message '----------------'

        # Initialize parser variables
        [System.Int64]$CurrentTTL = 0               # The TTL that the current section runs at
        [System.String]$CurrentOrigin = '.'         # The origin is the suffix of the FQDN that the record's name will use
        [System.String]$CurrentHost = ''            # The current host name for the record set that is currently being operated on
        [System.Boolean]$InParentheses = $false     # Keeps track if the current line is in a parentheses set
        [System.String]$SoaClass = ''               # The class type of the SOA, valid values are "IN", "HS", or "CH"
        [System.String[]]$SoaConfig = @()           # Array of SOA configs in order of scan from the Zone
        [PSCustomObject[]]$RecordList = @()         # List of records in the specified zone

        # Iterate through each line
        foreach ($Line in $LoadedFile.Value) {
            # Remove a comment in a line if it exists and remove any extra whitespace that may be left over because of the comment removal
            [System.String]$NoCommentLine = ($Line -split ';')[0].TrimEnd()

            # Write verbose info to console
            Write-Verbose -Message '================'
            Write-Verbose -Message 'No comment line:'
            Write-Verbose -Message $NoCommentLine
            Write-Verbose -Message "Line length: $($NoCommentLine.Length)"
            Write-Verbose -Message '================'

            # Check to see if the current contains is a command
            if ($NoCommentLine -like '`$ORIGIN*') {
                # If it is

                # Remove the origin prefix, any trailing white space, and set the current origin to the computed origin
                $CurrentOrigin = ($NoCommentLine -replace '^\$origin\s*', '').Trim()

                # If the current origin isn't a single dot, add a prefix dot so that other host names are added in properly and won't merge with non dot origins.
                if ($CurrentOrigin -ne '.') { $CurrentOrigin = '.' + $CurrentOrigin }

                # Write verbose info to console
                Write-Verbose -Message 'Changed current origin to:'
                Write-Verbose -Message $CurrentOrigin

                # Move onto the next line
                continue
            }
            elseif ($NoCommentLine -like '`$TTL*') {
                # If the line is a TTL command

                # Remove the TTL prefix, any trailing white space, and set the current TTL to the computed TTL
                $CurrentTTL = ($NoCommentLine -replace '^\$TTL\s*', '').Trim()

                # Write verbose info to console
                Write-Verbose -Message 'Changed current TTL to:'
                Write-Verbose -Message $CurrentTTL

                # Move onto the next line
                continue
            }
            elseif ($NoCommentLine -match '^(?<CurrentHost>[\w\-.]+)') {
                # Capture the current host value and set the current host value to the current host record
                $CurrentHost = $Matches.CurrentHost

                # Write verbose info to console
                Write-Verbose -Message 'Changed current host to:'
                Write-Verbose -Message $CurrentHost
            }

            # Get the info about the current line being operated so that the matches auto var gets populated on and silence the boolean output
            $NoCommentLine -match '(?<=(?<Class>IN|CH|HS)?\s+)(?<Type>SOA|A|AAAA|CNAME|CAA|MX|NS|TXT|SRV|PTR)(?=\s+)' | Out-Null

            # Set the current class to match the current line's current class. If nothing is defined default to IN as that is the BIND behavior.
            if ($null -eq $Matches.Class) { [System.String]$CurrentClass = 'IN' } else { [System.String]$CurrentClass = $Matches.Class }

            # Check to see if the SOA is in parentheses mode
            if ($InParentheses) {
                # Check to make sure the data is in the correct format
                if ($NoCommentLine -match '(?<=\s+|^)(?<SOAValue>[0-9smhdw]+)') {
                    # Capture all matches, not just the first
                    [System.Text.RegularExpressions.Match[]]$RegexMatchList = [regex]::Matches($NoCommentLine, '(?<=\s+|^)(?<SOAValue>[0-9smhdw]+)', 'IgnoreCase')

                    # Write verbose info to console
                    Write-Verbose -Message 'SOA Config Matches:'
                    foreach ($Value in $RegexMatchList) { Write-Verbose -Message $Value.Value }

                    # Add the current matches to the SOA config
                    $SOAConfig += $Value.Value
                }

                # Check to see if the line in question also is the end of the parentheses set
                if ($NoCommentLine.Trim() -like '*)*') {
                    # Disable parentheses mode
                    $InParentheses = $false

                    # Write verbose info to console
                    Write-Verbose -Message 'Changed parentheses mode to:'
                    Write-Verbose -Message $InParentheses

                    # Set the parameters of the new DNS record function in a hashtable for splatting
                    [System.Collections.Hashtable]$ParamSplat = @{
                        Type              = 'SOA'
                        Class             = $SoaClass
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
                    Write-Verbose -Message 'List of Records for the current zone:'
                    foreach ($Record in $RecordList) { Write-Verbose -Message $Record }
                }

                # Continue to the next line
                continue
            }

            # Check for the type of the resource record being used
            switch ($Matches.Type) {
                'SOA' {
                    # Get the SOA Server and the SOA Contact info from the SOA record and silently continue
                    $NoCommentLine -match '^.*(?<=SOA)\s+(?<primaryServer>[\w\.]+)\s+(?<contact>[\w\.]+)(?:\s+\(?\s*)(?<Serial>\d+)?(?:\s+)?(?<Refresh>\d+)?(?:\s+)?(?<Retry>\d+)?(?:\s+)?(?<Expire>\d+)?(?:\s+)?(?<Minimum>\d+)?(?:\s*\)?)?$' | Out-Null

                    # Set the SOA settings to be consumed by the DNS record builder for SOA records
                    [System.String]$SoaPrimaryServer = $Matches.primaryServer
                    [System.String]$SoaContact = $Matches.contact

                    # Set the SOA's class type
                    $SoaClass = $CurrentClass

                    # Cascade through the SOA config if present and set the settings if the previous setting is present
                    if ($Matches.Serial) {
                        $SoaConfig += $Matches.Serial
                        if ($Matches.Refresh) {
                            $SoaConfig += $Matches.Refresh
                            if ($Matches.Retry) {
                                $SoaConfig += $Matches.Retry
                                if ($Matches.Expire) {
                                    $SoaConfig += $Matches.Expire
                                    if ($Matches.Minimum) {
                                        $SoaConfig += $Matches.Minimum
                                    }
                                }
                            }
                        }
                    }

                    if ($SoaConfig.Length -eq 5) {
                        # Set the parameters of the new DNS record function in a hashtable for splatting
                        [System.Collections.Hashtable]$ParamSplat = @{
                            Type              = 'SOA'
                            Class             = $SoaClass
                            HostName          = "$($CurrentHost + $CurrentOrigin)"
                            TTL               = $CurrentTTL
                            PrimaryNameServer = $SoaPrimaryServer
                            ZoneContact       = $SoaContact
                            Serial            = $SoaConfig[0]
                            Refresh           = $SoaConfig[1]
                            Retry             = $SoaConfig[2]
                            Expire            = $SoaConfig[3]
                            Minimum           = $SoaConfig[4]
                        }

                        # Create the new DNS Record object
                        $RecordList += New-DNSRecord @ParamSplat

                        # Write verbose info to console
                        Write-Verbose -Message 'List of Records for the current zone:'
                        foreach ($Record in $RecordList) { Write-Verbose -Message $Record }
                        
                        # Check parentheses mode toggling
                    }
                    elseif ($NoCommentLine -like '*(*') {
                        # if a line triggers a parentheses set
                        # Enable parentheses mode
                        $InParentheses = $true

                        # Write verbose info to console
                        Write-Verbose -Message 'Changed parentheses mode to:'
                        Write-Verbose -Message $InParentheses


                        # Check to see if the line in question also is the end of the parentheses set
                        if ($NoCommentLine -like '*)*') {
                            # Disable parentheses mode
                            $InParentheses = $false

                            # Write verbose info to console
                            Write-Verbose -Message 'Changed parentheses mode to:'
                            Write-Verbose -Message $InParentheses

                            # Set the parameters of the new DNS record function in a hashtable for splatting
                            [System.Collections.Hashtable]$ParamSplat = @{
                                Type              = 'SOA'
                                Class             = $SoaClass
                                HostName          = "$($CurrentHost + $CurrentOrigin)"
                                TTL               = $CurrentTTL
                                PrimaryNameServer = $SoaPrimaryServer
                                ZoneContact       = $SoaContact
                                Serial            = $SoaConfig[0]
                                Refresh           = $SoaConfig[1]
                                Retry             = $SoaConfig[2]
                                Expire            = $SoaConfig[3]
                                Minimum           = $SoaConfig[4]
                            }

                            # Create the new DNS Record object
                            $RecordList += New-DNSRecord @ParamSplat

                            # Write verbose info to console
                            Write-Verbose -Message 'List of Records for the current zone:'
                            foreach ($Record in $RecordList) { Write-Verbose -Message $Record }
                        }
                    }
                }
                'A' {
                    # Run a match on the current line
                    $NoCommentLine -match '(?<=(?:IN|HS|CH)?\s+A\s+)(?<Value>[\w+\.]+)' | Out-Null

                    # Write verbose info to console
                    Write-Verbose -Message 'Current A record IP matches:'
                    Write-Verbose -Message $Matches.value

                    # Create the A record in the record list
                    $RecordList += New-DNSRecord -Type 'A' -Class $CurrentClass -HostName ($CurrentHost + $CurrentOrigin) -TTL $CurrentTTL -IP $Matches.Value
                }
                'AAAA' {
                    # Run a match on the current line
                    $NoCommentLine -match '(?<=(?:IN|HS|CH)?\s+AAAA\s+)(?<Value>[\w+\.]+)' | Out-Null

                    # Write verbose info to console
                    Write-Verbose -Message 'Current AAAA record IP matches:'
                    Write-Verbose -Message $Matches.value

                    # Create the AAAA record in the record list
                    $RecordList += New-DNSRecord -Type 'AAAA' -Class $CurrentClass -HostName ($CurrentHost + $CurrentOrigin) -TTL $CurrentTTL -IP $Matches.Value
                }
                'CNAME' {
                    # Run a match on the current line
                    $NoCommentLine -match '(?<=(?:IN|HS|CH)?\s+CNAME\s+)(?<Value>[\w+-\.]+)' | Out-Null

                    # Write verbose info to console
                    Write-Verbose -Message 'Current CNAME value matches:'
                    Write-Verbose -Message $Matches.value

                    # Create the CNAME record in the record list
                    $RecordList += New-DNSRecord -Type 'CNAME' -Class $CurrentClass -HostName ($CurrentHost + $CurrentOrigin) -TTL $CurrentTTL -Value $Matches.Value
                }
                'CAA' {
                    # Get the CAA Resource Record's configs
                    [System.Text.RegularExpressions.Match[]]$RegexMatchList = [regex]::Matches($NoCommentLine, "(?<=(?:IN|HS|CH)?\s+CAA\s+)(?<Value>[\w+\.]+)(?:\s+)(?<Type>\w+)(?:\s+\`")(?<Target>.+)(?:\`")", 'IgnoreCase')

                
                    # Set the SOA settings to be consumed by the DNS record builder for SOA records
                    [System.String]$CaaValue = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq 'Value' }).Value
                    [System.String]$CaaType = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq 'Type' }).Value
                    [System.String]$CaaTarget = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq 'Target' }).Value

                    # Create the CAA record in the zone's record list
                    $RecordList += New-DNSRecord -Type 'CAA' -Class $CurrentClass -HostName ($CurrentHost + $CurrentOrigin) -TTL $CurrentTTL -Flag $CaaValue -Tag $CaaType -Value $CaaTarget
                }
                'MX' {
                    # Get the MX Resource Record's configs
                    [System.Text.RegularExpressions.Match[]]$RegexMatchList = [regex]::Matches($NoCommentLine, '(?<=(?:IN|HS|CH)?\s+MX\s+)(?<Priority>[\d+]+)(?:\s+)(?<Value>\S+)', 'IgnoreCase')

                
                    # Set the MX settings to be consumed by the DNS record builder for MX records
                    [System.String]$MxPriority = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq 'Priority' }).Value
                    [System.String]$MxValue = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq 'Value' }).Value
                        
                    # Create the MX record in the zone's record list
                    $RecordList += New-DNSRecord -Type 'MX' -Class $CurrentClass -HostName ($CurrentHost + $CurrentOrigin) -TTL $CurrentTTL -Priority $MxPriority -Value $MxValue
                }
                'NS' {
                    # Run a match on the current line
                    $NoCommentLine -match '(?<=(?:IN|HS|CH)?\s+NS\s+)(?<Value>[\w+-\.]+)' | Out-Null

                    # Write verbose info to console
                    Write-Verbose -Message 'Current NS value matches:'
                    Write-Verbose -Message $Matches.value
                                                
                    # Create the NS record in the record list
                    $RecordList += New-DNSRecord -Type 'NS' -Class $CurrentClass -HostName ($CurrentHost + $CurrentOrigin) -TTL $CurrentTTL -Value $Matches.Value 
                }
                'TXT' {
                    # Run a match on the current line
                    $NoCommentLine -match "(?<=(?:IN|HS|CH)?\s+TXT\s+\`")(?<Value>.+)(?:\`")" | Out-Null

                    # Write verbose info to console
                    Write-Verbose -Message 'Current TXT value matches:'
                    Write-Verbose -Message $Matches.value
                        
                    # Create the TXT record in the record list
                    $RecordList += New-DNSRecord -Type 'TXT' -Class $CurrentClass -HostName ($CurrentHost + $CurrentOrigin) -TTL $CurrentTTL -Value $Matches.Value
                }
                'SRV' {
                    # Get the SRV Resource Record's configs
                    [System.Text.RegularExpressions.Match[]]$RegexMatchList = [regex]::Matches($NoCommentLine, '(?<=(?:IN|HS|CH)?\s+SRV\s+)(?<Priority>[\d+]+)(?:\s+)(?<Weight>\d+)(?:\s+)(?<Port>\d+)(?:\s+)(?<Target>\S+)', 'IgnoreCase')

                    # Set the SRV settings to be consumed by the DNS record builder for SRV records
                    [System.String]$SrvPriority = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq 'Priority' }).Value
                    [System.String]$SrvWeight = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq 'Weight' }).Value
                    [System.String]$SrvPort = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq 'Port' }).Value
                    [System.String]$SrvTarget = ($RegexMatchList.Groups | Where-Object -FilterScript { $_.Name -eq 'Target' }).Value
                                                
                    # Create the SRV record in the zone's record list
                    $RecordList += New-DNSRecord -Type 'SRV' -Class $CurrentClass -HostName ($CurrentHost + $CurrentOrigin) -TTL $CurrentTTL -Priority $SrvPriority -Weight $SrvWeight -Port $SrvPort -Value $SrvTarget
                }
                'PTR' {
                    # Run a match on the current line
                    $NoCommentLine -match '(?<=(?:IN|HS|CH)?\s+PTR\s+)(?<Value>[\w+-\.]+)' | Out-Null

                    # Write verbose info to console
                    Write-Verbose -Message 'Current PTR value matches:'
                    Write-Verbose -Message $Matches.value
                                                                        
                    # Create the PTR record in the record list
                    $RecordList += New-DNSRecord -Type 'PTR' -Class $CurrentClass -HostName ($CurrentHost + $CurrentOrigin) -TTL $CurrentTTL -Value $Matches.Value 
                        
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