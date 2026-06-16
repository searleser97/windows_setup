Set-PSReadLineOption -EditMode Vi
# Set-Alias -Name x86_64-w64-mingw32-gcc -Value gcc -Scope Global
# Set-PSReadLineKeyHandler -Chord "Tab" -Function ForwardWord
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

# Use x64 .NET SDK (ARM64 translation layer)
$env:DOTNET_ROOT = "C:\Program Files\dotnet\x64"
$env:PATH = "C:\Program Files\dotnet\x64;$env:PATH"

if ($PWD.Path -eq $HOME -and $args.Count -eq 0 -and -not $Host.CurrentCommandParameter) {
    cd E:\
}

function sd {
    $env:FZF_DEFAULT_COMMAND='fd --type d -i -H -d 13'
    $dir = $(fzf)
    if ($dir) {
        cd $dir
    }
}

function sf {
    $env:FZF_DEFAULT_COMMAND='fd --type f -i -H -d 13'
    $file = $(fzf)
    if ($file) {
        $dir = Split-Path -Parent $file
        cd $dir
    }
}
