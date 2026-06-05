# Install scoop if not already installed
if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
    irm get.scoop.sh | iex
}

scoop bucket add main
scoop bucket add extras
scoop bucket add versions

scoop install main/git
scoop install main/ripgrep
scoop install main/fd
scoop install main/gcc
scoop install extras/vcredist2022
scoop install fzf

winget install Microsoft.DotNet.SDK.8 --source winget
winget install Microsoft.DotNet.SDK.9 --source winget
winget install Microsoft.DotNet.SDK.10 --source winget
if (!(Get-Command git-credential-manager -ErrorAction SilentlyContinue)) {
    dotnet tool install -g git-credential-manager
}
# C++ build tools required by Rust
winget install Microsoft.VisualStudio.2022.BuildTools --source winget --override "--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.Tools.ARM64 --add Microsoft.VisualStudio.Component.Windows11SDK.22621 --addProductLang En-us"

winget install Rustlang.Rustup --source winget --accept-package-agreements --accept-source-agreements
if (!(Get-Command cargo-binstall -ErrorAction SilentlyContinue)) {
    cargo install cargo-binstall
}
if (!(Get-Command tree-sitter -ErrorAction SilentlyContinue)) {
    cargo binstall tree-sitter-cli -y
}

scoop install versions/neovim-nightly
scoop install extras/vscode
scoop install main/nvm
scoop install delta
scoop install main/grep

# save git credentials in computer
# git config --global credential.helper store
# set nvim as default git editor
git config --global core.editor "nvim"
# auto create branches on remote locally
git config --global push.autoSetupRemote true
# set delta as default pager
git config --global core.pager "delta"

scoop install lazygit

nvm install 24
nvm use 24

if (!(Get-Command mmdc -ErrorAction SilentlyContinue)) {
    npm install -g @mermaid-js/mermaid-cli
}

winget install wez.wezterm --source winget
# install openGL compatibility pack using the app id that we got from runnig `winget search opengl` for windows devbox
# winget install 9NQPSL29BFFF --source winget
 
if (!(Get-Command pyenv -ErrorAction SilentlyContinue)) {
    Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"; &"./install-pyenv-win.ps1"
}

# follow installation instruction from the following link -> https://github.com/microsoft/artifacts-credprovider
# so that I can restore dotnet soludions with `dotnet restore` command without authentication issues
# Basically it installs some sort of artifacts-credprovider and for that, we just need to run the .ps1 script that they mention in the wiki
# but in order to execute it I needed to run `Set-ExecutionPolicy -ExecutionPolicy Unrestricted` first.

pyenv install 3.10.5
pyenv global 3.10.5

# Clone nvim config into default neovim config folder
$nvimConfigPath = "$env:LOCALAPPDATA\nvim"
if (!(Test-Path $nvimConfigPath)) {
    git clone https://github.com/searleser97/nvim_lua $nvimConfigPath
}

# Copy wezterm config to home directory
Copy-Item "$nvimConfigPath\.wezterm.lua" "$env:USERPROFILE\.wezterm.lua"

# Copy vscode config files to default vscode settings folder
Copy-Item "$nvimConfigPath\keybindings.json" "$env:APPDATA\Code\User\keybindings.json"
Copy-Item "$nvimConfigPath\settings.json" "$env:APPDATA\Code\User\settings.json"
