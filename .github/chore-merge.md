# Chore PR merge
 
- Ensure that `admin` is on the same commit of `master` before merging the PR. If it's not, then move it there, and add a comment in the PR with the content `@dependabot rebase` and wait for its execution
- Proceed to the PR merge with "Squash and merge", leaving the title but removing the whole description
- Check whether the workflow went well for the `admin` branch
- Fast forward `master` to `admin`
- (dd only) If needed: rebase `dev` on the new `master` and check the `dev` workflow