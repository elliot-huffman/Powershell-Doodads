$Name = Import-Csv -Path '.\Master Folder List.csv'

Function New-Folders ($EntityType, $ParentFolderName, $TargetYear) {
    New-Item -Path ".\output\$EntityType\$ParentFolderName\$TargetYear\Compliance" -ItemType "directory" -ErrorAction Stop -Force
    New-Item -Path ".\output\$EntityType\$ParentFolderName\$TargetYear\Financial Statement" -ItemType "directory" -ErrorAction Stop -Force
    New-Item -Path ".\output\$EntityType\$ParentFolderName\$TargetYear\Tax Return" -ItemType "directory" -ErrorAction Stop -Force
    New-Item -Path ".\output\$EntityType\$ParentFolderName\$TargetYear\Unfiled" -ItemType "directory" -ErrorAction Stop -Force
}

foreach ($Line in $Name) {
    if ($Line.Name.contains("/") -or $Line.Name.contains("\") -or $Line.Name.contains(":") -or $Line.Name.contains("*") -or $Line.Name.contains("?") -or $Line.Name.contains('"') -or $Line.Name.contains("<") -or $Line.Name.contains(">") -or $Line.Name.contains("|")) {
        "Skipped $($Line.Name) due to invalid character" | Out-File -FilePath "Skipped.log" -Append
    }
    else {
        New-Folders -EntityType $Line."Entity Type" -ParentFolderName $Line.Name.TrimStart("0","1","2","3","4","5","6","7","8","9"," ") -TargetYear "2013"
        New-Folders -EntityType $Line."Entity Type" -ParentFolderName $Line.Name.TrimStart("0","1","2","3","4","5","6","7","8","9"," ") -TargetYear "2014"
        New-Folders -EntityType $Line."Entity Type" -ParentFolderName $Line.Name.TrimStart("0","1","2","3","4","5","6","7","8","9"," ") -TargetYear "2015"
        New-Folders -EntityType $Line."Entity Type" -ParentFolderName $Line.Name.TrimStart("0","1","2","3","4","5","6","7","8","9"," ") -TargetYear "2016"
        New-Folders -EntityType $Line."Entity Type" -ParentFolderName $Line.Name.TrimStart("0","1","2","3","4","5","6","7","8","9"," ") -TargetYear "2017"
    }    
}