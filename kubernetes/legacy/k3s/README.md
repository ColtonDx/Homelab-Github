# Legacy K3s cluster

The earlier cluster: K3s on Proxmox VMs, with Argo CD. Talos and Flux (`../../clusters/talos-cluster/`) replaced it, but everything needed to rebuild it is kept here.

## Building it

- `terraform/proxmox/k3s` builds the VMs. Run it through `ansible/playbooks/terraform/build-project.yaml -e tf_project=terraform/proxmox/k3s`, which then runs `ansible/playbooks/k3s/initialize.yaml`.
- `initialize.yaml` installs K3s, Longhorn, MetalLB and Traefik with a wildcard certificate, then External Secrets, Argo CD, the Longhorn UI and Rancher.
- `service-argo-bootstrap.yaml`, the last Argo step, renders `argocd/*.yaml.j2` and applies them. Argo then syncs each app from this folder.

## Layout

```
argocd/   Argo CD Applications, as templates the bootstrap fills in
apps/     the manifests those Applications point at
values/   Helm values for the chart-based apps
```

## Site values

Argo has no variable substitution, so nothing site-specific is in these files. Hostnames are filled in by the bootstrap from `traefik_domain` in the inventory. The ingress in `apps/it-tools` carries a placeholder host that its Application patches, and NetBox's and Rancher's hosts are Helm values set in their Applications.

## Secrets

The ExternalSecrets read Vault through the `vault` ClusterSecretStore that `service-external-secrets.yaml` creates:

| App | Vault path | Fields |
|---|---|---|
| traefik-secrets | `cloudflare` | `CF_API` |
| longhorn-backup | `garage` | `GARAGE_ACCESS_KEY`, `GARAGE_SECRET_KEY`, `GARAGE_URL` (with its scheme) |
| netbox | `k3s/netbox` | `NETBOX_SUPER_USER`, `NETBOX_SUPER_PASSWORD`, `NETBOX_SUPER_EMAIL`, `NETBOX_TOKEN`, `NETBOX_SECRET_KEY`, `NETBOX_API_TOKEN_PEPPERS`, `NETBOX_DB_PASSWORD`, `NETBOX_DB_ADMIN_PASSWORD`, `NETBOX_VALKEY_PASSWORD` |

## Adding an app

1. Create `apps/<name>/` with its manifests, and a `kustomization.yaml` if an Application needs to patch it.
2. Copy an Application template in `argocd/` to `<name>.yaml.j2`, and change the name and path.
3. Re-run `service-argo-bootstrap.yaml`.

`prune: true` means deleting an app's manifests deletes its resources, and `selfHeal: true` reverts changes made with kubectl.
