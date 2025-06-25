winget install --id Microsoft.PowerShell --source winget
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser # Optional: Needed to run a remote script the first time
irm get.scoop.sh | iex
# install chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

scoop bucket add main
scoop bucket add extras
scoop bucket add versions

scoop install main/git
scoop install main/ripgrep
scoop install main/fd
scoop install main/gcc
scoop install extras/vcredist2022
scoop install fzf

winget install Microsoft.DotNet.SDK.8
dotnet tool install -g git-credential-manager

# scoop install versions/neovim-nightly
choco install neovim --pre
scoop install extras/vscode
scoop install main/nvm
scoop install delta
scoop install main/grep

# save git credentials in computer
git config --global credential.helper store
# set nvim as default git editor
git config --global core.editor "nvim"
# auto create branches on remote locally
git config --global push.autoSetupRemote true
# set delta as default pager
git config --global core.pager "delta"

scoop install lazygit

nvm install 22
nvm use 22

winget install wez.wezterm
# install openGL compatibility pack using the app id that we got from runnig `winget search opengl`
winget install 9NQPSL29BFFF
 
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"; &"./install-pyenv-win.ps1"

# follow installation instruction from the following link -> https://github.com/microsoft/artifacts-credprovider
# so that I can restore dotnet soludions with `dotnet restore` command without authentication issues
# Basically it installs some sort of artifacts-credprovider and for that, we just need to run the .ps1 script that they mention in the wiki
# but in order to execute it I needed to run `Set-ExecutionPolicy -ExecutionPolicy Unrestricted` first.

pyenv install 3.10.5
pyenv global 3.10.5
