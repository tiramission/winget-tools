$scriptDir = $PSScriptRoot
$outputDir = Join-Path $scriptDir "output"

$jsonFile = Join-Path $outputDir "winget-list-details.json"
$outFile = Join-Path $outputDir "context-menu-packages.json"

if (-not (Test-Path $jsonFile)) {
    Write-Error "JSON file not found at $jsonFile. Run parse-winget.ps1 first."
    exit 1
}

$json = Get-Content $jsonFile -Raw | ConvertFrom-Json
$results = @()

foreach ($pkg in $json) {
    if (-not $pkg.InstalledLocation) { continue }
    $loc = $pkg.InstalledLocation.Trim('"')
    if ($loc -notlike 'C:\Program Files\WindowsApps\*') { continue }

    $manifest = Join-Path $loc "AppxManifest.xml"
    if (-not (Test-Path $manifest)) { continue }

    try {
        $xml = [xml](Get-Content $manifest -Raw)
        $hasContextMenu = $xml.DocumentElement.OuterXml -match 'desktop4:FileExplorerContextMenus'

        if ($hasContextMenu) {
            $results += [PSCustomObject]@{
                Name               = $pkg.Name
                Version            = $pkg.Version
                SourceId           = $pkg.SourceId
                PackageFamilyName  = $pkg.PackageFamilyName
                InstalledLocation  = $loc
            }
        }
    } catch {
        Write-Warning "Failed to parse $manifest : $_"
    }
}

$results | Format-Table -AutoSize

$results | ConvertTo-Json -Depth 2 | Out-File $outFile -Encoding utf8
Write-Host "`nFound $($results.Count) package(s) with desktop4:FileExplorerContextMenus. Saved to $outFile"
