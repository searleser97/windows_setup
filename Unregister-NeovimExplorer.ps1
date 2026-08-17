[CmdletBinding()]
param()

$progId = "Neovim.WezTerm"
$installDirectory = Join-Path $env:LOCALAPPDATA "Programs\NeovimInWezTerm"
$backupPath = Join-Path $installDirectory "association-backup.json"
$shimHiddenMarker = Join-Path $installDirectory "scoop-nvim-shim-hidden"
$neovimShim = Join-Path $env:USERPROFILE "scoop\shims\nvim.exe"
$startMenuDirectory = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$startMenuShortcuts = @(
    (Join-Path $startMenuDirectory "Neovim (nvim) in WezTerm.lnk"),
    (Join-Path $startMenuDirectory "Neovim.lnk"),
    (Join-Path $startMenuDirectory "nvim.lnk"),
    (Join-Path $startMenuDirectory "Neovim in WezTerm.lnk")
)

$registrationPaths = @(
    "Software\Classes\$progId",
    "Software\Classes\Applications\Neovim.exe",
    "Software\Classes\Applications\nvim.exe",
    "Software\Classes\Applications\NeovimInWezTerm.exe",
    "Software\Classes\*\shell\NeovimInWezTerm",
    "Software\Classes\Directory\shell\NeovimInWezTerm",
    "Software\Classes\Directory\Background\shell\NeovimInWezTerm",
    "Software\Classes\Drive\shell\NeovimInWezTerm"
)

if (Test-Path -LiteralPath $backupPath) {
    $backup = Get-Content -LiteralPath $backupPath -Raw | ConvertFrom-Json -AsHashtable
    foreach ($entry in $backup.GetEnumerator()) {
        $extensionPath = "HKCU:\Software\Classes\$($entry.Key)"
        if (Test-Path $extensionPath) {
            $extensionKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey(
                "Software\Classes\$($entry.Key)",
                $true
            )
            try {
                if ($extensionKey.GetValue("") -eq $progId) {
                    if ($null -eq $entry.Value) {
                        $extensionKey.DeleteValue("", $false)
                    } else {
                        $extensionKey.SetValue(
                            "",
                            $entry.Value,
                            [Microsoft.Win32.RegistryValueKind]::String
                        )
                    }
                }
            } finally {
                $extensionKey.Dispose()
            }

            Remove-ItemProperty `
                -Path (Join-Path $extensionPath "OpenWithProgids") `
                -Name $progId `
                -ErrorAction SilentlyContinue
            Remove-Item `
                -LiteralPath (Join-Path $extensionPath "OpenWithList\NeovimInWezTerm.exe") `
                -Force `
                -ErrorAction SilentlyContinue
            Remove-Item `
                -LiteralPath (Join-Path $extensionPath "OpenWithList\nvim.exe") `
                -Force `
                -ErrorAction SilentlyContinue
            Remove-Item `
                -LiteralPath (Join-Path $extensionPath "OpenWithList\Neovim.exe") `
                -Force `
                -ErrorAction SilentlyContinue
        }
    }
}

foreach ($path in $registrationPaths) {
    [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($path, $false)
}

$registeredApplications = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey(
    "Software\RegisteredApplications",
    $true
)
if ($registeredApplications) {
    try {
        $registeredApplications.DeleteValue("Neovim", $false)
    } finally {
        $registeredApplications.Dispose()
    }
}
[Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree(
    "Software\searleser97\Neovim",
    $false
)

Remove-Item -LiteralPath $startMenuShortcuts -Force -ErrorAction SilentlyContinue
if ((Test-Path -LiteralPath $shimHiddenMarker) -and (Test-Path -LiteralPath $neovimShim)) {
    [IO.File]::SetAttributes(
        $neovimShim,
        [IO.File]::GetAttributes($neovimShim) -band (-bnot [IO.FileAttributes]::Hidden)
    )
}
Remove-Item -LiteralPath $installDirectory -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Removed Neovim in WezTerm Explorer integration."
