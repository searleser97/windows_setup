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

# nvm install 16
# nvm use 16
