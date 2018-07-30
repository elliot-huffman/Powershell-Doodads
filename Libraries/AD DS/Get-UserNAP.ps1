<#
.SYNOPSIS
Get the dial in Network Access Permission in property of a user.
.DESCRIPTION
This script retrieves the Network Access Permission of a user from an active directory database.
Users can be specified and the name of the server can also be specified.
By default the script retrieves the current logged in user as the user name to search.
It also grabs the domain of the current user as the server to connect to.
.PARAMETER User
If specified, the username to search on the AD instance.
If not specified then it will use the currently logged in user's username as the user to run the query upon.
.PARAMETER Domain
If specified, the domain/server to search for the user in.
If you specify the name of the domain, DNS will return the name of the server that the script will query.
If you specify the name of the server it will bypass the DNS's best judgement and allow you a direct connection to the server of your choice.
If not specified, then the script will retrieve the domain name that the computer says that the currently logged in user is a member of.
.EXAMPLE
Get-UserNAP
This will get the currently logged in user name and the domain that the computer says that the user is in.
It will then run a search on the specified domain and return the NAP status of the user in integer form or $false if there is an unknown state.
.EXAMPLE
Get-UserNAP -User "usernamehere"
This will get the specified user and the domain that the computer says that the current user is in (currently logged in user, not the specified user).
It will then run a search on the specified domain and return the NAP status of the user in integer form or $false if there is an unknown state.
.EXAMPLE
Get-UserNAP -Domain "contoso.com"
This will get the currently logged in user name and run a query on the domain that was specified.
It will then run a search on the specified domain and return the NAP status of the user in integer form or $false if there is an unknown state.
.EXAMPLE
Get-UserNAP -Domain "dc01.contoso.com"
This will get the currently logged in user name and run a query on the name of the server that was specified.
It will then run a search on the specified domain and return the NAP status of the user in integer form or $false if there is an unknown state.
.EXAMPLE
Get-UserNAP -User "usernamehere" -Domain "contoso.com"
This will run a search for the user that was specified on the domain that was also specified.
It will then run a search on the specified domain and return the NAP status of the user in integer form or $false if there is an unknown state.
.NOTES
RSAT's Active directory powershell needs to be installed and enabled for this script to work.
Domain controller connectivity needs to be present for the Active Directory searches to be successful.
Results:
0 = Network Access Permission Denied
1 = Full access granted
2 = managed through NPS policy
$false = unknown Network Access Permission state
.LINK
https://github.com/elliot-labs/Powershell-Doodads
#>

# Allow command line automation.
param([string]$User = $env:USERNAME, [string]$Domain=$env:USERDOMAIN)

# Run everything in a try-catch block to grab errors and return coherent error messages.
try {
    # Run a search on the specified AD user on the specified domain controller.
    # Filter the results to only the NPS property and dropping the rest.
    # Remove the headers on the table to streamline the text.
    # Convert the output to a string.
    $Results = Get-ADUser -Properties "msNPAllowDialin" -Identity $User -Server $Domain | Select-Object -Property "msNPAllowDialin" | Format-Table -HideTableHeaders | Out-String
    # Remove the whitespace around the string to simplify it.
    $Results = $Results.Trim()
    # Filter the output into diffrent categories.
    switch ($Results) {
        # If the returned value is false, write the output of the int 0.
        "FALSE" {
            Write-Output -InputObject 0
        }
        # If the returned value is true, write the output of the int 1.
        "TRUE" {
            Write-Output -InputObject 1
        }
        # If the returned value is blank, write the output of the int 2.
        "" {
            Write-Output -InputObject 2
        }
        # Otherwise just output false if the output is not known.
        Default {
            Write-Output $false
        }
    }
# If the queried user property is not known, throw an error.
} catch [System.ArgumentException] {
    Write-Error "Unknown property."
# If the spevified domain controller is not accessable, throw an error.
} catch [Microsoft.ActiveDirectory.Management.ADServerDownException] {
    Write-Error "Domain Controller not found."
# If the user can't be found, throw an error.
} catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    Write-Error "User not found."
}
