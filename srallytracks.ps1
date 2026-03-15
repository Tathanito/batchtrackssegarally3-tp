# SEGA Rally 3 Edition Generator
# Credits: Tathan (x.com/konotathan | tathan.moe)

$sourceRally = Read-Host "Enter the full path to your SEGA Rally 3 'Rally' folder"
$magiTracks = Read-Host "Enter the full path to your SEGA Rally Revo tracks folder"

# Validate paths
if (-not (Test-Path $sourceRally)) {
    Write-Host "Error: SEGA Rally 3 installation not found at '$sourceRally'. Exiting." -ForegroundColor Red
    exit
}

if (-not (Test-Path $magiTracks)) {
    Write-Host "Error: Revo tracks folder not found at '$magiTracks'. Exiting." -ForegroundColor Red
    exit
}

$baseDir = Split-Path $sourceRally -Parent
$originalTracksDir = "$sourceRally\Main_release\tracks"

if (-not (Test-Path $originalTracksDir)) {
    Write-Host "Error: Original tracks folder not found. Check your installation structure." -ForegroundColor Red
    exit
}

$editions = [ordered]@{
    "SEGA Rally 3 - Alpine Edition"       = @("alpine1", "alpine2", "alpine3", "alpine6", "alpine7")
    "SEGA Rally 3 - Arctic Edition"       = @("arctic1", "arctic2", "arctic3", "arctic6", "Arctic7")
    "SEGA Rally 3 - Canyon Edition"       = @("canyon1", "canyon2", "canyon3", "Canyon7")
    "SEGA Rally 3 - Master Edition"       = @("lakeside1")
    "SEGA Rally 3 - Safari Edition"       = @("safari1", "safari2", "safari3", "Safari6")
    "SEGA Rally 3 - Tropical Edition"     = @("tropical1", "tropical2", "tropical3")
    "SEGA Rally 3 - Tropical Edition 478" = @("tropical7", "tropical8")
}

$keepMatches = @{
    "Alpine"   = "Alpine4"
    "Canyon"   = "Canyon4"
    "Desert"   = "Desert4"
    "Lakeside" = "Lakeside4"
    "Master"   = "Lakeside4"
    "Stadium"  = "Stadium4"
    "Tropical" = "Tropical4"
}

$targetDefs = [ordered]@{
    "Alpine4"   = @{ Master = "alpine4"; Route = "alp_track_route4" }
    "Canyon4"   = @{ Master = "canyon4"; Route = "can_track_route4" }
    "Desert4"   = @{ Master = "desert4"; Route = "des_track_route4" }
    "Lakeside4" = @{ Master = "lakeside4"; Route = "lak_track_route4" }
    "Stadium4"  = @{ Master = "stadium4"; Route = "sta_track_route4" }
    "Tropical4" = @{ Master = "tropical4"; Route = "tro_track_route4" }
}

# Cleanup existing edition folders
foreach ($editionName in $editions.Keys) {
    $targetDir = "$baseDir\$editionName"
    if (Test-Path $targetDir) {
        Remove-Item -Path $targetDir -Recurse -Force
    }
}

# Generate new instances
foreach ($edition in $editions.GetEnumerator()) {
    $editionName = $edition.Name
    $sourceTracks = $edition.Value
    $targetDir = "$baseDir\$editionName"

    Write-Host "Building $editionName..." -ForegroundColor Cyan

    $null = New-Item -ItemType Directory -Force -Path "$targetDir\Main_release\tracks"

    # Link folders and copy files in root
    Get-ChildItem -Path $sourceRally | Where-Object Name -ne "Main_release" | ForEach-Object {
        if ($_.PSIsContainer) {
            $null = New-Item -ItemType SymbolicLink -Path "$targetDir\$($_.Name)" -Target $_.FullName -Force
        } else {
            Copy-Item -Path $_.FullName -Destination "$targetDir\$($_.Name)" -Force
        }
    }

    # Link folders and copy files in Main_release
    Get-ChildItem -Path "$sourceRally\Main_release" | Where-Object Name -ne "tracks" | ForEach-Object {
        if ($_.PSIsContainer) {
            $null = New-Item -ItemType SymbolicLink -Path "$targetDir\Main_release\$($_.Name)" -Target $_.FullName -Force
        } else {
            Copy-Item -Path $_.FullName -Destination "$targetDir\Main_release\$($_.Name)" -Force
        }
    }

    # Determine vanilla track to keep
    $keptTrack = $null
    foreach ($key in $keepMatches.Keys) {
        if ($editionName -match $key) {
            $keptTrack = $keepMatches[$key]
            break
        }
    }

    # Identify slots for new tracks
    $slotsToFill = @()
    foreach ($slot in $targetDefs.Keys) {
        if ($slot -ne $keptTrack) {
            $slotsToFill += $slot
        }
    }

    # Process track folder replacements
    Get-ChildItem -Path $originalTracksDir | ForEach-Object {
        $itemName = $_.Name

        if ($itemName -in $targetDefs.Keys) {
            if ($itemName -eq $keptTrack) {
                $null = New-Item -ItemType SymbolicLink -Path "$targetDir\Main_release\tracks\$itemName" -Target $_.FullName -Force
            } else {
                $slotIndex = [array]::IndexOf($slotsToFill, $itemName)
                
                if ($slotIndex -lt $sourceTracks.Count) {
                    $sourceTrackName = $sourceTracks[$slotIndex]
                    $sourceTrackDir = "$magiTracks\$sourceTrackName"
                    $newTrackDir = "$targetDir\Main_release\tracks\$itemName"
                    $null = New-Item -ItemType Directory -Force -Path $newTrackDir
                    
                    $sNameLower = $sourceTrackName.ToLower()
                    $sourceMasterPrefix = $sNameLower
                    $sourceRoutePrefix = $sNameLower.Substring(0,3) + "_track_route" + $sNameLower.Substring($sNameLower.Length - 1, 1)

                    $targetMasterPrefix = $targetDefs[$itemName].Master
                    $targetRoutePrefix = $targetDefs[$itemName].Route

                    # Copy and rename Revo track files
                    Get-ChildItem -Path $sourceTrackDir -File | ForEach-Object {
                        $newName = $_.Name -ireplace "^$sourceMasterPrefix", $targetMasterPrefix
                        $newName = $newName -ireplace "^$sourceRoutePrefix", $targetRoutePrefix
                        Copy-Item -Path $_.FullName -Destination "$newTrackDir\$newName" -Force
                    }
                } else {
                    $null = New-Item -ItemType SymbolicLink -Path "$targetDir\Main_release\tracks\$itemName" -Target $_.FullName -Force
                }
            }
        } else {
            $null = New-Item -ItemType SymbolicLink -Path "$targetDir\Main_release\tracks\$itemName" -Target $_.FullName -Force
        }
    }
}
Write-Host "Batch process completed successfully!" -ForegroundColor Green