# Compose hardening

Every service in `docker/*/docker-compose.yaml` carries the same block of settings, each with a one-line comment in the file saying what it does. `ci/compose-hardening.py` warns about any service missing one; it only warns until every stack has been rolled out, then it will fail.

| Setting | What it does |
|---|---|
| `security_opt: [no-new-privileges:true]` | No process can gain more privileges than it started with (blocks setuid tricks) |
| `cap_drop: [ALL]` plus a short `cap_add` | Starts with no Linux capabilities and adds back only what the app needs, each with a comment saying why |
| `read_only: true` with `tmpfs` folders | The app cannot change its own files; only volumes and in-memory scratch folders are writable |
| `healthcheck` | Docker and Kuma can see a hung app, not just a running container |
| `mem_limit`, `pids_limit` | One runaway app cannot take the host's memory or fork without limit |
| `logging` with `max-size` and `max-file` | Container logs are rotated so they cannot fill the disk |

Images are pinned by digest separately, through Renovate.

## Exceptions

When an app cannot take a setting (for example it writes its own files at start-up, so it cannot be read-only), the file says so in a comment next to where the setting would be. A comment starting `# hardening:` and naming the setting (e.g. `# hardening: healthcheck comes from the image itself`) also tells the CI check to skip it.

## Rollout

Stacks are hardened a few at a time, low-risk apps first and the password manager and anything holding secrets last. Each batch is one pull request; after it deploys, the stacks are checked for a healthy container and a green Kuma monitor, and a stack that breaks is reverted on its own.
