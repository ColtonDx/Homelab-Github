# Uptime Kuma

Read by the **Uptime Kuma | GitOps** job, which creates a monitor for every host with `kuma_monitor` (apps get theirs from `Kuma.*` labels in their compose files), and by Linux patching, which silences a host's monitors while it reboots.

## Per host

`kuma_monitor`: `true` pings the host, a mapping is one monitor, a list is several.

| Option | Meaning |
|---|---|
| `name` | Monitor name (default the host name) |
| `type` | `http`, `ping`, `port` or `dns` (default `http` with a `url`, else `ping`) |
| `group` | Kuma group to put it in |
| `url` | Address to check (`http`) |
| `accepted_codes` | Status codes that count as up (default `["200-299"]`) |
| `ignore_tls` | `true` to skip certificate checks, e.g. when checking an IP |
| `hostname` | Host to ping or connect to (default `ansible_host`); for `dns`, the name to look up |
| `port` | Port to check (`port`; `dns` defaults to `53`) |
| `dns_resolve_server` | DNS server to ask (`dns`) |
| `interval` | Seconds between checks (default `60`) |

```yaml
myserver:
  ansible_host: 192.0.2.10
  kuma_monitor:
    - name: myserver
      type: ping
      hostname: "{{ ansible_host }}"
```

## Other options

| Option | Where | Meaning |
|---|---|---|
| `kuma_docker_name` | A Docker host | Its name in Uptime Kuma, and its group under `Containers` (default the inventory name) |
| `kuma_monitor_group` | Host or group | Group for all of a host's monitors, when an entry has no `group` |
| `uptime_kuma_url` | `all: vars:` | Kuma's address (default `https://kuma.<docker_domain>`) |
| `uptime_kuma_notifications` | `all: vars:` | Kuma notifications to attach to every monitor, e.g. `[Discord]` |
| `patch_window_minutes` | Host or group | Longest maintenance window during patching (default `30`) |

The Kuma login is in Vault at `uptime-kuma` (`KUMA_USERNAME`, `KUMA_PASSWORD`).
