param(
    [Parameter(Mandatory = $true)]
    [string] $Author
)


git log --author="$Author" --pretty="%Cblue%h%Creset (%ch by %Cgreen%an%Creset) %s" -i
