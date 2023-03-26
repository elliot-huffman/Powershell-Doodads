<#
.SYNOPSIS
    A script to generate mock user data for the Privileged Security Management (MSM) application.
.DESCRIPTION
    The data generated is in the format of the MSM User object.
    The data can be generated in the context of the Data Access API or in the standard user management API context.
.PARAMETER Count
    Used to specify the number of user objects to be created in the JSON file
.PARAMETER DataAccess
    Used to flag the script to generate user objects in the context of the data access API
.PARAMETER Path
    Used to configure where the JSON file will be created.
    The output file will always be a text file with JSON content.
.EXAMPLE
    New-MsmUserObject.ps1
    Generates 50 user objects in the current working directory in a file named "MsmUserObjectList.json"
.EXAMPLE
    New-MsmUserObject.ps1 -Count 123
    Generates 123 user objects in a file that is located in the current working directory that is named "MsmUserObjectList.json"
.EXAMPLE
    New-MsmUserObject.ps1 -DataAccess
    Generates 50 user objects that all have a type of "unmanaged" in a file that is located in the current working directory that is named "MsmUserObjectList.json"
.EXAMPLE
    New-MsmUserObject.ps1 -Path "C:\UserObjectList.json"
    Generates 50 user objects in a file that is located in on the root of the "C:\" drive that is named "UserObjectList.json"
.EXAMPLE
    New-MsmUserObject.ps1 -Count 321 -Path "C:\UserObjectList.json" -DataAccess
    Generates 321 user objects with the context of the Data Access API located on the root of the "C:\" drive with the file name of "UserObjectList.json"
.INPUTS
    System.Int64
    System.String
    Switch
.OUTPUTS
    Void   
.LINK
    https://mootinc.com
#>

# Define the parameters of the script
param(
    [System.Int64]$Count = 50,
    [switch]$Unmanaged,
    [System.String]$Path = '.\MsmUserObjectList.json'
)

# Define the part of the script to be executed at the beginning of the pipeline collection
begin {
    # Define a list of first an last names
    $FirstName = 'Vern', 'Salvador', 'Brain', 'Dwight', 'Ryan', 'Jocelyn', 'Janette', 'Tara', 'Fritz', 'Jaime', 'Paulette', 'Cindy', 'Max', 'Johnathan', 'Freddy', 'Carmen', 'Darrel', 'Brock', 'Thanh', 'Sherri', 'Omer', 'Aida', 'Adrienne', 'Orval', 'Beulah', 'Luigi', 'Leanne', 'James', 'Miguel', 'Melinda', 'Carter', 'Virgilio', 'Korey', 'Fletcher', 'Minerva', 'Suzette', 'Joaquin', 'Rosie', 'Michal', 'Francesca', 'Brooke', 'Letha', 'Charlie', 'Columbus', 'Allyson', 'Wilbur', 'Cameron', 'Arturo', 'Deon', 'Sofia'
    $LastName = 'Crawford', 'Butler', 'Hester', 'French', 'Blevins', 'Riggs', 'Hughes', 'Maynard', 'Mercado', 'Fleming', 'Bean', 'Huffman', 'Wu', 'Dyer', 'Berger', 'Bates', 'Moses', 'Cherry', 'Rosales', 'Roman', 'Bender', 'Collier', 'Michael', 'Ferguson', 'Love', 'Dawson', 'Aguilar', 'Oliver', 'Montoya', 'Johns', 'Knapp', 'Ellis', 'Lambert', 'Ward', 'Wilkins', 'Fuentes', 'Romero', 'Estrada', 'Patterson', 'Frey', 'Merritt', 'Medina', 'Vasquez', 'Duarte', 'Massey', 'Fry', 'Schmidt', 'Reeves', 'Pitts', 'Waters'
    
    # Define the list of user types
    $UserTypeList = 'Privileged', 'Specialized', 'Enterprise'

    # Define a function that creates a MSM user object 
    function New-MsmUser {
        # Randomly select a first and last name
        $RandomFirst = Get-Random -InputObject $FirstName
        $RandomLast = Get-Random -InputObject $LastName

        # Create a MSM user object
        $UserObject = @{
            'Id'           = (New-Guid).Guid
            'Upn'          = "$RandomFirst.$RandomLast@example.com"
            'UniqueGroup'  = (New-Guid).Guid
            'DisplayName'  = "$RandomFirst $RandomLast"
            'FirstName'    = $RandomFirst
            'LastName'     = $RandomLast
            'CreationDate' = (Get-Date -Year 2023 -Day (Get-Random -Maximum 29 -Minimum 1) -Month (Get-Random -Minimum 1 -Maximum 12)).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            'UiEducation'  = Get-Random -InputObject $true, $false
        }

        # If data access mode is specified
        if ($Unmanaged) {
            # set all user types to unmanaged
            $UserObject['Type'] = 'Unmanaged'
            $UserObject['UniqueGroup'] = '00000000-0000-0000-0000-000000000000'
            $UserObject['UiEducation'] = $true
        } else {
            # Set the user type to a random value
            $UserObject['Type'] = Get-Random -InputObject $UserTypeList
        }

        # If the data access flag is not specified, generate privileged user objects
        if ($UserObject['Type'] -eq 'Privileged') {
            $UserObject.DisplayName = $UserObject.DisplayName + ' (Privileged)'
            $UserObject.Upn = 'priv-' + $UserObject.Upn
        }

        # Return the computed user object to the caller
        return $UserObject
    }
}

# Define the part of the script to be executed at the end of the pipeline object collection
end {
    # Generate the user objects and store them in an array
    [System.Object[]]$UserList = 1..$Count | ForEach-Object -Process { New-MsmUser }

    # Save the user objects to disk
    $UserList | ConvertTo-Json | Out-File -FilePath $Path
}