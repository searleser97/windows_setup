param(
    [Parameter(Mandatory = $true)]
    [string] $From,
    [Parameter(Mandatory = $false)]
    [string] $To
)

if (! $To) {
  $To = "HEAD"
}

$FromDate=git show --no-patch --format=%ci $From
$ToDate=git show --no-patch --format=%ci $To

git log --since="$FromDate" --until="$ToDate" --pretty="%Cblue%h%Creset (%ch by %Cgreen%an%Creset) %s"
