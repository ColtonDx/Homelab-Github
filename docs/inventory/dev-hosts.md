# Development hosts

Read by the **Host | Dev** job (`ansible/playbooks/deployment/host-dev.yaml`), which runs the `dev_host` role on every host in `dev_hosts`. Every option and its default is in [the role's defaults](../../ansible/roles/dev_host/defaults/main.yaml).

## What every host gets

- Build tools (`git`, `build-essential`, `pkg-config`, `curl`, `unzip`) and rootless Podman (`podman`, `uidmap`, `passt`, `dbus-user-session`).
- [mise](https://mise.jdx.dev) at a pinned version, checked against its sha256. Interactive bash shells activate it from `/etc/profile.d/mise.sh`; SSH and login sessions get its shims on `PATH` from `/etc/security/pam_env.conf`. Processes started without PAM must set `PATH` themselves.
- Subordinate ID ranges in `/etc/login.defs`, so `useradd` gives every new user what rootless Podman needs.
- Lingering for every user in the UID range, so `systemctl --user` works over SSH and user services survive a reboot. This is the only change made to users the role did not create.
- A read-only check that fails the run when any of those users is in `sudo`, `docker`, `adm`, `disk`, `lxd`, `libvirt` or `wheel`. List the admin account Ansible logs in as in `dev_host_admin_users`.

The role does not install or remove Docker; that is the `docker` group and the **Host | Docker** job.

## Test hosts

With `dev_host_manage_users: true`, the role creates one user per project, `dev-<name>`, with a private home, and removes users it created once their project leaves the list. Accounts it did not create are never touched.

| Option | Meaning |
|---|---|
| `dev_host_projects` | List of `{ name, port_base }`. `port_base` starts the project's block of `dev_host_port_block` ports (default 10) inside `dev_host_port_range` (default 20000-29999); set it explicitly, never from list order |
| `dev_host_deploy_key` | Public key every project user accepts, for the deploy job; empty removes project keys |
| `dev_host_deploy_key_from` | Address that key may connect from, written as `restrict,from="..."` |

Each project's user services see `DEV_HOST_PORT_BASE` and `DEV_HOST_PORT_COUNT` through `~/.config/environment.d/`. A project's deploy script (for example Quadlet units with `Restart=on-failure` and health checks) lives in the project's own repo, so a rebuilt host is redeployed by rerunning it. Test URLs follow `<project>.dev.<domain>` to `<host>:<port_base>`, served by the reverse proxy from the same project list.

```yaml
dev_hosts:
  vars:
    dev_host_admin_users: [admin]
  hosts:
    dev-a:
    dev-b:
      dev_host_manage_users: true
      dev_host_projects:
        - { name: example, port_base: 20000 }
      dev_host_deploy_key: "ssh-ed25519 AAAA... deploy"
      dev_host_deploy_key_from: 192.0.2.10
```
