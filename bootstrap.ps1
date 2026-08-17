[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Refresh-Path {
    $paths = @(
        [Environment]::GetEnvironmentVariable("Path", "Machine") -split ";"
        [Environment]::GetEnvironmentVariable("Path", "User") -split ";"
        $env:Path -split ";"
    ) | Where-Object { $_ }
    $env:Path = ($paths | Select-Object -Unique) -join ";"
}

function Test-WingetPackage {
    param([Parameter(Mandatory)][string]$Id)

    $output = winget list --id $Id --exact --disable-interactivity 2>$null | Out-String
    return $output -match "(?im)\b$([regex]::Escape($Id))\b"
}

Refresh-Path
$pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
if (!$pwsh) {
    if (!(Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        throw "winget.exe is required to install PowerShell 7."
    }

    if (!(Test-WingetPackage -Id "Microsoft.PowerShell")) {
        Write-Host "Installing PowerShell 7..."
        winget install `
            --id Microsoft.PowerShell `
            --exact `
            --source winget `
            --accept-source-agreements `
            --accept-package-agreements `
            --disable-interactivity
        if ($LASTEXITCODE -ne 0) {
            throw "PowerShell 7 installation failed with exit code $LASTEXITCODE."
        }
    }

    Refresh-Path
    $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
}

if (!$pwsh) {
    throw "PowerShell 7 is installed but pwsh.exe was not found. Open a new terminal and rerun run.bat."
}

& $pwsh.Source -NoProfile -File (Join-Path $PSScriptRoot "logic.ps1")
exit $LASTEXITCODE
