#requires -Version 7.0
<#
.SYNOPSIS
    Remove the dsh-ar Arabic language pack from a DeepSeek Harness profile.

.DESCRIPTION
    Removes the dsh-ar loader row from the profile's cordis.patch.yml and deletes
    the package directory from the profile's node_modules.

.PARAMETER Profile
    Profile name under $DSH_HOME\profiles. Default: desktop.

.PARAMETER DshHome
    Harness home. Defaults to $env:DSH_HOME, else ~/.dsh.
#>
[CmdletBinding()]
param(
    [string]$Profile = 'desktop',
    [string]$DshHome = $(if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $HOME '.dsh' })
)

$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host 'dsh-ar uninstaller' -ForegroundColor Cyan
Write-Host '-------------------'

$profileDir = Join-Path $DshHome "profiles\$Profile"
$patchFile = Join-Path $profileDir 'cordis.patch.yml'
$targetDir = Join-Path $profileDir 'node_modules\dsh-ar'

if (Test-Path -LiteralPath $patchFile) {
    $lines = Get-Content -LiteralPath $patchFile -Encoding UTF8
    $out = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^\s*-\s*id:\s*dsh-ar\s*$') {
            if ($out.Count -ge 1 -and $out[$out.Count - 1] -match '^\s*-\s*insert:\s*$') { $out.RemoveAt($out.Count - 1) }
            if ($out.Count -ge 1 -and $out[$out.Count - 1] -match '^#\s*dsh-ar') { $out.RemoveAt($out.Count - 1) }
            continue
        }
        $out.Add($line)
    }
    [System.IO.File]::WriteAllText($patchFile, (($out -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding $false))
    Write-Host "  patch row removed from $patchFile" -ForegroundColor Green
}

if (Test-Path -LiteralPath $targetDir) {
    Remove-Item -LiteralPath $targetDir -Recurse -Force
    Write-Host "  package removed: $targetDir" -ForegroundColor Green
}

Write-Host ''
Write-Host 'Done. The UI returns to English (or Chinese) after a restart.' -ForegroundColor Green
Write-Host ''
