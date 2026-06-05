# Install scoop if not already installed
if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
    irm get.scoop.sh | iex
}

function Install-ScoopApp($app) {
    if (!(scoop list $app 2>$null | Select-String $app.Split("/")[-1])) {
        scoop install $app
    }
}

scoop bucket add main
scoop bucket add extras
scoop bucket add versions

Install-ScoopApp main/git
Install-ScoopApp main/ripgrep
Install-ScoopApp main/fd
Install-ScoopApp main/gcc
Install-ScoopApp extras/vcredist2022
Install-ScoopApp fzf

winget install Microsoft.DotNet.SDK.8 --source winget
winget install Microsoft.DotNet.SDK.9 --source winget
winget install Microsoft.DotNet.SDK.10 --source winget
if (!(Get-Command git-credential-manager -ErrorAction SilentlyContinue)) {
    dotnet tool install -g git-credential-manager
}
# C++ build tools required by Rust
winget install Microsoft.VisualStudio.BuildTools --source winget --override "--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.Tools.ARM64 --add Microsoft.VisualStudio.Component.Windows11SDK.22621 --addProductLang En-us"
Install-ScoopApp main/llvm

winget install Rustlang.Rustup --source winget --accept-package-agreements --accept-source-agreements
$cargoBin = "$env:USERPROFILE\.cargo\bin"
if (!(Test-Path "$cargoBin\cargo-binstall.exe")) {
    cargo install cargo-binstall
}
if (!(Test-Path "$cargoBin\tree-sitter.exe")) {
    cargo binstall tree-sitter-cli -y
}

Install-ScoopApp versions/neovim-nightly
Install-ScoopApp extras/vscode
Install-ScoopApp main/nvm
Install-ScoopApp delta
Install-ScoopApp main/grep

# save git credentials in computer
# git config --global credential.helper store
# set nvim as default git editor
git config --global core.editor "nvim"
# auto create branches on remote locally
git config --global push.autoSetupRemote true
# set delta as default pager
git config --global core.pager "delta"

Install-ScoopApp lazygit

nvm install 24
nvm use 24
# Find the highest node v24.x.x version directory
$nodeDir = Get-ChildItem "$env:USERPROFILE\scoop\persist\nvm\nodejs" -Directory | Where-Object { $_.Name -match '^v24' } | Sort-Object { [version]($_.Name -replace '^v','') } -Descending | Select-Object -First 1
if ($nodeDir) {
    $env:Path = "$($nodeDir.FullName);$env:Path"
    npm install -g @mermaid-js/mermaid-cli
} else {
    Write-Warning "No node v24 found in scoop persist nvm"
}

winget install wez.wezterm --source winget
# install openGL compatibility pack using the app id that we got from runnig `winget search opengl` for windows devbox
# winget install 9NQPSL29BFFF --source winget
 
if (!(Get-Command pyenv -ErrorAction SilentlyContinue)) {
    Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"; &"./install-pyenv-win.ps1"
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# follow installation instruction from the following link -> https://github.com/microsoft/artifacts-credprovider
# so that I can restore dotnet soludions with `dotnet restore` command without authentication issues
# Basically it installs some sort of artifacts-credprovider and for that, we just need to run the .ps1 script that they mention in the wiki
# but in order to execute it I needed to run `Set-ExecutionPolicy -ExecutionPolicy Unrestricted` first.

$installedVersions = pyenv versions 2>$null
if ($installedVersions -notmatch "3.10.5") {
    pyenv install 3.10.5
}
pyenv global 3.10.5
pip install termaid

# Clone nvim config into default neovim config folder
$nvimConfigPath = "$env:LOCALAPPDATA\nvim"
if (!(Test-Path $nvimConfigPath)) {
    git clone https://github.com/searleser97/nvim_lua $nvimConfigPath
}

# Copy wezterm config to home directory
Copy-Item "$nvimConfigPath\.wezterm.lua" "$env:USERPROFILE\.wezterm.lua"

# Copy vscode config files to default vscode settings folder
$vscodeConfigPath = "$env:APPDATA\Code\User"
New-Item -ItemType Directory -Path $vscodeConfigPath -Force | Out-Null
Copy-Item "$nvimConfigPath\keybindings.json" "$vscodeConfigPath\keybindings.json"
Copy-Item "$nvimConfigPath\settings.json" "$vscodeConfigPath\settings.json"

# Set PowerShell 7 as default Windows Terminal profile
$wtSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $wtSettings) {
    $settings = Get-Content $wtSettings | ConvertFrom-Json
    $settings.defaultProfile = "{574e775e-4f2a-5b96-ac1e-a2962a402336}"
    $settings | ConvertTo-Json -Depth 100 | Set-Content $wtSettings
}
