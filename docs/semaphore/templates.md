# Semaphore

Copies of the Semaphore task templates that run this repo's playbooks, plus the Proxmox template build from the PACT repo, one file per template in [templates/](../../semaphore/templates/). They record how each job is set up, so a lost or rebuilt Semaphore project can be recreated from them.

Site-specific values are left out: survey defaults and choices that held a domain, a user name or a host list are replaced with generic examples, and Semaphore's numeric IDs are replaced with the names of the resources below.

## Project resources

Each template names these by their Semaphore name. Create them first when rebuilding the project.

| Kind | Name | What it is |
|---|---|---|
| Repository | Github-Homelab | This repo, branch `main` |
| Repository | Proxmox PACT Github | [Proxmox-P.A.C.T.](https://github.com/ColtonDx/Proxmox-P.A.C.T.), which builds the VM templates the Terraform projects clone |
| Inventory | Gitlab Ansible Inventory | The private inventory repo's `inventory/` folder, type File |
| Environment | Hashicorp Secrets | Vault access and service URLs, listed below |
| Environment | Proxmox-PACT-Variables | Variables for the PACT build script; see that repo for what it reads |
| Environment | Empty | No variables, for jobs that need nothing from Vault |
| View | Proxmox, Kubernetes, Netbox, Backups | Tabs that group the templates; templates with no view show under All |

### Hashicorp Secrets

Only these environment variables reach a job, so everything else comes from the inventory or from Vault.

| Variable | Secret | Used by |
|---|---|---|
| `VAULT_ADDR` | No | Every job that reads Vault |
| `VAULT_TOKEN` | Yes | Every job that reads Vault |
| `VAULT_KV_MOUNT` | No | Every job that reads Vault |
| `PORTAINER_URL` | No | Portainer jobs |
| `NPM_URL` | No | Portainer Stack Creation, when adding a proxy host |
| `DVBM_URL` | No | Portainer jobs and Backup \| DVBM Job |
| `GARAGE_URL` | No | Terraform jobs, for the S3 state backend |
| `UPTIME_KUMA_URL` | No | Optional; overrides the default `https://kuma.<docker_domain>` for Uptime Kuma monitors, and is itself overridden by `uptime_kuma_url` in the inventory |

Optional: `NETBOX_URL` is the fallback when the inventory has no `netbox_url`, for the NetBox jobs and Terraform's NetBox lookups; `NETBOX_CLUSTER_NAME` overrides the cluster name for Netbox | Sync.

## Templates

| Template | View | File | Playbook |
|---|---|---|---|
| Proxmox \| PACT Github | Proxmox | [proxmox-pact-github.yaml](../../semaphore/templates/proxmox-pact-github.yaml) | `Scripts/build.sh` in the PACT repo |
| Proxmox \| Configure Nodes | Proxmox | [proxmox-configure-nodes.yaml](../../semaphore/templates/proxmox-configure-nodes.yaml) | `ansible/playbooks/proxmox/configure-proxmox.yaml` |
| Proxmox \| Terraform - Build a PVE VM | Proxmox | [proxmox-terraform-build-a-pve-vm.yaml](../../semaphore/templates/proxmox-terraform-build-a-pve-vm.yaml) | `ansible/playbooks/terraform-adhoc-vm/build-vm.yaml` |
| Proxmox \| Terraform - Delete PVE VM | Proxmox | [proxmox-terraform-delete-pve-vm.yaml](../../semaphore/templates/proxmox-terraform-delete-pve-vm.yaml) | `ansible/playbooks/terraform-adhoc-vm/delete-vm.yaml` |
| Proxmox \| Update Nodes | Proxmox | [proxmox-update-nodes.yaml](../../semaphore/templates/proxmox-update-nodes.yaml) | `ansible/playbooks/proxmox/update-proxmox.yaml` |
| Terraform \| Project Runner | Proxmox | [terraform-project-runner.yaml](../../semaphore/templates/terraform-project-runner.yaml) | `ansible/playbooks/terraform/build-project.yaml` |
| Netbox \| Seed | Netbox | [netbox-seed.yaml](../../semaphore/templates/netbox-seed.yaml) | `ansible/playbooks/netbox/seed.yaml` |
| Netbox \| Sync | Netbox | [netbox-sync.yaml](../../semaphore/templates/netbox-sync.yaml) | `ansible/playbooks/netbox/sync-netbox.yaml` |
| Backup \| DVBM Job | Backups | [backup-dvbm-job.yaml](../../semaphore/templates/backup-dvbm-job.yaml) | `ansible/playbooks/backups/dvbm-backup.yaml` |
| Backup \| Gitlab | Backups | [backup-gitlab.yaml](../../semaphore/templates/backup-gitlab.yaml) | `ansible/playbooks/backups/gitlab-backup.yaml` |
| Backup \| Plex | Backups | [backup-plex.yaml](../../semaphore/templates/backup-plex.yaml) | `ansible/playbooks/backups/plex-backup.yaml` |
| Host \| Docker | (none) | [host-docker.yaml](../../semaphore/templates/host-docker.yaml) | `ansible/playbooks/deployment/host-docker.yaml` |
| Host \| Dev | (none) | [host-dev.yaml](../../semaphore/templates/host-dev.yaml) | `ansible/playbooks/deployment/host-dev.yaml` |
| Linux Disk Utilization Check | (none) | [linux-disk-utilization-check.yaml](../../semaphore/templates/linux-disk-utilization-check.yaml) | `ansible/playbooks/maintenance/disk-usage-alert.yaml` |
| Linux Updates | (none) | [linux-updates.yaml](../../semaphore/templates/linux-updates.yaml) | `ansible/playbooks/maintenance/update-linux.yaml` |
| Portainer Stack Creation | (none) | [portainer-stack-creation.yaml](../../semaphore/templates/portainer-stack-creation.yaml) | `ansible/playbooks/portainer/deploy-stack.yaml` |
| Portainer Stack Update | (none) | [portainer-stack-update.yaml](../../semaphore/templates/portainer-stack-update.yaml) | `ansible/playbooks/portainer/update-stack.yaml` |
| Portainer \| Push Config | (none) | [portainer-push-config.yaml](../../semaphore/templates/portainer-push-config.yaml) | `ansible/playbooks/portainer/push-config.yaml` |
| Semaphore \| Scheduled Job Alerts | (none) | [semaphore-scheduled-job-alerts.yaml](../../semaphore/templates/semaphore-scheduled-job-alerts.yaml) | `ansible/playbooks/semaphore/scheduled-job-alerts.yaml` |
| SSH Key Rotation | (none) | [ssh-key-rotation.yaml](../../semaphore/templates/ssh-key-rotation.yaml) | `ansible/playbooks/maintenance/rotate-ssh-keys.yaml` |
| TLS \| Renew Certificates | (none) | [tls-renew-certificates.yaml](../../semaphore/templates/tls-renew-certificates.yaml) | `ansible/playbooks/tls/renew-certificates.yaml` |
| Uptime Kuma \| Sync Monitors | (none) | [uptime-kuma-sync-monitors.yaml](../../semaphore/templates/uptime-kuma-sync-monitors.yaml) | `ansible/playbooks/uptime-kuma/sync-monitors.yaml` |
| Uptime Kuma \| Maintenance Window | (none) | [uptime-kuma-maintenance-window.yaml](../../semaphore/templates/uptime-kuma-maintenance-window.yaml) | `ansible/playbooks/uptime-kuma/set-maintenance-window.yaml` |
| OPNsense \| Reserve IP | (none) | [opnsense-dnsmasq-reserve-ip.yaml](../../semaphore/templates/opnsense-dnsmasq-reserve-ip.yaml) | `ansible/playbooks/opnsense/dnsmasq-reserve-ip.yaml` |
| Network \| ICX Facts | (none) | [network-icx-facts.yaml](../../semaphore/templates/network-icx-facts.yaml) | `ansible/playbooks/network/icx-facts.yaml` |

## File format

Each file follows the fields of Semaphore's template API (`/api/project/{id}/templates`), with names in place of IDs:

- `repository`, `inventory`, `environments` and `view` name the resources above.
- `arguments` are extra command-line arguments, such as a fixed `-e tf_project=...`.
- `task_params` and `allow_override_args_in_task` control what can be changed when starting a task.
- `allow_override_branch_in_task` lets a task run another branch of the repository than its default (`main`); I only use it for check-mode runs of a PR branch before merge.
- `survey_vars` are the questions asked when starting a task; for an Ansible template each answer becomes an extra variable of the same name, and for a Bash template the survey name is the script's flag, such as `--proxmox-host`.

Templates for jobs that still run from the old GitLab repo (Build Container Registry Image) are not copied here until their playbooks move to this repo.
