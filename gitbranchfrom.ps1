param(
    [Parameter(Mandatory = $true)]
    [string] $NewBranch,
    [Parameter(Mandatory = $true)]
    [string] $OriginBranch
)

git switch -c $NewBranch $OriginBranch
if (! $?) {
  exit
}
git branch --unset-upstream
