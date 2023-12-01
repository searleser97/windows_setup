Set-ExecutionPolicy RemoteSigned -Scope CurrentUser # Optional: Needed to run a remote script the first time
irm get.scoop.sh | iex

scoop bucket add main
scoop bucket add extras
scoop bucket add versions

scoop install main/git
scoop install main/ripgrep
scoop install main/fd
scoop install main/gcc
scoop install extras/vcredist2022
scoop install versions/neovim-nightly
scoop install extras/vscode
scoop install main/nvm
scoop install delta

# save git credentials in computer
git config --global credential.helper store
# set nvim as default git editor
git config --global core.editor "nvim"
# auto create branches on remote locally
git config --global push.autoSetupRemote true
# set delta as default pager
git config --global core.pager "delta"

scoop install lazygit

nvm install 16
nvm use 16

winget install Microsoft.DotNet.SDK.6

Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"; &"./install-pyenv-win.ps1"
