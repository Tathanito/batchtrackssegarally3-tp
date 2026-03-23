# SEGA Rally 3 Edition Generator
# Credits: Tathan (x.com/konotathan | tathan.moe)

$segaRally3Dir = Read-Host "Enter the full path to your 'SEGA Rally 3' base folder (e.g., C:\Games\Arcade\SEGA Rally 3)"
$magiTracks = Read-Host "Enter the full path to your SEGA Rally Revo tracks folder"

# Validate paths
if (-not (Test-Path $segaRally3Dir)) {
    Write-Host "Error: SEGA Rally 3 installation not found at '$segaRally3Dir'. Exiting." -ForegroundColor Red
    exit
}

if (-not (Test-Path $magiTracks)) {
    Write-Host "Error: Revo tracks folder not found at '$magiTracks'. Exiting." -ForegroundColor Red
    exit
}

$baseDir = Split-Path $segaRally3Dir -Parent
$originalTracksDir = "$segaRally3Dir\Rally\Main_release\tracks"

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

$carsSection = @"
[Cars]
Car0=Citroen C4 WRC
Car1=Ford Focus RS WRC 07
Car2=Subaru Impreza WRC2008
Car3=Suzuki SX4 WRC
Car4=Mitsubishi Lancer Evolution X
Car5=Peugeot 207 Super 2000
Car6=Toyota Celica ST205
Car7=Lancia Super Delta HF integrale
Car8=Bowler Nemesis
Car9=McRae Enduro
"@

$gameInfoTracks = @{
    "SEGA Rally 3 - Alpine Edition" = "[Tracks]`nTrack0=Alpine 7`nTrack1=Alpine 1`nTrack2=Alpine (Original)`nTrack3=Alpine 3`nTrack4=Alpine 2`nTrack5=Alpine 6"
    "SEGA Rally 3 - Arctic Edition" = "[Tracks]`nTrack0=Tropical (Original)`nTrack1=Arctic 2`nTrack2=Arctic 1`nTrack3=Arctic 6`nTrack4=Arctic 3`nTrack5=Arctic 7"
    "SEGA Rally 3 - Canyon Edition" = "[Tracks]`nTrack0=Tropical (Original)`nTrack1=Canyon (Original)`nTrack2=Canyon 1`nTrack3=Canyon 3`nTrack4=Canyon 2`nTrack5=Canyon 7"
    "SEGA Rally 3 - Master Edition" = "[Tracks]`nTrack0=Tropical (Original)`nTrack1=Canyon (Original)`nTrack2=Lakeside 1`nTrack3=Lakeside (Original)`nTrack4=Desert 95 (Original)`nTrack5=Stadium (Original)"
    "SEGA Rally 3 - Safari Edition" = "[Tracks]`nTrack0=Tropical (Original)`nTrack1=Safari 2`nTrack2=Safari 1`nTrack3=Safari 6`nTrack4=Safari 3`nTrack5=Stadium (Original)"
    "SEGA Rally 3 - Tropical Edition" = "[Tracks]`nTrack0=Tropical (Original)`nTrack1=Tropical 2`nTrack2=Tropical 1`nTrack3=Lakeside (Original)`nTrack4=Tropical 3`nTrack5=Stadium (Original)"
    "SEGA Rally 3 - Tropical Edition 478" = "[Tracks]`nTrack0=Tropical (Original)`nTrack1=Tropical 8`nTrack2=Tropical 7`nTrack3=Lakeside (Original)`nTrack4=Desert 95 (Original)`nTrack5=Stadium (Original)"
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

    $targetRally = "$targetDir\Rally"
    $targetShell = "$targetDir\Shell"
    $targetShellData = "$targetDir\ShellData"
    
    $null = New-Item -ItemType Directory -Force -Path "$targetRally\Main_release\tracks"
    $null = New-Item -ItemType Directory -Force -Path $targetShell
    $null = New-Item -ItemType Directory -Force -Path $targetShellData

    # --- Handle Shell ---
    if (Test-Path "$segaRally3Dir\Shell") {
        Get-ChildItem -Path "$segaRally3Dir\Shell" | ForEach-Object {
            $null = New-Item -ItemType SymbolicLink -Path "$targetShell\$($_.Name)" -Target $_.FullName -Force
        }
    }

    # --- Handle ShellData & GameInfo.ini ---
    if (Test-Path "$segaRally3Dir\ShellData") {
        Get-ChildItem -Path "$segaRally3Dir\ShellData" | Where-Object Name -ne "GameInfo.ini" | ForEach-Object {
            $null = New-Item -ItemType SymbolicLink -Path "$targetShellData\$($_.Name)" -Target $_.FullName -Force
        }
    }
    
    $gameInfoContent = "#game author game info`n" + $gameInfoTracks[$editionName] + "`n`n" + $carsSection
    Set-Content -Path "$targetShellData\GameInfo.ini" -Value $gameInfoContent -Force

    # --- Handle Rally ---
    Get-ChildItem -Path "$segaRally3Dir\Rally" | Where-Object { $_.Name -notin @("Main_release", "Rally.exe") } | ForEach-Object {
        $null = New-Item -ItemType SymbolicLink -Path "$targetRally\$($_.Name)" -Target $_.FullName -Force
    }
    
    if (Test-Path "$segaRally3Dir\Rally\Rally.exe") {
        Copy-Item -Path "$segaRally3Dir\Rally\Rally.exe" -Destination "$targetRally\Rally.exe" -Force
    }

    # --- Handle Main_release ---
    Get-ChildItem -Path "$segaRally3Dir\Rally\Main_release" | Where-Object Name -ne "tracks" | ForEach-Object {
        $null = New-Item -ItemType SymbolicLink -Path "$targetRally\Main_release\$($_.Name)" -Target $_.FullName -Force
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
                $null = New-Item -ItemType SymbolicLink -Path "$targetRally\Main_release\tracks\$itemName" -Target $_.FullName -Force
            } else {
                $slotIndex = [array]::IndexOf($slotsToFill, $itemName)
                
                if ($slotIndex -lt $sourceTracks.Count) {
                    $sourceTrackName = $sourceTracks[$slotIndex]
                    $sourceTrackDir = "$magiTracks\$sourceTrackName"
                    $newTrackDir = "$targetRally\Main_release\tracks\$itemName"
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
                    $null = New-Item -ItemType SymbolicLink -Path "$targetRally\Main_release\tracks\$itemName" -Target $_.FullName -Force
                }
            }
        } else {
            $null = New-Item -ItemType SymbolicLink -Path "$targetRally\Main_release\tracks\$itemName" -Target $_.FullName -Force
        }
    }
}
Write-Host "Batch process completed successfully!" -ForegroundColor Green
