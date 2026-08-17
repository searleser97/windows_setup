$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

function Write-Skipped {
    param([Parameter(Mandatory)][string]$Name)
    Write-Host "[skip] $Name is already installed or configured"
}

function Refresh-Path {
    $registeredPaths = @(
        [Environment]::GetEnvironmentVariable("Path", "Machine") -split ";"
        [Environment]::GetEnvironmentVariable("Path", "User") -split ";"
    ) | Where-Object { $_ }
    $toolPaths = @(
        (Join-Path $env:USERPROFILE "scoop\shims")
        (Join-Path $env:USERPROFILE ".dotnet\tools")
        (Join-Path $env:USERPROFILE ".cargo\bin")
        (Join-Path $env:USERPROFILE ".pyenv\pyenv-win\bin")
        (Join-Path $env:USERPROFILE ".pyenv\pyenv-win\shims")
    ) | Where-Object { Test-Path -LiteralPath $_ }
    $currentPaths = $env:Path -split ";" | Where-Object { $_ }
    $env:Path = (
        @($registeredPaths) + @($toolPaths) + @($currentPaths) |
            Select-Object -Unique
    ) -join ";"
}

function Test-Command {
    param([Parameter(Mandatory)][string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-WingetPackage {
    param([Parameter(Mandatory)][string]$Id)

    if ($script:wingetPackageList -match "(?im)\b$([regex]::Escape($Id))\b") {
        return $true
    }

    $previousPreference = $PSNativeCommandUseErrorActionPreference
    $PSNativeCommandUseErrorActionPreference = $false
    try {
        $output = winget list --id $Id --exact --disable-interactivity 2>$null |
            Out-String
        $querySucceeded = $LASTEXITCODE -eq 0
    } finally {
        $PSNativeCommandUseErrorActionPreference = $previousPreference
    }
    return (
        $querySucceeded -and
        $output -match "(?im)\b$([regex]::Escape($Id))\b"
    )
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory)][string]$Id,
        [string[]]$AdditionalArguments = @()
    )

    if (Test-WingetPackage $Id) {
        Write-Skipped $Id
        return
    }

    Write-Host "[run ] Installing $Id"
    winget install `
        --id $Id `
        --exact `
        --source winget `
        --accept-source-agreements `
        --accept-package-agreements `
        --disable-interactivity `
        @AdditionalArguments
    $script:wingetPackageList += "`n$Id"
    Refresh-Path
}

function Test-ScoopApp {
    param([Parameter(Mandatory)][string]$App)
    $name = $App.Split("/")[-1]
    return Test-Path -LiteralPath (Join-Path $env:USERPROFILE "scoop\apps\$name\current")
}

function Install-ScoopApp {
    param([Parameter(Mandatory)][string]$App)

    if (Test-ScoopApp $App) {
        Write-Skipped $App
        return
    }

    Write-Host "[run ] Installing $App"
    scoop install $App
    Refresh-Path
}

function Test-DotNetSdk {
    param([Parameter(Mandatory)][int]$Major)

    if (!(Test-Command dotnet)) {
        return $false
    }
    return [bool](dotnet --list-sdks | Where-Object { $_ -match "^$Major\." })
}

function Set-GitConfigIfNeeded {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    $previousPreference = $PSNativeCommandUseErrorActionPreference
    $PSNativeCommandUseErrorActionPreference = $false
    try {
        $currentValue = git config --global --get $Name 2>$null
    } finally {
        $PSNativeCommandUseErrorActionPreference = $previousPreference
    }
    if ($currentValue -ceq $Value) {
        Write-Skipped "git config $Name"
        return
    }
    git config --global $Name $Value
}

Refresh-Path

$previousColumns = $env:COLUMNS
$env:COLUMNS = "500"
$previousPreference = $PSNativeCommandUseErrorActionPreference
$PSNativeCommandUseErrorActionPreference = $false
try {
    $script:wingetPackageList = winget list --disable-interactivity 2>$null | Out-String
} finally {
    $PSNativeCommandUseErrorActionPreference = $previousPreference
    $env:COLUMNS = $previousColumns
}

if (!(Test-Command scoop)) {
    Write-Host "[run ] Installing Scoop"
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
    Refresh-Path
} else {
    Write-Skipped "Scoop"
}

foreach ($bucket in @("main", "extras", "versions")) {
    $bucketPath = Join-Path $env:USERPROFILE "scoop\buckets\$bucket"
    if (Test-Path -LiteralPath $bucketPath) {
        Write-Skipped "Scoop bucket $bucket"
    } else {
        scoop bucket add $bucket
    }
}

foreach ($app in @(
    "main/git",
    "main/ripgrep",
    "main/fd",
    "main/gcc",
    "extras/vcredist2022",
    "fzf"
)) {
    Install-ScoopApp $app
}

Install-WingetPackage "cURL.cURL"
Install-WingetPackage "Microsoft.AzureCLI"

foreach ($major in @(8, 9, 10)) {
    if (Test-DotNetSdk $major) {
        Write-Skipped ".NET SDK $major"
    } else {
        Install-WingetPackage "Microsoft.DotNet.SDK.$major" @("--architecture", "x64")
    }
}

$credentialProvider = Join-Path $env:USERPROFILE ".nuget\plugins\netcore\CredentialProvider.Microsoft\CredentialProvider.Microsoft.exe"
if (Test-Path -LiteralPath $credentialProvider) {
    Write-Skipped "Azure Artifacts Credential Provider"
} else {
    $credentialProviderZip = Join-Path $env:TEMP "credprovider-x64.zip"
    try {
        Invoke-WebRequest `
            -Uri "https://github.com/microsoft/artifacts-credprovider/releases/latest/download/Microsoft.win-x64.NuGet.CredentialProvider.zip" `
            -OutFile $credentialProviderZip
        Expand-Archive `
            -LiteralPath $credentialProviderZip `
            -DestinationPath (Join-Path $env:USERPROFILE ".nuget") `
            -Force
    } finally {
        Remove-Item -LiteralPath $credentialProviderZip -Force -ErrorAction SilentlyContinue
    }
}

foreach ($tool in @(
    @{ Package = "git-credential-manager"; Command = "git-credential-manager" },
    @{ Package = "dotnet-script"; Command = "dotnet-script" }
)) {
    $toolShim = Join-Path $env:USERPROFILE ".dotnet\tools\$($tool.Command).exe"
    if ((Test-Path -LiteralPath $toolShim) -or (Test-Command $tool.Command)) {
        Write-Skipped $tool.Package
    } else {
        dotnet tool install --global $tool.Package
        Refresh-Path
    }
}

$buildToolComponents = @(
    "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
    "Microsoft.VisualStudio.Component.VC.Tools.ARM64",
    "Microsoft.VisualStudio.Component.Windows11SDK.22621"
)
$buildToolsOverride =
    (($buildToolComponents | ForEach-Object { "--add $_" }) -join " ") +
    " --addProductLang En-us"
Install-WingetPackage `
    "Microsoft.VisualStudio.BuildTools" `
    @("--override", $buildToolsOverride)

Install-ScoopApp "main/llvm"
Install-WingetPackage "Rustlang.Rustup"

$cargoBin = Join-Path $env:USERPROFILE ".cargo\bin"
if (Test-Path -LiteralPath (Join-Path $cargoBin "cargo-binstall.exe")) {
    Write-Skipped "cargo-binstall"
} else {
    cargo install cargo-binstall
}
if (Test-Path -LiteralPath (Join-Path $cargoBin "tree-sitter.exe")) {
    Write-Skipped "tree-sitter-cli"
} else {
    cargo binstall tree-sitter-cli -y
}

foreach ($app in @(
    "versions/neovim-nightly",
    "extras/vscode",
    "main/nvm",
    "delta",
    "main/grep",
    "lazygit"
)) {
    Install-ScoopApp $app
}

Set-GitConfigIfNeeded "core.editor" "nvim"
Set-GitConfigIfNeeded "push.autoSetupRemote" "true"
Set-GitConfigIfNeeded "core.pager" "delta"
Set-GitConfigIfNeeded "core.longpaths" "true"

$nvmNodeRoot = Join-Path $env:USERPROFILE "scoop\persist\nvm\nodejs"
$node24 = Get-ChildItem $nvmNodeRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match "^v24\." } |
    Sort-Object { [version]($_.Name -replace "^v", "") } -Descending |
    Select-Object -First 1
if ($node24) {
    Write-Skipped "Node.js 24"
} else {
    nvm install 24
    $node24 = Get-ChildItem $nvmNodeRoot -Directory |
        Where-Object { $_.Name -match "^v24\." } |
        Sort-Object { [version]($_.Name -replace "^v", "") } -Descending |
        Select-Object -First 1
}

if (!(Test-Command node) -or (node --version 2>$null) -notmatch "^v24\.") {
    nvm use 24
    Refresh-Path
} else {
    Write-Skipped "Active Node.js 24"
}
if ($node24) {
    $env:Path = "$($node24.FullName);$env:Path"
}

$npmRoot = npm root --global
foreach ($package in @("prettier", "pnpm", "yarn", "vsts-npm-auth")) {
    if (Test-Path -LiteralPath (Join-Path $npmRoot "$package\package.json")) {
        Write-Skipped "npm package $package"
    } else {
        npm install --global $package
    }
}

Install-WingetPackage "wez.wezterm"

$neovimInstallDirectory = Join-Path $env:LOCALAPPDATA "Programs\NeovimInWezTerm"
$neovimLauncher = Join-Path $neovimInstallDirectory "nvim.exe"
$startMenuDirectory = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$legacyNeovimPaths = @(
    (Join-Path $startMenuDirectory "Neovim (nvim) in WezTerm.lnk"),
    (Join-Path $startMenuDirectory "Neovim in WezTerm.lnk"),
    (Join-Path $startMenuDirectory "nvim.lnk"),
    (Join-Path $neovimInstallDirectory "Open-NeovimInWezTerm.ps1"),
    (Join-Path $neovimInstallDirectory "NeovimInWezTerm.exe")
)
$hasLegacyNeovimFiles = [bool](
    $legacyNeovimPaths | Where-Object { Test-Path -LiteralPath $_ }
)
$hasLegacyNeovimRegistration = Test-Path `
    "HKCU:\Software\Classes\Applications\NeovimInWezTerm.exe"
$neovimCommandKey = Get-Item `
    "HKCU:\Software\Classes\Neovim.WezTerm\shell\open\command" `
    -ErrorAction SilentlyContinue
$neovimCommand = if ($neovimCommandKey) {
    $neovimCommandKey.GetValue("")
} else {
    $null
}
if (
    (Test-Path -LiteralPath $neovimLauncher) -and
    $neovimCommand -and
    $neovimCommand.Contains($neovimLauncher) -and
    !$hasLegacyNeovimFiles -and
    !$hasLegacyNeovimRegistration
) {
    Write-Skipped "Neovim Explorer integration"
} else {
    & (Join-Path $PSScriptRoot "Register-NeovimExplorer.ps1")
}

if (Test-Command pyenv) {
    Write-Skipped "pyenv-win"
} else {
    & (Join-Path $PSScriptRoot "install-pyenv-win.ps1")
    Refresh-Path
}

$windowsApps = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps"
$pythonAliases = Get-ChildItem $windowsApps -Filter "python*.exe" -ErrorAction SilentlyContinue
if ($pythonAliases) {
    $pythonAliases | Remove-Item -Force
} else {
    Write-Skipped "Windows Store Python aliases"
}

Refresh-Path
$pythonVersion = "3.14.5"
$pythonPath = Join-Path $env:USERPROFILE ".pyenv\pyenv-win\versions\$pythonVersion"
if (Test-Path -LiteralPath $pythonPath) {
    Write-Skipped "Python $pythonVersion"
} else {
    pyenv install $pythonVersion
}

$previousPreference = $PSNativeCommandUseErrorActionPreference
$PSNativeCommandUseErrorActionPreference = $false
try {
    $globalPython = pyenv global 2>$null | Select-Object -First 1
} finally {
    $PSNativeCommandUseErrorActionPreference = $previousPreference
}
if ($globalPython -eq $pythonVersion) {
    Write-Skipped "pyenv global Python $pythonVersion"
} else {
    pyenv global $pythonVersion
    Refresh-Path
}

$previousPreference = $PSNativeCommandUseErrorActionPreference
$PSNativeCommandUseErrorActionPreference = $false
try {
    python -m pip show termaid 2>$null | Out-Null
    $hasTermaid = $LASTEXITCODE -eq 0
} finally {
    $PSNativeCommandUseErrorActionPreference = $previousPreference
}
if ($hasTermaid) {
    Write-Skipped "Python package termaid"
} else {
    python -m pip install --upgrade pip
    python -m pip install termaid
}

$nvimConfigPath = Join-Path $env:LOCALAPPDATA "nvim"
if (Test-Path -LiteralPath (Join-Path $nvimConfigPath ".git")) {
    Write-Skipped "Neovim configuration"
} else {
    git clone https://github.com/searleser97/nvim_lua $nvimConfigPath
}

$vscodeConfigPath = Join-Path $env:APPDATA "Code\User"
New-Item -ItemType Directory -Path $vscodeConfigPath -Force | Out-Null
Copy-Item `
    -LiteralPath (Join-Path $nvimConfigPath ".wezterm.lua") `
    -Destination (Join-Path $env:USERPROFILE ".wezterm.lua") `
    -Force
Copy-Item `
    -LiteralPath (Join-Path $nvimConfigPath "keybindings.json") `
    -Destination (Join-Path $vscodeConfigPath "keybindings.json") `
    -Force
Copy-Item `
    -LiteralPath (Join-Path $nvimConfigPath "settings.json") `
    -Destination (Join-Path $vscodeConfigPath "settings.json") `
    -Force

$terminalSettings = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$powerShellProfileId = "{574e775e-4f2a-5b96-ac1e-a2962a402336}"
if (Test-Path -LiteralPath $terminalSettings) {
    $settings = Get-Content -LiteralPath $terminalSettings -Raw | ConvertFrom-Json
    if ($settings.defaultProfile -eq $powerShellProfileId) {
        Write-Skipped "Windows Terminal default PowerShell profile"
    } else {
        $settings.defaultProfile = $powerShellProfileId
        $settings | ConvertTo-Json -Depth 100 |
            Set-Content -LiteralPath $terminalSettings -Encoding utf8
    }
}

Install-WingetPackage "GitHub.Copilot"
Install-WingetPackage "GitHub.cli"
