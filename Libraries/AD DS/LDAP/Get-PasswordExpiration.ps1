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
    Thsi script is not compatible with .Net Core.
.LINK
    https://github.com/elliot-labs/PowerShell-Doodads
#>

# Add command line switch/flag support.
# Each parameter is detailed in the above help documentation.
[OutputType([System.DateTime])]
param(
    # Specifies a path to a location.
    [Parameter(Mandatory = $false,
        Position = 0,
        ParameterSetName = "CLI",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "Username to search")]
    [Alias("Name")]
    [ValidateNotNullOrEmpty()]
    [string]$User = $env:USERNAME,
    # Specifies a path to one or more locations
    [Parameter(Mandatory = $false,
        Position = 1,
        ParameterSetName = "CLI",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "Domain controller to connect to")]
    [Alias("ComputerName", "MachineName", "Domain")]
    [ValidateNotNullOrEmpty()]
    [string]$Server,
    # Column name to copy to destination CSV file
    [Parameter(Mandatory = $false,
        Position = 2,
        ParameterSetName = "CLI",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "Connect to a global catalog domain controller")]
    [switch]$GlobalCatalog,
    # Allow the library to be used as a standalone command line application
    [Parameter(Mandatory = $false,
        Position = 3,
        ParameterSetName = "CLI",
        ValueFromPipeline = $false,
        HelpMessage = "Use this library standalone on the command line")]
    [switch]$CLIMode
)

# Define a function that will connect to the domain
function Connect-ADSIDomain {
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
        # Domain Controller/Domain option
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ADSI Domain Connection (.Net)")]
        [Alias("Server", "ComputerName")]
        [String]$Domain = ""
    )

    # Check to see if the Server is not provided, and if it is provided with dot syntax, convert it to the proper syntax.
    if (("" -ne $Domain) -and ($Domain -like "*.*")) {
        $ConnectionString = ConvertTo-LDAPDomain -DotDomain $Domain
    } elseif ("" -eq $Domain) {
        $ConnectionString = ""
    } else {
        # Create and populate the connection string
        $ConnectionString = "LDAP://$Domain"
    }

    # connect to the current domain
    $DomainConnectionInstance = [ADSI]$ConnectionString
    Return $DomainConnectionInstance
}

# Define the search function
function Get-PwdExpirationTime {
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
    .OUTPUTS
        System.DateTime
    .NOTES
        .Net framework is required, .Net Core is not supported.
    #>
    param (
        # Domain Connection
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ADSI Domain Connection (.Net)")]
        [Alias("Domain", "Server")]
        [System.DirectoryServices.DirectoryEntry]$DomainConnection = [ADSI]""
    )

    # Create a directory searcher
    $DirectorySearcher = [ADSISearcher]$DomainConnection

    # Specify the property that needs retrieved from AD
    $DirectorySearcher.PropertiesToLoad.Add('msDS-UserPasswordExpiryTimeComputed') | Out-Null
    
    # Build a search string and store it into a variable
    $SearchString = "(&(objectClass=user)(objectCategory=person)(SAMAccountName=$user))"

    # Configure the searcher filter (search parameters)
    $DirectorySearcher.Filter = $SearchString

    # Search the Directory for a single user
    $UserInstance = $DirectorySearcher.FindOne()

    # Isolate a single user, the first instance in the results
    $SingleUser = $UserInstance[0]

    # Extract the password expiration time from the single user
    $SearchTime = $SingleUser.Properties['msDS-UserPasswordExpiryTimeComputed']

    # Convert the SearchResult's time to a string and cast that into a standard DateTime format.
    $Time = [DateTime]::FromFileTime([string]$SearchTime)

    # Return the time results
    Return $Time
}

# Create the LDAP domain conversion function
function ConvertTo-LDAPDomain {
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
    
    # Define the DNS FQDN parameter to be converted to LDAP FQDN
    [Parameter(
        Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "DNS style FQDN to be converted to LDAP style FQDN"
    )]
    [Alias("Name", "Server")]
    [String]$DotDomain

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

# Allow this library to be used in a standalone mode as a command line application
if ($CLIMode) {
    # Connect to the domain and store the connection instance
    $DomainInstance = Connect-ADSIDomain

    # Use the connection instance to retrieve the current user's password expiration time
    Return Get-PwdExpirationTime -DomainConnection $DomainInstance
}
