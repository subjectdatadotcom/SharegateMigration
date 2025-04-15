# Import the ShareGate module
Import-Module Sharegate

# Define the path to the CSV file containing user and group mappings
$csvFile = "$MyDir\usermappings.csv"
Write-Host $csvFile
try {
    # Import the CSV file into a table variable, specifying the delimiter as a comma
    $table = Import-CSV $csvFile -Delimiter ","

    # Create a new mapping settings object to store user and group mappings
    $mappingSettings = New-MappingSettings

    # Loop through each row in the imported CSV table
    foreach ($row in $table) {
        # Set user and group mappings for each row in the CSV file
        $results = Set-UserAndGroupMapping -MappingSettings $mappingSettings -Source $row.SourceValue -Destination $row.DestinationValue
    
        # Output the source value for each row (for debugging or tracking purposes)
        $row.SourceValue
    }

    # Export the user and group mappings to a file
    Export-UserAndGroupMapping -MappingSettings $mappingSettings -Path "$MyDir\usermappings.sgum"
}
catch {
    Write-Host "User mappings file already exists" -ForegroundColor Magenta
}
