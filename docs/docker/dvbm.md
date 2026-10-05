# DVBM backups

Docker Volume Backup Manager (DVBMv3) backs up container volumes. A container's volumes are backed up when its compose service has a `Backup` label.

## The label

| Label | What it does |
|---|---|
| `Backup=<job>` | Puts every volume of this container in the DVBM job named `<job>`. Use the app name, e.g. `Backup=bookstack` |

Several containers in a stack can share one job name, so the app and its database are backed up together.

## How the job is used

- **Portainer Stack Creation** with `dvbm_job=true` creates the job in DVBM, if no job of that name exists.
- **Portainer Stack Update** runs the job and waits for it before updating, so every update has a backup to restore from.
- **Backup | DVBM Job** runs one job on demand, by name.

Restores are done in DVBM itself.

## Example

```yaml
services:
  app:
    container_name: myapp
    volumes:
      - data:/data
    labels:
      - "Backup=myapp"
  db:
    container_name: myapp-db
    volumes:
      - db:/var/lib/postgresql/data
    labels:
      - "Backup=myapp"

volumes:
  data:
  db:
```

Both containers' volumes go into the `myapp` job. A container without the label is not backed up.
