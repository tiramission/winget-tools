$scriptDir = $PSScriptRoot
$outputDir = Join-Path $scriptDir "output"
if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }

$rawFile = Join-Path $outputDir "winget-raw.txt"
$jsonFile = Join-Path $outputDir "winget-list-details.json"

Write-Host "Running winget list --details ..."
winget list --details *>$rawFile

$raw = Get-Content $rawFile -Raw
# strip ANSI escape sequences
$raw = $raw -replace '\x1b\[[0-9;]*[a-zA-Z]', ''

$entries = @()
$current = $null

$lines = $raw -split "`r?`n"
foreach ($line in $lines) {
    $trimmed = $line.Trim()
    if ($trimmed -eq '') { continue }
    if ($trimmed -match '^█+|^\s*-\s*$|\d+\.\d+\s+MB') { continue }

    $isUpgradeLine = $line -match '^\s{2,}\S+\s+\[.+?\]$' -and $current.ContainsKey('AvailableUpgrades') -and $current['AvailableUpgrades'] -is [array]
    if ($isUpgradeLine) {
        if ($line -match '^\s{2,}\S+\s+\[(.+?)\]$') { $current['AvailableUpgrades'] += $matches[1] }
        continue
    }

    if ($trimmed -match '^\(\d+/\d+\)\s+(.+?)\s+\[(.+?)\]$') {
        if ($current) { $entries += $current }
        $current = @{
            Name     = $matches[1]
            SourceId = $matches[2]
            AvailableUpgrades = @()
        }
    } elseif ($current) {
        if ($trimmed -match '^(?:Version|版本):\s*(.+)$') { $current['Version'] = $matches[1].Trim() }
        elseif ($trimmed -match '^(?:Publisher|发布者):\s*(.+)$') { $current['Publisher'] = $matches[1].Trim() }
        elseif ($trimmed -match '^(?:Local Identifier|本地标识符):\s*(.+)$') { $current['LocalIdentifier'] = $matches[1].Trim() }
        elseif ($trimmed -match '^(?:Product Code|产品代码):\s*(.+)$') { $current['ProductCode'] = $matches[1].Trim() }
        elseif ($trimmed -match '^(?:Package Family Name|包系列名称):\s*(.+)$') { $current['PackageFamilyName'] = $matches[1].Trim() }
        elseif ($trimmed -match '^(?:Installer Category|安装程序类别):\s*(.+)$') { $current['InstallerCategory'] = $matches[1].Trim() }
        elseif ($trimmed -match '^(?:Installed Scope|已安装的范围):\s*(.+)$') { $current['InstalledScope'] = $matches[1].Trim() }
        elseif ($trimmed -match '^(?:Installed Architecture|已安装的体系结构):\s*(.+)$') { $current['InstalledArchitecture'] = $matches[1].Trim() }
        elseif ($trimmed -match '^(?:Installed Location|安装位置):\s*(.+)$') { $current['InstalledLocation'] = $matches[1].Trim() }
        elseif ($trimmed -match '^(?:Available Upgrades|可用更新):$') { $current['AvailableUpgrades'] = @() }
    }
}
if ($current) { $entries += $current }

$entries | ConvertTo-Json -Depth 3 | Out-File $jsonFile -Encoding utf8
Write-Host "Exported $($entries.Count) entries to $jsonFile"
