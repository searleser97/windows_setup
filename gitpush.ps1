$baseBranch = "users/sergiosanc/localConfig"
git rebase --onto main $baseBranch
if (! $?) {
  exit
}
git push --force-with-lease
if (! $?) {
  exit
}
gitrebasemain
