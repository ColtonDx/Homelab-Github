#!/bin/sh
# Builds every kustomization under kubernetes/ and checks it against the Kubernetes schemas and the community CRD catalog; needs kustomize and kubeconform on PATH
set -eu

rendered=$(mktemp)
trap 'rm -f "$rendered"' EXIT

status=0
for file in $(find kubernetes -name kustomization.yaml | sort); do
  dir=$(dirname "$file")
  echo "== $dir"
  # Built to a file first, so a failed build fails the check rather than validating empty output
  if ! kustomize build "$dir" > "$rendered"; then
    status=1
    continue
  fi
  kubeconform -strict -summary -skip CustomResourceDefinition \
    -schema-location default \
    -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
    "$rendered" || status=1
done
exit $status
