# Import ShareGate PowerShell Module
Import-Module Sharegate

$MyDir = "C:\Users\RB\Documents\SG_MigrationScripts"

.\SGUM_UserAndGroupMappings.ps1
#.\Creds.ps1


# Define paths
$sitesInputFile = $MyDir + "\sitemappings_batch1.csv"  # Path to site mappings csv input file
$sgumFile = $MyDir + "\spusermappings.sgum"  # Path to refer SGUM user mapping file
$batch = ([System.IO.Path]::GetFileNameWithoutExtension($sitesInputFile)) -split "_" | Select-Object -Last 1
$logFile = $MyDir + "\logs\$($batch)_migration_log.txt"  # Log file for tracking migrations

if (-not (Test-Path -Path "$MyDir\logs")) {
    New-Item -Path "$MyDir\logs" -ItemType Directory
}

# User input for Insane Mode or Normal Mode
$useInsaneMode = Read-Host "Do you want to use Insane Mode? (yes/no)"
$insaneMode = $false
if ($useInsaneMode.ToLower().Trim() -eq "yes") {
    $insaneMode = $true
}

# User input for Delta Migration
$performDelta = Read-Host "Do you want to perform a Delta Migration? (yes/no)"
$copySettings = New-CopySettings
if ($performDelta.ToLower().Trim() -eq "yes") {
    $copySettings = New-CopySettings -OnContentItemExists IncrementalUpdate
}

# User input for Pre-check
$runPreCheck = Read-Host "Do you want to run a Pre-check before migration? (yes/no)"
$preCheck = $false
if ($runPreCheck.ToLower().Trim() -eq "yes") {
    $preCheck = $true
}

# Import user mappings
$mappingSettings = New-MappingSettings
$mappingSettings = Import-UserAndGroupMapping -Path $sgumFile

# Read migration CSV
$sites = Import-Csv -Path $sitesInputFile -Delimiter "," 

# Loop through each site in CSV
if(([String]::IsNullOrWhiteSpace($SourceConn))) {
    Write-Host "No connection to Source"
    $SourceConn = ""
}

if(([String]::IsNullOrWhiteSpace($TargetConn))) {
    Write-Host "No connection to Target"
    $TargetConn = ""
}

foreach ($site in $sites) {
#$site = $sites[0]
    $sourceSiteURL = $site.SourceSiteURL.Trim()
    $targetSiteURL = $site.TargetSiteURL.Trim()
    $listNames = $site.ListName # Can be empty or contain list names separated by "|"

    Write-Host "Starting migration for $sourceSiteURL -> $targetSiteURL" -ForegroundColor Green
    Add-Content -Path $logFile -Value "Starting migration for $sourceSiteURL -> $targetSiteURL"
    #Clear-Variable $srcSite
    #Clear-Variable $dstSite

    # Connect to source and target sites
    if([String]::IsNullOrWhiteSpace($SourceConn)) {
        $SourceConn = Connect-Site -Url $sourceSiteURL -Browser
        $srcSite = $SourceConn
    }
    else {
        $srcSite = Connect-Site -Url $sourceSiteURL -UseCredentialsFrom $SourceConn
    }

    if([String]::IsNullOrWhiteSpace($TargetConn)) {
        $TargetConn = Connect-Site -Url $targetSiteURL -Browser
        $dstSite = $TargetConn
    }
    else {
        $dstSite = Connect-Site -Url $targetSiteURL -UseCredentialsFrom $TargetConn
    }

    if (-not $srcSite -or -not $dstSite) {
        Write-Host "Error connecting to sites: $sourceSiteURL or $targetSiteURL" -ForegroundColor Red
        Add-Content -Path $logFile -Value "Error connecting to sites: $sourceSiteURL or $targetSiteURL"
        continue
    }
 
    # If specific lists are provided, only migrate those lists
    if ($listNames -and ($listnames -match '\S')) {
        $listsToMigrate = ($listNames -split "\|").Trim()  # Split list names if multiple lists are provided

        foreach ($list in $listsToMigrate) {
        #$list = $listsToMigrate
            Write-Host "Migrating list: $list from $sourceSiteURL to $targetSiteURL"
            Add-Content -Path $logFile -Value "Migrating list: $list from $sourceSiteURL to $targetSiteURL"

            # Get Source & Target List
            $srcList = Get-List -Name $list -Site $srcSite
            $dstList = Get-List -Name $list -Site $dstSite

            if ($preCheck) {
                # Perform a Pre-check
                Copy-Content -SourceList $srcList -DestinationList $dstList -MappingSettings $mappingSettings -CopySettings $copySettings -WhatIf
            } else {
                # Perform Actual Content Migration
                Copy-List -List $srcList -DestinationSite $dstSite -MappingSettings $mappingSettings
                # Copy-Content -SourceList $srcList -DestinationList $dstList -MappingSettings $mappingSettings -CopySettings $copySettings
                Copy-ObjectPermissions -Source $srcSite -Destination $dstSite -MappingSettings $mappingSettings
            }
        }
    } 
    else {
        # If no list is specified, perform full site migration
        Write-Host "Performing full site migration from $sourceSiteURL to $targetSiteURL"
        Add-Content -Path $logFile -Value "Performing full site migration from $sourceSiteURL to $targetSiteURL"

        if ($preCheck) {
            # Pre-check mode (WhatIf)
            Copy-Site -Site $srcSite -DestinationSite $dstSite -MappingSettings $mappingSettings -CopySettings $copySettings -WhatIf
        } 
        else {
            # Perform Full Site Migration with Insane Mode or Normal Mode
            if ($insaneMode) {
                Copy-Site -Site $srcSite -DestinationSite $dstSite -MappingSettings $mappingSettings -CopySettings $copySettings -InsaneMode -Merge -Subsites
                Copy-ObjectPermissions -Source $srcSite -Destination $dstSite -MappingSettings $mappingSettings
            } 
            else {
                Copy-Site -Site $srcSite -DestinationSite $dstSite -MappingSettings $mappingSettings -Merge -CopySettings $copySettings -Subsites
                Copy-ObjectPermissions -Source $srcSite -Destination $dstSite -MappingSettings $mappingSettings
            }
        }
    }

    Write-Host "Migration completed for $sourceSiteURL -> $targetSiteURL" -ForegroundColor Cyan
    Add-Content -Path $logFile -Value "Migration completed for $sourceSiteURL -> $targetSiteURL"
}

Write-Host "Migration process completed! Logs saved to: $logFile" -ForegroundColor Green


