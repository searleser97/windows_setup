param(
    [Parameter(Mandatory = $true)]
    [string] $Reference
)

git rev-list "$Reference~1..HEAD" --no-commit-header --pretty="%Cblue%h%Creset (%ch by %Cgreen%an%Creset) %s"
