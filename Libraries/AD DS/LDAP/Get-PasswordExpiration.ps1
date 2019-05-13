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
[OutputType([String])]
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
    [Alias("ComputerName")]
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
    [Alias("Domain, ComputerName")]
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
    [Alias("Domain, Server")]
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