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
    You can use this to target an alternative domain, e.g. you are in fabricam and you need to target contoso.
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
    # Specifies a path to one or more locations.
    [Parameter(Mandatory = $false,
        Position = 1,
        ParameterSetName = "CLI",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "Domain controller to connect to")]
    [Alias("ComputerName","MachineName")]
    [ValidateNotNullOrEmpty()]
    [string]$Server,
    # Column name to copy to destination CSV file.
    [Parameter(Mandatory = $false,
        Position = 2,
        ParameterSetName = "CLI",
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "Connect to a global catalog domain controller")]
    [switch]$GlobalCatalog
)

# Temporary code storage
# Build search string: $searchString = "(&(objectClass=user)(objectCategory=person)(SAMAccountName=$user))"
# AD user property to retrieve and compare against: MSDS-UserPasswordExpireyTimeComputed

function Connect-ADSIDomain {
    <#
    .SYNOPSIS
        Creates an Active Directory Domain Connection using .Net
    .DESCRIPTION
        Creates an active directory domain connection.
        By default it uses the current user and computer's context to establish this connection.
        This can be overridden by the "Server" parameter. 
    .EXAMPLE
        PS C:\> <example usage>
        blah
    .INPUTS
        String
    .OUTPUTS
        System.DirectoryServices.DirectoryEntry
    .NOTES
        Uses native .Net ADSI to connect to create the directory connection.
    #>
    param (
    # Domain Controller/Domain option
    [Parameter(Mandatory = $false,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "ADSI Domain Connection (.Net)")]
    [Alias("Domain", "ComputerName")]
    [String]$Server = ""
    )
    
    # ToDo: Auto convert dot style DN to LDAP style DN
    # https://stackoverflow.com/questions/4620717/convert-domain-name-to-ldap-style-in-net
    
    # Create and populate the connection string
    $ConnectionString = ""

    # connect to the current domain
    $DomainConnectionInstance = [ADSI]$ConnectionString
    return $DomainConnectionInstance
}

# Define the search function
function Search-DomainUser {
    <#
    .SYNOPSIS
        blah
    .DESCRIPTION
        blah
    .EXAMPLE
        PS C:\> <example usage>
        blah
    .INPUTS
        blah
    .OUTPUTS
        blah
    .NOTES
        blah
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

    # Configure the searcher filter (search parameters)
    $DirectorySearcher.Filter = ""

    # Run the search query and store the results
    $SearchResults = $DirectorySearcher.FindAll()

    Write-Host $SearchResults
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
        Mandatory = $false,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "DNS style FQDN to be converted to LDAP style FQDN"
    )]
    [Alias("Name","Server")]
    [String]$DotDomain

    # Instantiate a directory context 
    $DirectoryContext = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new([System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Domain, $DotDomain)
    $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DirectoryContext)
    $DirectoryEntry = $Domain.GetDirectoryEntry()
    $Results = $DirectoryEntry.distinguishedName
    return $Results
}
