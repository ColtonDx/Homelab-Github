# Monitoring

How the homelab notices problems, what each tool watches, and how it tells someone. Every alert ends in Discord.

| Layer | Tool | Watches | Alerts through |
|---|---|---|---|
| Metrics and logs | Grafana, Prometheus, Loki, fed by Grafana Alloy | Host resources, disks, failed services, kernel and SSH logs, Proxmox, the firewall, syslog from network gear | Grafana alert rules → Discord |
| Up or down | Uptime Kuma | Every app URL, container, host and device that answers on the network | Kuma notifications → Discord |
| Automation | Semaphore | Scheduled jobs: backups, syncs, drift checks | Semaphore \| Scheduled Job Alerts → Discord |
| Drift | Scheduled jobs | Switch config against the inventory | A failed scheduled run → Discord |
| At a glance | Homepage | Status dots on every tile | None (visual only) |

## Metrics and logs (Grafana stack)

One monitoring server runs Grafana, Prometheus, Loki and Alloy in Docker, built by `terraform/proxmox/monitoring` and installed by `ansible/playbooks/deployment/app-monitoring.yaml` (role `monitoring_server`). Logs and metrics are kept for `monitoring_server_retention_days` (30).

**What feeds it**

| Source | How | Set up by |
|---|---|---|
| Linux hosts and the Proxmox nodes | Grafana Alloy on each host pushes metrics (CPU, memory, disk, network, systemd units) and the journal, plus container logs on Docker hosts | `deployment/monitoring-client.yaml` (role `monitoring_client`) for every host in the inventory's `monitoring_clients` group; the Proxmox nodes are reached with their Vault-signed SSH certificate |
| Proxmox cluster | A Proxmox exporter reads the API with a read-only token: every node and guest | `monitoring_server_pve_targets` |
| Firewall | An OPNsense exporter reads the API (interfaces, gateways, firewall, Unbound, DHCP); firewall logs arrive as syslog and are parsed into action, direction and interface labels, with a country label on outbound WAN traffic when GeoIP is on | `monitoring_server_opnsense_*`, `monitoring_server_filterlog_wan_interfaces`, `monitoring_server_geoip` |
| Network gear | Syslog to Alloy on the server: RFC 3164 on UDP 514, RFC 5424 on UDP and TCP 5514 | `monitoring_server_syslog_listeners`; the ICX switch's `logging host` line is in its inventory config (`network/icx-config.yaml`) |
| Other services | Extra Prometheus scrape jobs | `monitoring_server_scrape_jobs` |

Hosts push over HTTPS through a gateway on the server: the `push` user may only send, the `read` user may only query, and both passwords come from Vault.

**Alert rules** (`roles/monitoring_server/templates/grafana/alert-rules.yaml.j2`). Each alert says what is wrong, where, and the first thing to check.

| Alert | Fires when | Waits |
|---|---|---|
| Host stopped reporting | A host's Alloy has sent no metrics; clears 24 hours after the host last reported, so a retired host stops alerting | 5 min |
| Disk almost full | A local filesystem (ext4, xfs, btrfs, zfs) is over 90% | 15 min |
| Monitoring target down | Prometheus cannot scrape one of its targets (an exporter or the stack itself) | 5 min |
| Process killed for memory | The kernel's out-of-memory killer ran | immediately |
| Disk or filesystem errors | The kernel logs I/O or filesystem errors | immediately |
| Service failed | A systemd unit entered the failed state | immediately |
| Repeated SSH login failures | Many failed SSH logins on one host in 10 minutes | immediately |
| Site log alerts | Each entry in the inventory's `monitoring_server_log_alerts`: a LogQL count above its threshold | per alert |

**Routing** (`alerting.yaml.j2`): one Discord contact point, with the webhook from Vault. Alerts are grouped by alert name and host, so one problem on one host is one message; a still-firing alert repeats every 4 hours.

Dashboards are built in Grafana's own UI and are not kept in this repo; data sources, alert rules and routing are.

## Up or down (Uptime Kuma)

The **Uptime Kuma | GitOps** job makes Kuma match Git every 3 hours. Monitors come from three places:

- **Apps:** labels on each service in `docker/*/docker-compose.yaml`: an HTTP check of the app's URL and a container check on its Docker host. See [docker/uptime-kuma.md](docker/uptime-kuma.md).
- **Hosts and devices:** `kuma_monitor` on inventory hosts: HTTP, ping, port or DNS checks, e.g. for VMs without a web UI, Windows servers and network gear. See [inventory/uptime-kuma.md](inventory/uptime-kuma.md).
- **Anything else:** `kuma_manual_monitors` in the inventory.

Each top-level Kuma group gets its Discord notifications from the inventory's `kuma_group_notifications`. Every monitor the sync manages carries a Kuma tag, `iac`. Each run reports tagged monitors the code no longer defines, and with `kuma_prune: true` in the inventory it deletes them (at most `kuma_prune_max`, default 5, per run). Monitors made by hand in Kuma have no tag and are never touched. Linux patching opens a Kuma maintenance window for each host it reboots, so planned restarts stay quiet.

## Scheduled jobs (Semaphore)

**Semaphore | Scheduled Job Alerts** runs every 15 minutes and watches every template that has an active schedule. It posts once when a job starts failing, once when it recovers, and once when a run hangs far longer than usual, rather than once per failed run. Anything put on a schedule is covered automatically, including backups, the NetBox sync and the drift checks below.

## Drift checks

- **Switch config:** **Network | ICX Config Drift** runs daily with `fail_on_drift=true` and compares the switch's running config with its inventory definition; a hand-made change fails the run and reaches Discord through the scheduled job alerts.
- **Terraform:** a `plan` of each project shows any difference between a VM and its code.

## At a glance (Homepage)

Every Homepage tile has a status dot: the container's state for apps Homepage can see over the Docker API, or a check of the link (`siteMonitor`) for everything else. It is for looking at, not alerting; Kuma covers the same things with notifications.

## Adding something

| New thing | Do this |
|---|---|
| Linux VM | Add it to `monitoring_clients` (through the `ssh` group) and run Monitoring \| Clients; give it `kuma_monitor` if it should also be pinged |
| Docker app | Add the `Kuma.*` labels (and `AppPort`) in its compose file; Homepage and Kuma pick it up |
| Device or appliance | `kuma_monitor` on its inventory host; point its syslog at the monitoring server if it can send one |
| Exporter or scrape target | `monitoring_server_scrape_jobs`, then rerun app-monitoring |
| Log-based alert | An entry in `monitoring_server_log_alerts` |
| Scheduled job | A Semaphore schedule; the job alerts follow on their own |

## Not covered by agents

Storage appliances and Windows servers run no Alloy agent: they are watched by Kuma, and Proxmox's exporter reports their VMs' resource use from the hypervisor's side.
