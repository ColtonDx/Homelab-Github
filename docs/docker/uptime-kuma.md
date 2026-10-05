# Uptime Kuma

The **Uptime Kuma | GitOps** job reads the labels in every compose file in `docker/` and creates or updates two kinds of monitor:

| Monitor | Comes from | Name | Group |
|---|---|---|---|
| Application URL (HTTP) | A service with `Kuma.Name` and `AppPort` | The `Kuma.Name` value | `Applications` |
| Container (Docker socket) | A service with `Kuma.DockerHost` | The container name | `Containers > <Docker host>` |

## Labels

| Label | What it does |
|---|---|
| `Kuma.Name` | With `AppPort`: turns on the application URL check, with this name |
| `Kuma.Subdomain` | The URL's subdomain (default the container name), giving `https://<subdomain>.<docker_domain>` |
| `Kuma.Path` | A path to check, e.g. `/health` (default none) |
| `Kuma.AcceptedCodes` | Status codes that count as up, comma-separated (default `200-299`) |
| `Kuma.Group` | Moves the URL check out of `Applications` |
| `Kuma.DockerHost` | Turns on the container check, on this Docker host (its inventory name, e.g. `truenas-scale`) |

The Docker host's name in Kuma, and its group under `Containers`, is `kuma_docker_name` on its inventory host, e.g. `TrueNAS`. The GitOps job registers every host these labels name before adding the checks.

## Example

```yaml
services:
  app:
    container_name: myapp
    labels:
      - "AppPort=8080"
      - "Kuma.Name=My App"
      - "Kuma.Path=/health"
      - "Kuma.DockerHost=truenas-scale"
  db:
    container_name: myapp-db
    labels:
      - "Kuma.DockerHost=truenas-scale"
```

This gives `My App` checking `https://myapp.<docker_domain>/health` in `Applications`, and container checks `myapp` and `myapp-db` in `Containers > TrueNAS`.

Monitor names must be unique (case counts), and removing a label does not delete the monitor; delete it in Kuma.
