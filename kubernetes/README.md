# Kubernetes

Everything that runs on the Kubernetes clusters, applied by Flux. Apps are written once and shared by every cluster that runs them. Nothing in this folder is private: each cluster's domain and other site details come from Vault at deploy time.

## Layout

```
kubernetes/
├── clusters/<cluster>/     # what one cluster runs; flux bootstrap points the cluster here
├── infrastructure/
│   ├── controllers/        # External Secrets, storage, ingress: base/ for every cluster, proxmox/ and azure/ for the rest
│   └── configs/            # things that need the controllers' CRDs, like the Vault secret store
└── apps/
    ├── base/<app>/         # one folder per app
    └── <cluster>/          # the list of apps that cluster runs, plus any patches
```

Talos machine configs are kept elsewhere, since they describe the nodes rather than what runs on them.

## Load order

Each cluster applies four Flux Kustomizations, each waiting for the one before:

1. **infra-controllers**: installs the controllers.
2. **infra-configs**: the `vault` ClusterSecretStore, which reaches Vault using the `cluster-bootstrap` Secret.
3. **cluster-vars**: copies every field at the cluster's Vault path (`flux-talos` for talos-cluster) into the `cluster-vars` Secret.
4. **apps**: deploys the cluster's apps, filling in `${VAR}` placeholders from `cluster-vars`.

## Variables

Apps write site details as placeholders, e.g. `host: it-tools.${CLUSTER_SUBDOMAIN}.${DOMAIN}`. Flux replaces them from `cluster-vars`, which holds whatever fields the cluster's Vault path has. Adding a field there makes it available to every app.

A literal `${...}` that must not be replaced is written `$${...}`.

## Secrets

Apps read secrets through ExternalSecrets that name the ClusterSecretStore `vault` and a Vault path. Every cluster has a store with that name, so an app's ExternalSecrets are the same on every cluster.

## Adding an app

1. Create `apps/base/<app>/` with its manifests or HelmRelease, using placeholders for anything site-specific.
2. Add `../base/<app>` to `apps/<cluster>/kustomization.yaml` for each cluster that should run it.

## Bootstrapping a cluster

For the Talos cluster, `ansible/playbooks/terraform/build-project.yaml -e tf_project=terraform/proxmox/talos` does all of this. It builds the VMs, then `ansible/playbooks/talos/init-cluster.yaml` configures and bootstraps Talos, then `bootstrap-secrets.yaml` runs these steps:

1. Enables Vault's Kubernetes auth for the cluster, with a role for External Secrets and a read-only policy for the paths in `talos_cluster.eso_vault_paths`.
2. Creates the `cluster-bootstrap` Secret. It's the one Secret Flux can't get from Vault, because it says how to reach Vault.
3. Applies `clusters/<cluster>/flux-system/`, after which Flux manages everything, including itself.

The cluster's values go at its own Vault path, e.g. `flux-talos`, with fields such as `DOMAIN` and `CLUSTER_SUBDOMAIN`. That path is named in `clusters/<cluster>/vars/cluster-vars.yaml` and must be in `eso_vault_paths`.

To upgrade Flux, regenerate `flux-system/gotk-components.yaml` with a newer Flux CLI (`flux install --export`) and commit it.
