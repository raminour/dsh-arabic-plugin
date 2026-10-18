#requires -Version 7.0
<#
.SYNOPSIS
    Install the dsh-rtl plugin into a DeepSeek Harness profile.

.DESCRIPTION
    Copies the dsh-rtl package into <DSH_HOME>\profiles\<Profile>\node_modules\dsh-rtl
    and appends its loader row to the profile's cordis.patch.yml.

    The profile config is watched by dsh-hmr, so the change normally applies to an
    open window without a restart; restart the app if it does not.

    Re-running is safe: the copy overwrites and the row is only added once.

.PARAMETER Profile
    Profile name under $DSH_HOME\profiles. Desktop app uses "desktop" (default).

.PARAMETER DshHome
    Harness home. Defaults to $env:DSH_HOME, else ~/.dsh.

.PARAMETER Source
    Directory holding package.json, index.js, client.js. Defaults to this script's
    own directory.

.PARAMETER Restart
    Ask the app to restart after installing (Windows: stops and relaunches it).

.EXAMPLE
    pwsh -File .\install-rtl.ps1

.EXAMPLE
    pwsh -File .\install-rtl.ps1 -Profile web -Restart
#>
[CmdletBinding()]
param(
    [string]$Profile = 'desktop',
    [string]$DshHome = $(if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $HOME '.dsh' }),
    [string]$Source = $PSScriptRoot,
    [switch]$Restart
)

$ErrorActionPreference = 'Stop'

function Write-Step($text) { Write-Host "  $text" }

Write-Host ''
Write-Host 'dsh-rtl installer' -ForegroundColor Cyan
Write-Host '-----------------'

$profileDir = Join-Path $DshHome "profiles\$Profile"
if (-not (Test-Path -LiteralPath $profileDir)) {
    throw "Profile directory not found: $profileDir`nInstall/deepseek harness first, or pass -Profile/-DshHome."
}

$patchFile = Join-Path $profileDir 'cordis.patch.yml'
$packageJson = Join-Path $Source 'package.json'
foreach ($needed in @($patchFile, $packageJson, (Join-Path $Source 'client.js'), (Join-Path $Source 'index.js'))) {
    if (-not (Test-Path -LiteralPath $needed)) { throw "Missing required file: $needed" }
}

# 1. Copy the package into the profile's node_modules (loader resolves it from there).
$targetDir = Join-Path $profileDir 'node_modules\dsh-rtl'
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
foreach ($file in @('package.json', 'index.js', 'client.js')) {
    Copy-Item -LiteralPath (Join-Path $Source $file) -Destination (Join-Path $targetDir $file) -Force
    Write-Step "copied $file"
}
Write-Step "package -> $targetDir"

# 2. Register the loader row once (idempotent).
$patchText = Get-Content -LiteralPath $patchFile -Raw -Encoding UTF8
if ($patchText -match '(?m)^\s*-\s*id:\s*dsh-rtl\s*$') {
    Write-Step 'patch row already present'
}
else {
    $row = @'

# dsh-rtl: right-to-left layout for the web UI (local plugin in node_modules/dsh-rtl)
- insert:
    - id: dsh-rtl
      name: "dsh-rtl"
'@
    if (-not $patchText.EndsWith("`n")) { $patchText += "`n" }
    $patchText += $row
    [System.IO.File]::WriteAllText($patchFile, $patchText, (New-Object System.Text.UTF8Encoding $false))
    Write-Step "row appended -> $patchFile"
}

Write-Host ''
Write-Host 'Done. The window should switch to RTL within a second or two.' -ForegroundColor Green
Write-Host 'If nothing changed, restart DeepSeek Harness (or rerun with -Restart).'
Write-Host 'Undo: pwsh -File .\uninstall-rtl.ps1'
Write-Host ''

if ($Restart) {
    $exe = Get-Process 'DeepSeek Harness' -ErrorAction SilentlyContinue |
        Where-Object { $_.Path } | Select-Object -First 1 -ExpandProperty Path
    if (-not $exe) { $exe = Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Harness\DeepSeek Harness.exe' }
    if (Test-Path -LiteralPath $exe) {
        Write-Step "restarting $exe"
        Get-Process 'DeepSeek Harness' -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Seconds 2
        Start-Process -FilePath $exe
    }
    else {
        Write-Warning "Could not locate the app executable to restart: $exe"
    }
}
