Set-Alias -Name x86_64-w64-mingw32-gcc -Value gcc -Scope Global
Set-PSReadLineKeyHandler -Chord "Tab" -Function ForwardWord
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-Alias gitlogsince $HOME\windows_setup\gitlogsince.ps1
Set-Alias gitbranchfrom $HOME\windows_setup\gitbranchfrom.ps1
