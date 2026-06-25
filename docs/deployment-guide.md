# Deployment Guide

## Supported Deployment Model

The repo is built for Docker deployment on a Linux host that can run WireGuard and manage kernel/network permissions.

## Build

From the repo root:

```sh
docker build -t wg-easy .
```

The root `build` script uses the same Docker build path.

## Run With Compose

The checked-in `docker-compose.yml` uses the GHCR image and expects these host capabilities:

- `NET_ADMIN`
- `SYS_MODULE`
- access to `/lib/modules` read-only
- a persistent `/etc/wireguard` volume

Default published ports:

| Port    | Protocol | Purpose                  |
| ------- | -------- | ------------------------ |
| `51820` | UDP      | WireGuard tunnel traffic |
| `51821` | TCP      | Web UI                   |

## Runtime Defaults

The Dockerfile sets these defaults:

| Variable       | Default   |
| -------------- | --------- |
| `PORT`         | `51821`   |
| `HOST`         | `0.0.0.0` |
| `INSECURE`     | `false`   |
| `INIT_ENABLED` | `false`   |
| `DISABLE_IPV6` | `false`   |

## Suggested Environment Variables

| Variable                                                                                     | Purpose                                                  |
| -------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| `PORT`                                                                                       | UI listen port                                           |
| `HOST`                                                                                       | UI bind address                                          |
| `INSECURE`                                                                                   | Allow HTTP access instead of HTTPS-only assumptions      |
| `DISABLE_IPV6`                                                                               | Disable IPv6 config generation and related runtime paths |
| `INIT_ENABLED`                                                                               | Enable unattended initial setup                          |
| `INIT_USERNAME` / `INIT_PASSWORD`                                                            | Initial admin credentials                                |
| `INIT_DNS`, `INIT_ALLOWED_IPS`, `INIT_IPV4_CIDR`, `INIT_IPV6_CIDR`, `INIT_HOST`, `INIT_PORT` | Initial setup inputs                                     |
| `OAUTH_PROVIDERS`, `OAUTH_ALLOWED_DOMAINS`, `OAUTH_AUTO_REGISTER`, `OAUTH_AUTO_LAUNCH`       | OAuth enablement and behavior                            |
| `DISABLE_PASSWORD_AUTH`                                                                      | Disable password login when OAuth-only access is desired |

## Data and Paths

| Path                              | Purpose                               |
| --------------------------------- | ------------------------------------- |
| `/etc/wireguard/wg-easy.db`       | SQLite database used by libsql        |
| `/etc/wireguard/{interface}.conf` | Generated WireGuard config            |
| `/etc/wireguard`                  | Persistent config and DB volume mount |

## Operational Notes

- The app starts WireGuard only after the database is available.
- The Nitro close hook shuts WireGuard down on container stop.
- The container also ships the CLI bundle at `/app/server/cli.mjs`, exposed through the `cli` wrapper.
- Bandwidth settings are only config/API state today, so no deployment step needs traffic-shaping setup.

## Docs Preview

To preview the docs site locally:

```sh
pnpm docs:preview
```
