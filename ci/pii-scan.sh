#!/bin/sh
# Fails when a tracked file, or a line added or an author or committer in the commits of this push, matches a private pattern
# PII_PATTERNS holds one regex per line, or the path to a file of them; PII_RANGE (from ci/commit-range.sh) limits the history part, which is skipped when unset
set -eu

if [ -z "${PII_PATTERNS:-}" ]; then
  echo "PII_PATTERNS is not available to this run, so the scan was skipped"
  [ -n "${GITHUB_ACTIONS:-}" ] && echo "::warning::PII_PATTERNS is not available to this run, so the scan was skipped"
  exit 0
fi

patterns=$(mktemp)
hits=$(mktemp)
trap 'rm -f "$patterns" "$hits"' EXIT

# Blank lines would match everything, so they are dropped
if [ -f "$PII_PATTERNS" ]; then
  sed '/^[[:space:]]*$/d' "$PII_PATTERNS" > "$patterns"
else
  printf '%s\n' "$PII_PATTERNS" | sed '/^[[:space:]]*$/d' > "$patterns"
fi

# Only file and line are kept, never the match, since a public repo's CI logs are public too; safe.directory covers checkouts owned by another user in a container
git -c safe.directory="$PWD" grep -nIiE -f "$patterns" | cut -d: -f1,2 > "$hits" || true

# History: every commit in the range, so a value added in one commit and removed in the next is still caught, and commit metadata too
if [ -n "${PII_RANGE:-}" ]; then
  for commit in $(git -c safe.directory="$PWD" rev-list "$PII_RANGE"); do
    short=$(git -c safe.directory="$PWD" rev-parse --short "$commit")
    if git -c safe.directory="$PWD" log -1 --format='%an%n%ae%n%cn%n%ce' "$commit" | grep -qiE -f "$patterns"; then
      echo "commit $short:author or committer" >> "$hits"
    fi
    git -c safe.directory="$PWD" diff-tree --no-commit-id --name-only -r --root "$commit" | while IFS= read -r file; do
      if git -c safe.directory="$PWD" show --format= --no-color -U0 "$commit" -- "$file" | sed -n 's/^+//p' | grep -v '^++ ' | grep -qiE -f "$patterns"; then
        echo "commit $short $file:added line" >> "$hits"
      fi
    done
  done
fi

if [ ! -s "$hits" ]; then
  echo "No matches"
  exit 0
fi

# History hits name the commit (and file), current-file hits the file and line; never the match itself
while IFS=: read -r file line; do
  case $file in
    commit\ *) msg="$file ($line) matches a pattern from PII_PATTERNS" ;;
    *) msg="$file:$line matches a pattern from PII_PATTERNS" ;;
  esac
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    case $file in commit\ *) echo "::error::$msg" ;; *) echo "::error file=$file,line=$line::Matches a pattern from PII_PATTERNS" ;; esac
  else
    echo "$msg"
  fi
done < "$hits"
exit 1
