$scriptDir = $PSScriptRoot
$outputDir = Join-Path $scriptDir "output"

$jsonFile = Join-Path $outputDir "winget-list-details.json"
$outFile = Join-Path $outputDir "packages-by-type.json"

if (-not (Test-Path $jsonFile)) {
    Write-Error "JSON file not found at $jsonFile. Run parse-winget.ps1 first."
    exit 1
}

$json = Get-Content $jsonFile -Raw | ConvertFrom-Json

$groups = $json | Group-Object InstallerCategory

$results = @{}
foreach ($g in $groups) {
    $type = $g.Name
    if (-not $type) { $type = "unknown" }
    $results[$type] = $g.Group | ForEach-Object {
        [PSCustomObject]@{
            Name              = $_.Name
            Version           = $_.Version
            Publisher         = $_.Publisher
            PackageFamilyName = $_.PackageFamilyName
            InstalledLocation = $_.InstalledLocation
        }
    }
}

# display summary
Write-Host "`n=== Packages by Installer Type ==="
foreach ($type in ($results.Keys | Sort-Object)) {
    $count = $results[$type].Count
    Write-Host "`n--- $type ($count) ---" -ForegroundColor Cyan
    $results[$type] | Format-Table Name, Version, Publisher -AutoSize
}

$results | ConvertTo-Json -Depth 3 | Out-File $outFile -Encoding utf8
Write-Host "Saved to $outFile"
