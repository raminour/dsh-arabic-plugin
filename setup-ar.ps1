<#
  setup-ar.ps1 - installs the dsh-rtl (right-to-left layout) and dsh-ar (Arabic language pack)
  plugins into a DeepSeek Harness profile.

  Usage:
    powershell -ExecutionPolicy Bypass -File .\setup-ar.ps1
    powershell -ExecutionPolicy Bypass -File .\setup-ar.ps1 -Uninstall
    powershell -ExecutionPolicy Bypass -File .\setup-ar.ps1 -Profile web
    powershell -ExecutionPolicy Bypass -File .\setup-ar.ps1 -Restart

  It finds the Harness home (%USERPROFILE%\.dsh or $env:DSH_HOME), copies the two plugin
  folders into <profile>\node_modules, and adds their loader rows to <profile>\cordis.patch.yml
  once. It never touches the Harness installation itself, so app updates keep working.
#>
[CmdletBinding()]
param(
    [string]$Profile = 'desktop',
    [string]$DshHome = '',
    [switch]$Uninstall,
    [switch]$Restart
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$self = $MyInvocation.MyCommand.Path

if ([string]::IsNullOrWhiteSpace($DshHome)) {
    if ($env:DSH_HOME) { $DshHome = $env:DSH_HOME } else { $DshHome = Join-Path $env:USERPROFILE '.dsh' }
}

$plugins = @(
    @{ Id = 'dsh-rtl'; Label = 'right-to-left layout for the web UI' },
    @{ Id = 'dsh-ar'; Label = 'Arabic language pack for the web UI' }
)

function Step([string]$text) { Write-Host ('  ' + $text) }

Write-Host ''
Write-Host 'DeepSeek Harness - Arabic UI setup' -ForegroundColor Cyan
Write-Host '----------------------------------'
Step ('kit folder:   ' + $here)
Step ('harness home: ' + $DshHome)

$profileDir = Join-Path $DshHome (Join-Path 'profiles' $Profile)
if (-not (Test-Path -LiteralPath $profileDir)) {
    Write-Host ''
    Write-Host ('Profile "' + $Profile + '" not found at ' + $profileDir) -ForegroundColor Yellow
    Write-Host 'Start DeepSeek Harness once, close it, then run this setup again.'
    exit 1
}

$modsDir = Join-Path $profileDir 'node_modules'
$patchFile = Join-Path $profileDir 'cordis.patch.yml'
if (-not (Test-Path -LiteralPath $patchFile)) {
    [System.IO.File]::WriteAllText($patchFile, "# Your patch layer for this dsh profile.`r`n[]`r`n", (New-Object System.Text.UTF8Encoding $false))
}

function Read-Patch { return [System.IO.File]::ReadAllText($patchFile, [System.Text.Encoding]::UTF8) }
function Write-Patch([string]$text) { [System.IO.File]::WriteAllText($patchFile, $text, (New-Object System.Text.UTF8Encoding $false)) }

function Remove-Row([string]$text, [string]$id) {
    $lines = $text -split "`r?`n"
    $out = New-Object -TypeName 'System.Collections.Generic.List[string]'
    foreach ($line in $lines) {
        if ($line -match ('^\s*-\s*id:\s*' + [regex]::Escape($id) + '\s*$')) {
            if ($out.Count -ge 1 -and $out[$out.Count - 1] -match '^\s*-\s*insert:\s*$') { $out.RemoveAt($out.Count - 1) }
            if ($out.Count -ge 1 -and $out[$out.Count - 1] -match ('^#\s*' + [regex]::Escape($id))) { $out.RemoveAt($out.Count - 1) }
            continue
        }
        $out.Add($line)
    }
    return (($out -join "`r`n").TrimEnd() + "`r`n")
}

if ($Uninstall) {
    Write-Host ''
    Step 'removing plugin rows and folders'
    $patch = Read-Patch
    foreach ($plug in $plugins) { $patch = Remove-Row $patch $plug.Id }
    Write-Patch $patch
    foreach ($plug in $plugins) {
        $dir = Join-Path $modsDir $plug.Id
        if (Test-Path -LiteralPath $dir) {
            Remove-Item -LiteralPath $dir -Recurse -Force
            Step ('removed ' + $dir)
        }
    }
    Write-Host ''
    Write-Host 'Done. Restart DeepSeek Harness to return to the default interface.' -ForegroundColor Green
    exit 0
}

New-Item -ItemType Directory -Path $modsDir -Force | Out-Null
$patch = Read-Patch
$changed = $false

foreach ($plug in $plugins) {
    $src = Join-Path $here $plug.Id
    if (-not (Test-Path -LiteralPath (Join-Path $src 'package.json'))) { throw ('Missing plugin files: ' + $src) }
    $dst = Join-Path $modsDir $plug.Id
    if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }
    Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
    Step ('installed ' + $plug.Id + ' -> ' + $dst)

    if ($patch -match ('(?m)^\s*-\s*id:\s*' + [regex]::Escape($plug.Id) + '\s*$')) {
        Step ('row already present: ' + $plug.Id)
    } else {
        $block = "`r`n# " + $plug.Id + ': ' + $plug.Label + "`r`n- insert:`r`n    - id: " + $plug.Id + "`r`n      name: `"" + $plug.Id + "`"" + "`r`n"
        $patch = $patch.TrimEnd() + "`r`n" + $block
        $changed = $true
        Step ('row added: ' + $plug.Id)
    }
}

if ($changed) { Write-Patch $patch } else { Step 'patch file already up to date' }

Write-Host ''
Write-Host 'Installed. Next steps:' -ForegroundColor Green
Write-Host '  1. Start (or restart) DeepSeek Harness.'
Write-Host '  2. Open Settings (gear) -> General -> Language -> Arabic.'
Write-Host '  3. The UI switches to Arabic and right-to-left.'
Write-Host ''
Write-Host ('Undo: powershell -ExecutionPolicy Bypass -File "' + $self + '" -Uninstall')
Write-Host ''

if ($Restart) {
    $exe = $null
    $proc = Get-Process -Name 'DeepSeek Harness' -ErrorAction SilentlyContinue | Where-Object { $_.Path } | Select-Object -First 1
    if ($proc) { $exe = $proc.Path }
    if (-not $exe) { $exe = Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Harness\DeepSeek Harness.exe' }
    if (Test-Path -LiteralPath $exe) {
        Step 'restarting DeepSeek Harness'
        Get-Process -Name 'DeepSeek Harness' -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Seconds 2
        Start-Process -FilePath $exe
    } else {
        Write-Warning 'Could not find the DeepSeek Harness executable.'
    }
}