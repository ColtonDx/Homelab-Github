#!/bin/sh
# Fast-forwards main on the remote to the checked-out commit; refuses when main has commits that are not in this one
set -eu

remote=${PROMOTE_REMOTE:-origin}
commit=$(git rev-parse HEAD)

git fetch --quiet "$remote" main

# A diverged main means someone pushed to it directly, which needs a person to sort out
if ! git merge-base --is-ancestor "$remote/main" "$commit"; then
  echo "main has commits that are not on dev; rebase dev onto main and push again"
  exit 1
fi

if [ "$(git rev-parse "$remote/main")" = "$commit" ]; then
  echo "main is already at $commit"
  exit 0
fi

# A plain push is rejected unless it is a fast-forward, so this cannot rewrite main
git push "$remote" "$commit:refs/heads/main"
echo "main fast-forwarded to $commit"
