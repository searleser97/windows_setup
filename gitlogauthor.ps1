param(
    [Parameter(Mandatory = $true)]
    [string] $Author
)


git log --author="$Author" --pretty=oneline --abbrev-commit -i
