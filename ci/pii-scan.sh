#!/bin/sh
# Fails when a tracked file matches a private pattern; PII_PATTERNS holds one regex per line, or the path to a file of them (a GitLab File variable)
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

if [ ! -s "$hits" ]; then
  echo "No matches"
  exit 0
fi

while IFS=: read -r file line; do
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    echo "::error file=$file,line=$line::Matches a pattern from PII_PATTERNS"
  else
    echo "$file:$line matches a pattern from PII_PATTERNS"
  fi
done < "$hits"
exit 1
