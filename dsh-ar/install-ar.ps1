#requires -Version 7.0
<#
.SYNOPSIS
    Install the dsh-ar Arabic language pack into a DeepSeek Harness profile.

.DESCRIPTION
    Copies the dsh-ar package into <DSH_HOME>\profiles\<Profile>\node_modules\dsh-ar
    and appends its loader row to the profile's cordis.patch.yml.

    The profile config is watched by dsh-hmr, so an open window picks the pack up
    without a restart. After install, choose the language in Settings -> General ->
    Language -> العربية. The choice persists.

    Re-running is safe.

.PARAMETER Profile
    Profile name under $DSH_HOME\profiles. Desktop app uses "desktop" (default).

.PARAMETER DshHome
    Harness home. Defaults to $env:DSH_HOME, else ~/.dsh.

.PARAMETER Source
    Directory holding package.json, index.js, client.js. Defaults to $PSScriptRoot.

.EXAMPLE
    pwsh -File .\install-ar.ps1
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
Write-Host 'dsh-ar installer (Arabic language pack)' -ForegroundColor Cyan
Write-Host '---------------------------------------'

$profileDir = Join-Path $DshHome "profiles\$Profile"
if (-not (Test-Path -LiteralPath $profileDir)) {
    throw "Profile directory not found: $profileDir`nStart DeepSeek Harness once, or pass -Profile/-DshHome."
}

$patchFile = Join-Path $profileDir 'cordis.patch.yml'
foreach ($needed in @((Join-Path $Source 'package.json'), (Join-Path $Source 'client.js'), (Join-Path $Source 'index.js'), $patchFile)) {
    if (-not (Test-Path -LiteralPath $needed)) { throw "Missing required file: $needed" }
}

# 1. Copy the package into the profile's node_modules.
$targetDir = Join-Path $profileDir 'node_modules\dsh-ar'
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
foreach ($file in @('package.json', 'index.js', 'client.js')) {
    Copy-Item -LiteralPath (Join-Path $Source $file) -Destination (Join-Path $targetDir $file) -Force
    Write-Step "copied $file"
}
Write-Step "package -> $targetDir"

# 2. Register the loader row once.
$patchText = Get-Content -LiteralPath $patchFile -Raw -Encoding UTF8
if ($patchText -match '(?m)^\s*-\s*id:\s*dsh-ar\s*$') {
    Write-Step 'patch row already present'
}
else {
    $row = @'

# dsh-ar: Arabic language pack (local plugin in node_modules/dsh-ar)
- insert:
    - id: dsh-ar
      name: "dsh-ar"
'@
    if (-not $patchText.EndsWith("`n")) { $patchText += "`n" }
    $patchText += $row
    [System.IO.File]::WriteAllText($patchFile, $patchText, (New-Object System.Text.UTF8Encoding $false))
    Write-Step "row appended -> $patchFile"
}

Write-Host ''
Write-Host 'Done. Now open Settings -> General -> Language and choose العربية.' -ForegroundColor Green
Write-Host 'If the Language row is missing, restart DeepSeek Harness (or rerun with -Restart).'
Write-Host 'Undo: pwsh -File .\uninstall-ar.ps1'
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
