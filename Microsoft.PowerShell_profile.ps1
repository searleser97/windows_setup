Set-Alias -Name x86_64-w64-mingw32-gcc -Value gcc -Scope Global
Set-PSReadLineKeyHandler -Chord "Tab" -Function ForwardWord
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

$env:FZF_DEFAULT_COMMAND='fd --type d'

function sd {
    cd $(fzf)
}

Set-Alias gitlogsince $HOME\windows_setup\gitlogsince.ps1
Set-Alias gitbranchfrom $HOME\windows_setup\gitbranchfrom.ps1
Set-Alias gitlogauthor $HOME\windows_setup\gitlogauthor.ps1
Set-Alias gitrebasemain $HOME\windows_setup\gitrebasemain.ps1
Set-Alias gitpush $HOME\windows_setup\gitpush.ps1
Set-Alias gitlogtree $HOME\windows_setup\gitlogtree.ps1
