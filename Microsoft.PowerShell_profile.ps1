# Set-Alias -Name x86_64-w64-mingw32-gcc -Value gcc -Scope Global
Set-PSReadLineKeyHandler -Chord "Tab" -Function ForwardWord
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

$env:FZF_DEFAULT_COMMAND='fd --type d -i'
cd E:\
function sd {
    $dir = $(fzf)
    if ($dir) {
        cd $dir
    }
}
