# Host firewall

Read by the **Host | Firewall** job (`ansible/playbooks/deployment/host-firewall.yaml`), which runs the `host_firewall` role and the source restriction from `automation_user` on every host in `host_firewall`. Every option and its default is in [the firewall role's defaults](../../ansible/roles/host_firewall/defaults/main.yaml).

## What every host gets

- An nftables table of its own, `inet host_firewall`, loaded at boot by `host-firewall.service`. Nothing else is flushed, so Docker's rules and other tables (such as the dev hosts' port redirect) are left alone. `systemctl stop host-firewall` removes the table.
- Inbound only. Established traffic, loopback and ICMP pass; then `host_firewall_open_tcp` (443 by default) from anywhere, SSH from `host_firewall_ssh_sources`, and the host's own `host_firewall_allow` rules. Outbound traffic is not filtered.
- The same rules apply to Docker-published ports. Docker forwards those before the input chain sees them, so a forward chain checks new connections Docker sent on. Ports are matched as first addressed, so a published or redirected port is listed by its outside number.

## Modes

| `host_firewall_mode` | Effect |
|---|---|
| `log` (default) | Everything still gets in; what `enforce` would drop is logged as `host-firewall would drop:` (rate-limited, in the journal and Loki) |
| `enforce` | That traffic is dropped and logged as `host-firewall drop:` |

Run `log` until the logs show everything a host needs, add it to `host_firewall_allow`, then switch that host to `enforce`. Every switch to new rules arms a timer first: if the runner cannot open a new SSH connection through them, the previous rules come back at once (or after `host_firewall_revert_seconds` if the run is cut off).

## Temporary openings

The **Host | Firewall JIT** job (`ansible/playbooks/deployment/host-firewall-jit.yaml`) opens one TCP port (default 443) to one address for `jit_minutes` (default 60, at most 1440), for example to reach Vault from a device with a changing address. Entries live in the table's `jit_v4` / `jit_v6` sets with a timeout, so the kernel removes them when time is up; rerunning restarts the clock. Reloading the rules clears every opening, and the Semaphore task history records who opened what.

## Automation account sources

With `automation_user_sources` set, sshd accepts the automation account (`automation_user_name`, default `ansible`) only from those addresses, for keys and certificates alike. Before sshd reloads, the role asks sshd how it would treat this run's own address and an outside one, and takes the setting back out unless the run would still get in. An empty list removes the restriction.

```yaml
all:
  vars:
    automation_user_sources: "{{ groups['runners'] | map('extract', hostvars, 'ansible_host') | list }}"
    host_firewall_ssh_sources: "{{ automation_user_sources + ['192.0.2.0/24'] }}"

host_firewall:
  children:
    ssh:
```

One host's variables, once its log shows what it needs:

```yaml
host_firewall_mode: enforce
host_firewall_allow:
  - { port: 1280, from: [192.0.2.10], comment: reverse proxy }
  - { port: 514, proto: udp, from: [192.0.2.1], comment: firewall syslog }
```
