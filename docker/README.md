# Docker

Each folder here is one app, deployed as a Docker Compose stack through Portainer.

## Naming

One name ties an app together. The folder name is used as:

- the Portainer stack name
- the `container_name` of the main container, which is also its subdomain (`<app>.<docker domain>`)
- the app's Vault path
- the `Backup` label, which names its backup job

Other conventions:

- The compose file is always `docker/<app>/docker-compose.yaml`.
- Extra containers are named `<app>-<role>`, e.g. `netbox-redis`. Hyphens, not underscores, since container names are hostnames and the proxied one is also a subdomain.
- Variables are upper case, and secrets are prefixed with the app, e.g. `BOOKSTACK_DB_PASSWORD`.

## Deployment

Stacks are deployed by Semaphore, which runs the playbooks in `ansible/playbooks/portainer/`:

- **deploy-stack.yaml** creates or redeploys the stack in Portainer as a Git stack. It can also add the Nginx Proxy Manager host and register the backup job, and it pushes any `config/` folder into the running container.
- **update-stack.yaml** backs the stack up, pulls newer images, and checks the containers come back healthy.

Portainer pulls the compose file from this repo, so every change goes through Git. Don't edit stacks in the Portainer UI.

## Secrets

Secrets come from HashiCorp Vault, from the app's own path (e.g. `bookstack`) under the `VAULT_KV_MOUNT` mount. The playbook reads every `${VAR}` in the compose file and looks it up there. Secrets never go in this repo or the inventory.

## Variables

Values that aren't secret, such as URLs, emails and usernames, come from the inventory:

- `docker_stack_vars` applies to every stack, e.g. `DOCKER_DOMAIN` and `EMAIL`.
- `docker_app_vars.<app>` applies to one app.

If a name is set in more than one place, Vault wins over `docker_app_vars`, which wins over `docker_stack_vars`. `${VAR:-default}` uses its default and isn't looked up.

## Network and TLS

- Apps that need to be reachable join the external `reverseproxy-nw` network. Only Nginx Proxy Manager publishes ports to the host.
- Nginx Proxy Manager is the only way in. It handles TLS and forwards to the container on the port in its `AppPort` label, over plain HTTP unless `AppScheme=https` is set.
- Databases and other internal containers stay on the stack's own internal network only.

## Labels

| Label | Used for |
|---|---|
| `Backup=<app>` | The DVBM backup job that covers this container's volumes |
| `AppPort=<port>` | The port Nginx Proxy Manager forwards to; set it on the one container that serves the app. Its stack also gets an Uptime Kuma monitor on deploy |
| `AppScheme=https` | Optional, on the same container as `AppPort`: forward over HTTPS instead of the default HTTP, for apps that only serve TLS |
| `Kuma.Name=<name>` | Optional, with `AppPort`: an Uptime Kuma check on the app's URL, `https://<Kuma.Subdomain or container>.<docker_domain>`, in `Applications` |
| `Kuma.DockerHost=<host>` | An Uptime Kuma container check on this Docker host (inventory name), in `Containers > <host>`; every service here has one |
| `Kuma.Subdomain`, `Kuma.Path`, `Kuma.Group`, `Kuma.AcceptedCodes` | Optional, with `Kuma.Name`: the URL's subdomain and path, a group other than `Applications`, and status codes that count as up. See `docs/docker/uptime-kuma.md` |
| `ConfigPath=<path>` | Optional: where `docker/<app>/config/*.j2`, rendered from the inventory, is copied into this container by `deploy-stack.yaml` or `push-config.yaml` |

## Template

Copy this into `docker/<app>/docker-compose.yaml` and replace `app` and the image:

```yaml
services:
  app:
    container_name: app
    restart: unless-stopped
    image: vendor/app:latest
    networks:
      - reverseproxy-nw
    environment:
      - APP_URL=https://app.${DOCKER_DOMAIN}
      - APP_SECRET_KEY=${APP_SECRET_KEY}
    volumes:
      - data:/data
    labels:
      - "Backup=app" # Sets the DVBM Backup Job Label
      - "AppPort=8080" # Sets the Application Port for the Reverse Proxy Job

networks:
  reverseproxy-nw: # Use the existing Reverse Proxy Network
    external: true

volumes:
  data:
```

For an app with a database, add a second service on `default` only:

```yaml
  db:
    container_name: app-db
    restart: unless-stopped
    image: postgres:16
    networks:
      - default
    environment:
      - POSTGRES_PASSWORD=${APP_DB_PASSWORD}
    volumes:
      - db:/var/lib/postgresql/data
    labels:
      - "Backup=app" # Sets the DVBM Backup Job Label
```

Then put the main service on both networks, and add `default:` under `networks:` and `db:` under `volumes:`.
