# winget-tools

Three PowerShell scripts that enumerate Windows packages via the winget CLI.

## Pipeline

```powershell
pwsh parse-winget.ps1           # step 1: runs `winget list --details`, outputs output/winget-list-details.json
pwsh find-context-menus.ps1     # step 2: reads that JSON, inspects AppxManifest.xml for desktop4:FileExplorerContextMenus
pwsh group-by-type.ps1          # step 2 (alternative): groups same JSON by InstallerCategory (exe/msi/msix/portable)
```

- Steps 2 depend on step 1's output (`output/winget-list-details.json`).
- Intermediate artifacts: `output/winget-raw.txt`, `output/winget-list-details.json`.
- Final results: `output/context-menu-packages.json`, `output/packages-by-type.json`.

## Requirements

- Windows only
- `winget` CLI must be available on `PATH`
- PowerShell 5.1+ or pwsh

## Scripts

- `parse-winget.ps1` — Captures `winget list --details`, strips ANSI escapes, parses key-value fields (Version, Publisher, PackageFamilyName, InstalledLocation, etc.) into JSON. Handles bilingual headers (English/Chinese).
- `find-context-menus.ps1` — Filters parsed packages to those in `C:\Program Files\WindowsApps\`, reads each `AppxManifest.xml` for `desktop4:FileExplorerContextMenus`. Outputs matching packages as JSON table.
- `group-by-type.ps1` — Groups same JSON by `InstallerCategory` (exe/msi/msix/portable). Outputs `output/packages-by-type.json`.

## Conventions

- All output goes to `output/` (gitignored).
- Scripts use `$PSScriptRoot` — always run from repo root, don't change working directory.
- ANSI stripping via regex `\x1b\[[0-9;]*[a-zA-Z]` — rerun step 1 if winget output format changes.
