$ErrorActionPreference = "Stop"
$initialBranch = $(git branch --show-current)
$baseBranch = "users/sergiosanc/localConfig"
git fetch origin main:main
git switch --ignore-other-worktrees $baseBranch
git pull
git rebase origin/main
git switch $initialBranch
git rebase $baseBranch
$ErrorActionPreference = "Continue"
