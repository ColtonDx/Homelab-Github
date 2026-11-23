# Pinned versions

What is pinned to an exact version, what deliberately is not, and why. Change a pin with a pull request that updates the version and its digest or checksum together.

## Why pin at all

- **Supply chain:** a pin by digest or checksum means a moved tag or a tampered download cannot change what runs. A mismatch fails the deploy or install instead of running unknown code.
- **No surprise upgrades:** stacks that hold secrets or data only upgrade when someone reads the release notes and merges the change, never at an unattended re-pull. Databases are pinned so an image update can never jump a major version on existing data files.
- **Matching pairs:** some components must stay in step, e.g. the Semaphore runner with the Semaphore server.

The cost is that fixes arrive only when merged, so pins are reviewed for updates monthly.

## Docker images

### Pinned by version and digest

These hold secrets, credentials or data that an unattended update could break. Each was pinned to the image already running, so pinning changed no versions.

| Stack | Image | Version | Why |
|---|---|---|---|
| vaultwarden | vaultwarden/server | 1.37.5 | Password vault |
| 2fauth | 2fauth/2fauth | 9.0.2 | Two-factor secrets |
| nextcloud | lscr.io/linuxserver/nextcloud | 35.0.3-ls4 | User files; upgrades run database migrations |
| bookstack | lscr.io/linuxserver/bookstack | v26.09.3-ls300 | Documentation; upgrades run database migrations |
| bookstack | lscr.io/linuxserver/mariadb | 11.8.10-r0-ls241 | Database: a major-version jump can refuse the existing data |
| netbox | lscr.io/linuxserver/netbox | v4.7.5-ls393 | Source of truth for the network; upgrades run migrations |
| semaphore | semaphoreui/semaphore | v2.20.24 | Holds infrastructure credentials; the runner must match its version |
| gitlab-runner | gitlab/gitlab-runner | v19.6.0 | Runs CI jobs with Docker access |
| garage | dxflrs/garage | v2.2.0 | Holds Terraform state and backups |
| garage | khairul169/garage-webui | 1.1.0 | Admin access to that storage |
| docker-socket-proxy, homepage | wollomatic/socket-proxy | 1.13.2 | Filters access to the Docker API; a bad build would expose it |

Portainer's image re-pull should be off for these stacks: their images cannot change without a commit, so re-pulling only adds traffic.

### Pinned to a version tag

Databases and caches pinned to a major or minor version: patch releases within it are safe and arrive on redeploy.

| Stack | Image | Tag |
|---|---|---|
| netbox | postgres | 18.7 |
| netbox | redis | 7-alpine |
| semaphore | postgres | 14 |
| karakeep | getmeili/meilisearch | v1.13.3 |
| searxng | valkey/valkey | 9-alpine |
| cryptpad | cryptpad/cryptpad | version-2025.3.0 |

### Following `latest` on purpose

- **Images built in our own development group** (WorkSuite, Docker Volume Backup Manager): they track `latest` so Portainer's GitOps re-pull deploys each release automatically.
- **Stateless or low-stakes tools** (it-tools, excalidraw, omni-tools, searxng, kiwix, changedetection, withoutbg, aerofoil, homebox, karakeep, homepage, nginx-proxy-manager): a bad update costs a restart or a rollback, not data, and staying current brings their fixes without extra work.

## Other pinned downloads

Each is verified against a sha256 or fingerprint recorded in this repository, not one fetched from the same server as the file.

| What | Version | Pinned in | Verified by |
|---|---|---|---|
| acme.sh | 3.1.6 | `ansible/playbooks/tls/vars/acme-sh.yaml` | sha256 of the release archive |
| Kasm Workspaces | 1.19.0 | `ansible/playbooks/deployment/app-kasm.yaml` | sha256 per release in `kasm_release_checksums` |
| Semaphore runner | 2.20.23 | `ansible/playbooks/deployment/semaphore-runner.yaml` | sha256 per version and CPU in `runner_checksums` |
| Terraform (runner) | 1.16.4 | same | sha256 from HashiCorp's GPG-signed checksum list |
| talosctl, kubectl (runner) | 1.14.1, 1.37.1 | same | sha256 per version and CPU |
| Proxmox Terraform provider | 3.0.2-rc06 | `.terraform.lock.hcl` in each `terraform/proxmox/*` project | provider hashes for every platform |
| Monitoring stack (Grafana, Loki, Prometheus, Alloy, Proxmox exporter) | see role defaults | `ansible/roles/monitoring_server/defaults/main.yaml`, `ansible/roles/monitoring_client/defaults/main.yaml` | exact version tags; Alloy packages from Grafana's signed APT repository |
| APT repository keys (Docker, Grafana, HashiCorp, GitLab) | n/a | `apt_key_fingerprints` where each key is added | key fingerprint, checked by `ansible/tasks/apt_signing_key.yaml` |

The Semaphore runner is one patch release behind the server because the server's version has no published runner binaries; move the runner to the server's version once it is released.

## Updating a pin

1. Pick a release that has been published for at least two weeks, and read its release notes.
2. Get the new digest (`docker buildx imagetools inspect <image>:<tag>`) or checksum from the publisher, and update the version and digest or checksum together.
3. For stacks, merging redeploys through GitOps; take a backup first for stacks with data.
4. Update the tables above in the same pull request.
