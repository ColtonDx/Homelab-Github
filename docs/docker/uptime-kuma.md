# Uptime Kuma

A container gets an Uptime Kuma monitor when its compose service has a `Kuma.Name` label. The **Uptime Kuma | GitOps** job reads the labels from every compose file in `docker/` and creates or updates the monitors on its schedule.

## Labels

| Label | What it does |
|---|---|
| `Kuma.Name` | Turns the monitor on, with this name. Without it, the container is not monitored |
| `Kuma.Subdomain` | The address's subdomain (default the container name) |
| `Kuma.Path` | A path to check, e.g. `/health` (default none) |
| `Kuma.Group` | The Kuma group (default `Applications`) |
| `Kuma.AcceptedCodes` | Status codes that count as up, comma-separated (default `200-299`) |
| `Kuma.DockerHost` | Container checks only: which Docker host (default `kuma_default_docker_host` in the inventory) |

## Which check you get

- **With `AppPort`:** an HTTP check on `https://<Kuma.Subdomain>.<docker_domain><Kuma.Path>`, the address users reach the app at.
- **Without `AppPort`:** a container check, for databases and workers with no web page. It needs the Docker host set up by **Uptime Kuma | Configure**.

## Example

```yaml
services:
  app:
    container_name: myapp
    labels:
      - "AppPort=8080"
      - "Kuma.Name=My App"
      - "Kuma.Path=/health"
  db:
    container_name: myapp-db
    labels:
      - "Kuma.Name=My App Database"
      - "Kuma.Group=Databases"
```

This gives an HTTP check on `https://myapp.<docker_domain>/health` and a container check on `myapp-db`.

Monitor names must be unique, and removing a label does not delete the monitor; delete it in Kuma.
