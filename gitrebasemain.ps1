$initialBranch = $(git branch --show-current)
$baseBranch = "users/sergiosanc/localConfig"
git fetch origin main:main
if (! $?) {
  exit
}
git switch --ignore-other-worktrees $baseBranch
if (! $?) {
  exit
}
git pull
if (! $?) {
  exit
}
git rebase origin/main
if (! $?) {
  exit
}
git switch $initialBranch
if (! $?) {
  exit
}
git rebase $baseBranch
if (! $?) {
  exit
}
