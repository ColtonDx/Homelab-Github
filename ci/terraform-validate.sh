#!/bin/sh
# Checks formatting for the whole terraform/ tree, then runs init and validate per project without a backend or credentials
set -eu

terraform fmt -check -recursive -diff terraform

status=0
for dir in terraform/*/*/; do
  echo "== $dir"
  terraform -chdir="$dir" init -backend=false -input=false || status=1
  terraform -chdir="$dir" validate || status=1
done
exit $status
