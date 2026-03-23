# SEGA Rally 3 Track Batch
# Credits: Tathan (x.com/konotathan | tathan.moe)

$segaRally3Dir = Read-Host "Enter the full path to your 'SEGA Rally 3' base folder"
$magiTracks = Read-Host "Enter the full path to your SEGA Rally Revo tracks folder"

if (-not (Test-Path $segaRally3Dir) -or -not (Test-Path $magiTracks)) {
    Write-Host "Error: Paths not found. Exiting." -ForegroundColor Red
    exit
}

$baseDir = Split-Path $segaRally3Dir -Parent
$originalTracksDir = Join-Path $segaRally3Dir "Rally\Main_release\tracks"

$editions = [ordered]@{
    "SEGA Rally 3 - Alpine Edition"       = @("alpine1", "alpine2", "alpine3", "alpine6", "alpine7")
    "SEGA Rally 3 - Arctic Edition"       = @("arctic1", "arctic2", "arctic3", "arctic6", "Arctic7")
    "SEGA Rally 3 - Canyon Edition"       = @("canyon1", "canyon2", "canyon3", "Canyon7")
    "SEGA Rally 3 - Master Edition"       = @("lakeside1")
    "SEGA Rally 3 - Safari Edition"       = @("safari1", "safari2", "safari3", "Safari6")
    "SEGA Rally 3 - Tropical Edition"     = @("tropical1", "tropical2", "tropical3")
    "SEGA Rally 3 - Tropical Edition 478" = @("tropical7", "tropical8")
}

# The preferred vanilla track to KEEP if there are unused slots
$keepMatches = @{
    "Alpine"   = "Alpine4"; "Canyon"   = "Canyon4"; "Desert"   = "Desert4"
    "Lakeside" = "Lakeside4"; "Master"   = "Lakeside4"; "Stadium"  = "Stadium4"
}

# Tropical4 is explicitly excluded to protect the Main Menu background
$targetDefs = [ordered]@{
    "Alpine4"   = @{ Master = "alpine4"; Route = "alp_track_route4" }
    "Canyon4"   = @{ Master = "canyon4"; Route = "can_track_route4" }
    "Desert4"   = @{ Master = "desert4"; Route = "des_track_route4" }
    "Lakeside4" = @{ Master = "lakeside4"; Route = "lak_track_route4" }
    "Stadium4"  = @{ Master = "stadium4"; Route = "sta_track_route4" }
}

$fileMappings = @(
    @{ SourceSuffix = "*master_gfx_xdata.sbf"; Format = "{0}_master_gfx_xdata.sbf"; IsMaster = $true }
    @{ SourceSuffix = "*master_xdata.sbf"; Format = "{0}_master_xdata.sbf"; IsMaster = $true }
    @{ SourceSuffix = "*gameobj_gfx_dis_data.sbf"; Format = "{1}_gameobj_gfx_dis_data.sbf"; IsMaster = $false }
    @{ SourceSuffix = "*game_objects_gfx_data.sbf"; Format = "{1}_game_objects_gfx_data.sbf"; IsMaster = $false }
    @{ SourceSuffix = "*pobj_master_gfx_xdata.sbf"; Format = "{1}_pobj_master_gfx_xdata.sbf"; IsMaster = $false }
    @{ SourceSuffix = "*pobj_plac_gfx_xdata.sbf"; Format = "{1}_pobj_plac_gfx_xdata.sbf"; IsMaster = $false }
    @{ SourceSuffix = "*proc_cached.bin"; Format = "{2}_proc_cached.bin"; IsMaster = $false }
)

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

$rootFolders = @("Rally", "Shell", "ShellData")

foreach ($editionName in $editions.Keys) {
    $targetDir = Join-Path $baseDir $editionName
    if (Test-Path $targetDir) { Remove-Item -Path $targetDir -Recurse -Force }
}

foreach ($edition in $editions.GetEnumerator()) {
    $editionName = $edition.Name
    $sourceTracks = $edition.Value
    $targetDir = Join-Path $baseDir $editionName

    Write-Host "Building $editionName..." -ForegroundColor Cyan
    $null = New-Item -ItemType Directory -Force -Path $targetDir

    # 1. Base files Hard Linking (ignores arbitrary folders like MagiPacks)
    foreach ($folder in $rootFolders) {
        $sourceRoot = Join-Path $segaRally3Dir $folder
        if (-not (Test-Path $sourceRoot)) { continue }

        $targetRoot = Join-Path $targetDir $folder
        $null = New-Item -ItemType Directory -Path $targetRoot -Force

        Get-ChildItem -Path $sourceRoot -Recurse | ForEach-Object {
            $item = $_
            $relPath = $item.FullName.Substring($sourceRoot.Length).TrimStart('\')
            $targetPath = Join-Path $targetRoot $relPath

            if ($item.PSIsContainer) {
                $null = New-Item -ItemType Directory -Path $targetPath -Force
            } else {
                if ($folder -eq "Rally" -and $relPath -like "Main_release\tracks\*") { return }
                if ($folder -eq "Rally" -and $relPath -eq "Rally.exe") {
                    Copy-Item -Path $item.FullName -Destination $targetPath -Force
                    return
                }
                if ($folder -eq "ShellData" -and $relPath -eq "GameInfo.ini") { return }

                $null = New-Item -ItemType HardLink -Path $targetPath -Target $item.FullName -Force
            }
        }
    }

    # 2. Slot Logic (Prioritize overwriting non-native tracks first)
    $keptTrack = $null
    foreach ($key in $keepMatches.Keys) {
        if ($editionName -match $key) { $keptTrack = $keepMatches[$key]; break }
    }

    $slotsToFill = @()
    foreach ($slot in $targetDefs.Keys) {
        if ($slot -ne $keptTrack) { $slotsToFill += $slot }
    }
    if ($keptTrack) { $slotsToFill += $keptTrack } # Native track overwritten LAST if array is full

    # Dynamic Map Names for GameInfo.ini
    $gameInfoMap = @{
        "Tropical4" = "Tropical (Original)"
        "Canyon4"   = "Canyon (Original)"
        "Alpine4"   = "Alpine (Original)"
        "Lakeside4" = "Lakeside (Original)"
        "Desert4"   = "Desert 95 (Original)"
        "Stadium4"  = "Stadium (Original)"
    }

    $targetRallyTracks = Join-Path $targetDir "Rally\Main_release\tracks"
    if (-not (Test-Path $targetRallyTracks)) { $null = New-Item -ItemType Directory -Path $targetRallyTracks -Force }

    # 3. Track Processing & Strict File Map
    Get-ChildItem -Path $originalTracksDir -Directory | ForEach-Object {
        $itemName = $_.Name
        $newTrackDir = Join-Path $targetRallyTracks $itemName
        if (-not (Test-Path $newTrackDir)) { $null = New-Item -ItemType Directory -Path $newTrackDir -Force }

        if ($itemName -in $targetDefs.Keys) {
            $slotIndex = [array]::IndexOf($slotsToFill, $itemName)
            
            if ($slotIndex -lt $sourceTracks.Count) {
                $sourceTrackName = $sourceTracks[$slotIndex]
                $sourceTrackDir = Join-Path $magiTracks $sourceTrackName
                
                # Format name for GameInfo
                $friendlyName = $sourceTrackName -replace "^([a-zA-Z]+)(\d+)$", "`$1 `$2"
                $gameInfoMap[$itemName] = (Get-Culture).TextInfo.ToTitleCase($friendlyName.ToLower())

                $targetMaster = $targetDefs[$itemName].Master
                $targetRoute = $targetDefs[$itemName].Route
                $targetRouteTitle = $targetRoute.Substring(0,1).ToUpper() + $targetRoute.Substring(1)

                foreach ($mapping in $fileMappings) {
                    $sourceFile = Get-ChildItem -Path $sourceTrackDir -Filter $mapping.SourceSuffix | Select-Object -First 1
                    if ($sourceFile) {
                        if ($mapping.IsMaster) {
                            $newName = $mapping.Format -f $targetMaster
                        } else {
                            $newName = $mapping.Format -f $null, $targetRoute, $targetRouteTitle
                        }
                        Copy-Item -Path $sourceFile.FullName -Destination (Join-Path $newTrackDir $newName) -Force
                    }
                }
            } else {
                Get-ChildItem -Path $_.FullName -File | ForEach-Object {
                    $null = New-Item -ItemType HardLink -Path (Join-Path $newTrackDir $_.Name) -Target $_.FullName -Force
                }
            }
        } else {
            # Bypasses logic for Tropical4 and viewer1 (Hard Links them natively)
            Get-ChildItem -Path $_.FullName -File | ForEach-Object {
                $null = New-Item -ItemType HardLink -Path (Join-Path $newTrackDir $_.Name) -Target $_.FullName -Force
            }
        }
    }

    # 4. Generate GameInfo.ini
    $targetShellData = Join-Path $targetDir "ShellData"
    if (-not (Test-Path $targetShellData)) { $null = New-Item -ItemType Directory -Path $targetShellData -Force }
    
    $tracksSection = "[Tracks]`nTrack0=$($gameInfoMap['Tropical4'])`nTrack1=$($gameInfoMap['Canyon4'])`nTrack2=$($gameInfoMap['Alpine4'])`nTrack3=$($gameInfoMap['Lakeside4'])`nTrack4=$($gameInfoMap['Desert4'])`nTrack5=$($gameInfoMap['Stadium4'])"
    $gameInfoContent = "#game author game info`n" + $tracksSection + "`n`n" + $carsSection
    Set-Content -Path (Join-Path $targetShellData "GameInfo.ini") -Value $gameInfoContent -Force
}
Write-Host "Batch process completed successfully!" -ForegroundColor Green
