<#
.SYNOPSIS
    Retrieves the computed user password expatriation time.
.DESCRIPTION
    This library will retrieve the specified users current password expiration time, computed by AD DS.
    If no parameters are specified, it will automatically take the current user's domain and user account as the context.
    This script does not need to have the RSAT AD module installed and relies on the .net framework's ADSI and ADSISearcher namespaces.
.PARAMETER User
    This parameter is used to query a specific user account, the default is the current user context that is executing this library.
.PARAMETER Server
    The server parameter allows you to specify a target domain controller, by default it uses the current domain.
    You can use this to target an alternative domain, e.g. you are in Fabricam and you need to target Contoso.
    This may be useful if you need targeted debugging however it is inadvisable in most cases.
.PARAMETER GlobalCatalog
    This switch parameter will target a global catalog instead of a standard domain controller.
    This may be useful if you need targeted debugging however it is inadvisable in most cases.
.EXAMPLE
    Todo:
    Fill out examples after script logic is built.
.INPUTS
    Todo:
    Fill out examples after script logic is built.
.OUTPUTS
    System.DateTime
.NOTES
    This script is able to operate without the RSAT Active Directory Powershell modules.
    This script requires .Net with the ADSI libraries to be available.
    This script is not compatible with .Net Core.
.LINK
    https://github.com/elliot-labs/PowerShell-Doodads
#>

#requires -PSEdition Desktop

# Add command line parameter/argument support.
# Each parameter is detailed in the above help documentation.
[OutputType([System.DateTime])]
param(
    # Accepts a username to query in Active Directory
    [Parameter(
        Mandatory = $false,
        Position = 0,
        ParameterSetName = "CLI",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [Alias("Name")]
    [ValidateNotNullOrEmpty()]
    [string]$User = $env:USERNAME,
    # Domain to run the search against
    # Accepts a domain name, LDAP or DNS
    [Parameter(
        Mandatory = $false,
        Position = 1,
        ParameterSetName = "CLI",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [Alias("LDAPDomain","DNSDomain")]
    [ValidateNotNullOrEmpty()]
    [string]$Domain = "",
    # Accepts custom input for a domain controller to connect to
    [Parameter(
        Mandatory = $false,
        Position = 2,
        ParameterSetName = "CLI",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true
    )]
    [Alias("Server", "MachineName", "DomainController")]
    [ValidateNotNullOrEmpty()]
    [string]$ComputerName,
    # Connect to a global catalog domain controller if specified
    [Parameter(
        Mandatory = $false,
        Position = 3,
        ParameterSetName = "CLI",
        ValueFromPipeline = $false
    )]
    [switch]$GlobalCatalog,
    # Allow the library to be used as a standalone command line application
    [Parameter(
        Mandatory = $false,
        Position = 4,
        ParameterSetName = "CLI",
        ValueFromPipeline = $false
    )]
    [switch]$CLIMode
)

# Define a function that will connect to the domain
Function Connect-ADSIDomain {
    <#
    .SYNOPSIS
        Creates an Active Directory Domain Connection using .Net
    .DESCRIPTION
        Creates an active directory domain connection.
        By default it uses the current user and computer's context to establish this connection.
        This can be overridden by the "Server" parameter. 
    .EXAMPLE
        PS C:\> Connect-ADSIDomain
        Connects to the current domain and return an instance of the connection.
    .EXAMPLE
        PS C:\> Connect-ADSIDomain -Domain "contoso.com"
        Converts the DNS FQDN into an LDAP FQDN and uses that as the connection string for the custom domain and returns a domain connection instance.
    .EXAMPLE
        PS C:\> Connect-ADSIDomain -Domain "DC=contoso,DC=com"
        Connects to the specified domain and returns a connection instance.
    .INPUTS
        String
    .OUTPUTS
        System.DirectoryServices.DirectoryEntry
    .NOTES
        Uses native .Net ADSI to connect to create the directory connection.
        .Net Core is not supported.
    #>
    param (
        # Use the specified connection string or default to the current system's config
        [Parameter(
            Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "LDAP domain connection string"
        )]
        [Alias("LDAPString")]
        [String]$ConnectionString = ""
    )

    # Connect to the current domain
    $DomainConnectionInstance = [ADSI]$ConnectionString

    # Return the ADSI domain connection
    Return $DomainConnectionInstance
}

# Define the search function
Function Get-PwdExpirationTime {
    <#
    .SYNOPSIS
        Retrieves a single user instance from Active Directory
    .DESCRIPTION
        Runs a search on active directory for a user person with a specific SAM account name.
        The msDS-UserPasswordExpiryTimeComputed property is added to the query for retrieval and is returned with the search result.
        Only the first results is retrieved and returned.
        The password expiration time is then extracted from the search result and converted into a standard System.DateTime and returned.
    .EXAMPLE
        PS C:\> Get-PwdExpirationTime -DomainConnection $DomainConnectionInstance
        Retrieves the current user's password expiration time and returns it as a DateTime object.
        E.G. 9/19/2018 9:19:29 AM
    .INPUTS
        Optional: System.DirectoryServices.DirectoryEntry
        Optional: String
    .OUTPUTS
        System.DateTime
    .NOTES
        .Net framework is required, .Net Core is not supported.
    #>
    param (
        # Domain Connection
        [Parameter(
            Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ADSI Domain Connection (.Net)"
        )]
        [Alias("Domain", "Server")]
        [System.DirectoryServices.DirectoryEntry]$DomainConnection = [ADSI]"",
        # User account to search in Active Directory
        [Parameter(
            Mandatory = $false,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "User to search in AD for"
        )]
        [Alias("UserName","SAMAccountName")]
        [String]$User = $env:USERNAME
    )

    # Create a directory searcher
    $DirectorySearcher = [ADSISearcher]$DomainConnection

    # Specify the property that needs retrieved from AD
    $DirectorySearcher.PropertiesToLoad.Add('msDS-UserPasswordExpiryTimeComputed') | Out-Null
    
    # Build a search string and store it into a variable
    $SearchString = "(&(objectClass=user)(objectCategory=person)(SAMAccountName=$User))"

    # Configure the searcher filter (search parameters)
    $DirectorySearcher.Filter = $SearchString

    # Search the Directory for a single user
    $UserInstance = $DirectorySearcher.FindOne()

    # Isolate a single user, the first instance in the results
    $SingleUser = $UserInstance[0]

    # Extract the password expiration time from the single user
    $SearchTime = $SingleUser.Properties['msDS-UserPasswordExpiryTimeComputed']

    # If the password does not expire, return a zero date. Otherwise, return the expiration time.
    if ($SearchTime -eq 9223372036854775807) {
        # return a 0 date (Monday, January 1, 0001 12:00:00 AM)
        Return 0 | Get-Date
    } else {
        # Convert the SearchResult's time to a string and cast that into a standard DateTime format.
        $Time = [DateTime]::FromFileTime([string]$SearchTime)
    
        # Return the time results
        Return $Time   
    }
}

# Create the LDAP domain conversion function
Function ConvertTo-LDAPDomain {
    <#
    .SYNOPSIS
        Converts DNS FQDN notation to LDAP FQDN notation.
    .DESCRIPTION
        Converts DNS FQDN notation to LDAP FQDN notation by using the .net Active Directory DirectoryContext class to dynamically convert syntax strategies.
        This works by creating a connection with the domain and using the context from the domain connection session to retrieve the new syntax.
    .EXAMPLE
        PS C:\> ConvertTo-LDAPDomain -DotDomain "corp.contoso.com"
        This function converts the DNS dot syntax to LDAP style "DC=corp,DC=contoso,DC=com"
    .INPUTS
        String
    .OUTPUTS
        String
    .NOTES
        Uses the .Net directory context for conversion.
        This requires a connection to the domain that you want to convert DNS to LDAP syntax.
    #>
    param(
        # Define the DNS FQDN parameter to be converted to LDAP FQDN
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "DNS style FQDN to be converted to LDAP style FQDN"
        )]
        [Alias("Name", "Server","Domain")]
        [String]$DotDomain
    )

    # Instantiate a directory context that is prepped with the dot syntax the user passed
    $DirectoryContext = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new([System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Domain, $DotDomain)

    # Connect into the domain and store the domain instance
    $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DirectoryContext)

    # Store the object instance of the directory meta data
    $DirectoryEntry = $Domain.GetDirectoryEntry()

    # Extract the LDAP FQDN into the results variable
    $Results = $DirectoryEntry.distinguishedName

    # Return the results variable
    return $Results
}

# Create the function that builds the connection string
Function Merge-ConnectionString {
    <#
    .SYNOPSIS
        Builds an LDAP connection string from the specified parameters
    .DESCRIPTION
        Intelligently builds an LDAP connection string from the specified parameters. Uses the LDAP provider for the directory entry object.
    .EXAMPLE
        PS C:\> Merge-ConnectionString -ComputerName "SomeServer" -Domain "DC=something,DC=com" -GlobalCatalog
        Returns the string "GC://SomeServer/DC=something,DC=com"
    .EXAMPLE
        PS C:\> Merge-ConnectionString -ComputerName "SomeServer" -Domain "DC=something,DC=com"
        Returns the string "LDAP://SomeServer/DC=something,DC=com"
    .EXAMPLE
        PS C:\> Merge-ConnectionString -Domain "contoso.com"
        Returns the string "LDAP://DC=contoso,DC=com"
    .EXAMPLE
        PS C:\> Merge-ConnectionString -Domain "contoso.com" -GlobalCatalog
        Returns the string "GC://DC=contoso,DC=com"
    .PARAMETER ComputerName
        This string parameter will insert a server name to connect to after the server type specifier.
        E.G. <type>://<ServerNameHere>/
        This parameter requires the use of the Domain name parameter.
        This parameter can accept NetBIOS names, IP Addresses and DNS dot style FQDNs.
    .PARAMETER Domain
        This string parameter add the domain to connect to at the end of the connection string.
        E.G. LDAP://DC=contoso,DC=com
        If the ComputerName or GlobalCatalog parameters are used, this parameter is required otherwise a malformed connection string will be built.
    .PARAMETER GlobalCatalog
        This switch parameter will build the connection string with a GC:// instead of an LDAP://.
    .INPUTS
        String
    .OUTPUTS
        String
    .NOTES
        Just string manipulation, nothing special here :-P
        If a DNS dot style FQDN is passed to this function, it will call the ConvertTo-LDAPDomain function to convert it to the appropriate format.
        Read https://docs.microsoft.com/en-us/dotnet/api/system.directoryservices.directoryentry for more info on the strings required for connectivity.
    #>

    param(
        # Specific domain controller/global catalog to connect to in the domain
        [Parameter(
            Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Server name to connect to in the domain (specific DC or GC)"
        )]
        [string]$ComputerName = "",
        # Domain to connect to
        [Parameter(
            Mandatory = $false,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Domain to connect to"
        )]
        [string]$Domain = "",
        # Option to connect to the global catalog if necessary

        # Temp storage for parameter set options
        # [Parameter(
        #     Mandatory = $false,
        #     Position = 2,
        #     ValueFromPipeline = $true,
        #     ValueFromPipelineByPropertyName = $true,
        #     ParameterSetName='ID',
        #     HelpMessage = "Specifies that a global catalog should be connected to"
        # )]
        [Parameter(
            Mandatory = $false,
            Position = 2,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Specifies that a global catalog should be connected to"
        )]
        [switch]$GlobalCatalog
    )

    # Build the base search string
    if ($GlobalCatalog) {
        $BaseSearchString = "GC://"
    } else {
        $BaseSearchString = "LDAP://"
    }

    # If there is data present on the server string, build the server string to include the appropriate syntax
    if ($ComputerName -ne "") {
        $ServerString = $ComputerName + "/"
    } else {
        $ServerString = ""
    }

    # Check to see if the Server is not provided, and if it is provided with dot syntax, convert it to the proper syntax
    if (($Domain -ne "") -and ($Domain -like "*.*")) {
        $DomainString = ConvertTo-LDAPDomain -DotDomain $Domain
    } elseif ("" -eq $Domain) {
        $DomainString = ""
    } else {
        $DomainString = $Domain
    }

    # If both the Server and the Domain strings are empty, set the base search string to be empty too to avoid connection issues
    if (($ServerString -eq "") -and ($DomainString -eq "")) {
        $BaseSearchString = ""
    }

    # Build the final connection string
    $FinalConnectionString = $BaseSearchString + $ServerString + $DomainString

    # Return the connection string
    Return $FinalConnectionString
}

# Allow this library to be used in a standalone mode as a command line application
if ($CLIMode) {
    # Build the connection string
    $ConnectionString = Merge-ConnectionString -ComputerName $ComputerName -Domain $Domain -GlobalCatalog:$GlobalCatalog
    
    # Connect to the domain and store the connection instance
    $DomainInstance = Connect-ADSIDomain -ConnectionString $ConnectionString

    # Use the connection instance to retrieve the current user's password expiration time
    Return Get-PwdExpirationTime -DomainConnection $DomainInstance
}

# ToDo:
# Add parameter sets to avoid parameter issues where some params are used and others are not.
# After parameter sets are set up properly, update all the help docs and comments.
# Add cmdlet binding
# Add parameter info to functions
