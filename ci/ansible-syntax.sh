#!/bin/sh
# Syntax-checks every playbook under ansible/; needs ansible-playbook, the pinned collections and python3 with PyYAML on PATH
set -eu

# Playbooks are the files whose top level is a list of plays; task and vars files are checked through the playbooks that load them
playbooks=$(python3 - <<'PY'
import pathlib, yaml
for path in sorted(pathlib.Path("ansible").rglob("*.yaml")):
    doc = yaml.safe_load(path.read_text())
    if isinstance(doc, list) and doc and all(isinstance(p, dict) and ("hosts" in p or "import_playbook" in p or "ansible.builtin.import_playbook" in p) for p in doc):
        print(path)
PY
)

# An empty inventory with the groups the playbooks target, so host patterns resolve without the private inventory
inventory=$(mktemp)
trap 'rm -f "$inventory"' EXIT
printf '[proxmox]\n[talos_cluster]\n[k3s_nodes]\n[linux]\n[docker]\n[firewalls]\n' > "$inventory"

status=0
for playbook in $playbooks; do
  ansible-playbook -i "$inventory" --syntax-check "$playbook" || status=1
done
exit $status
