# monitoring

Builds the VM for central logging and monitoring: Grafana, Loki, Prometheus and a syslog receiver. Clients ship logs and metrics to it with Grafana Alloy; devices that can't run an agent send syslog.

Run it through `ansible/playbooks/terraform/build-project.yaml` (the "Terraform | Project Runner" template), which reads the inventory host named in `sources.yaml` and the Proxmox credentials from Vault.

| File | Purpose |
|---|---|
| `main.tf` | The VM, cloned from a cloud-init template, with a static address |
| `variables.tf` | Size, placement and network settings |
| `outputs.tf` | Address and VMID, and the record NetBox gets after an apply |
| `sources.yaml` | Where build-project.yaml finds the state key, secrets and inventory host |

The software is installed by a separate playbook, added to `sources.yaml` as the install entry once it exists.
