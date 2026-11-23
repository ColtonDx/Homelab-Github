#!/bin/sh
# Optional git pre-push hook: runs the PII scan and, when installed, gitleaks over the commits being pushed, before they reach the public remote
# Install: ln -s ../../ci/pre-push.sh .git/hooks/pre-push
# Patterns: PII_PATTERNS (as in CI), or a file at ~/.config/homelab/pii-patterns with one regex per line
set -eu
zero=0000000000000000000000000000000000000000
[ -n "${PII_PATTERNS:-}" ] || { [ -f "$HOME/.config/homelab/pii-patterns" ] && PII_PATTERNS="$HOME/.config/homelab/pii-patterns"; } || true
export PII_PATTERNS="${PII_PATTERNS:-}"
status=0

# git passes one line per ref: local ref, local sha, remote ref, remote sha
while read -r _local_ref local_sha _remote_ref remote_sha; do
  [ "$local_sha" = "$zero" ] && continue # a branch deletion pushes no commits
  range=$(BASE_SHA="$( [ "$remote_sha" = "$zero" ] && echo "" || echo "$remote_sha")" HEAD_SHA="$local_sha" sh ci/commit-range.sh)
  PII_RANGE="$range" sh ci/pii-scan.sh || status=1
  if command -v gitleaks >/dev/null 2>&1; then
    # gitleaks 8.19 renamed "detect" to "git"; either works here
    if gitleaks git --help >/dev/null 2>&1; then sub=git; else sub=detect; fi
    gitleaks "$sub" --redact --no-banner --log-opts="$range" . || status=1
  else
    echo "gitleaks is not installed, so only the PII scan ran"
  fi
done

[ "$status" -eq 0 ] || echo "Push blocked: fix the commits above (or push with --no-verify if a finding is a false positive)"
exit "$status"
