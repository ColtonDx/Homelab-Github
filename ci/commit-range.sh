#!/bin/sh
# Prints the commit range a push or pull request adds, for the scans that read history: BASE_SHA..HEAD_SHA,
# or origin/main..HEAD_SHA when there is no usable base (a new branch, or a first push)
set -eu
head=${HEAD_SHA:-HEAD}
base=${BASE_SHA:-}
if [ -z "$base" ] || [ "$base" = "0000000000000000000000000000000000000000" ] || ! git cat-file -e "$base^{commit}" 2>/dev/null; then
  git fetch --quiet origin main 2>/dev/null || true
  base=$(git merge-base origin/main "$head" 2>/dev/null || true)
fi
# A push to main itself with no previous commit to compare against scans only the pushed commit
[ -n "$base" ] && [ "$base" != "$(git rev-parse "$head")" ] && echo "$base..$head" || echo "$head^!"
