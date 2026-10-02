#!/bin/sh
# Checks formatting for the whole terraform/ tree, then runs init and validate per project without a backend or credentials
set -eu

terraform fmt -check -recursive -diff terraform

# One provider download shared by every project, so a run makes as few registry requests as possible
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-${TMPDIR:-/tmp}/terraform-plugin-cache}"
mkdir -p "$TF_PLUGIN_CACHE_DIR"

status=0
for dir in terraform/*/*/; do
  echo "== $dir"
  # The registry occasionally fails a download, so init gets three tries before the project counts as broken
  attempt=1
  until terraform -chdir="$dir" init -backend=false -input=false; do
    if [ "$attempt" -ge 3 ]; then
      echo "init failed three times for $dir"
      status=1
      continue 2
    fi
    attempt=$((attempt + 1))
    echo "init failed, retrying in 10 seconds (attempt $attempt of 3)"
    sleep 10
  done
  terraform -chdir="$dir" validate || status=1
done
exit $status
