# Homepage

What you can set in the inventory to change what Homepage shows. Everything else (layout, names, icons) is in `docker/homepage/config/`.

## Under `all: vars:`

| Variable | What it changes |
|---|---|
| `domain` | The domain in every app link |
| `docker_subdomain` | Docker app links: `https://<app>.<docker_subdomain>.<domain>` |
| `homepage.title` | The page title |
| `homepage.kubernetes_subdomain` | Kubernetes app links (Rancher, Longhorn): `https://<app>.<subdomain>.<domain>` |
| `homepage.weather` | The weather widget: `label`, `latitude`, `longitude`, `timezone` |

## On a host

| Variable | What it changes |
|---|---|
| `homepage_url` | Where that host's tile links to, and what its status dot checks |

These hosts need it: `gitlab`, `hashicorp-vault`, `kasm`, `PVE-VM-1`, `PVE-VM-2`, `PVE-VM-3`, `truenas-scale`, `truenas-claw`, `unraid`, `citadel`, `core-switch-1`, `plex`, `apc-pdu`, `eaton-ups`, `home-assistant`, `kvm`, `alarm-panel`, `slzb06`.

## Example

```yaml
all:
  vars:
    domain: example.com
    docker_subdomain: apps
    homepage:
      title: My Homepage
      weather: { label: Home, latitude: 0.0, longitude: 0.0, timezone: UTC }

plex:
  homepage_url: "https://192.0.2.12:32400"
```
