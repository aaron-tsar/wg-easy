# Project Overview & Product Development Requirements

`wg-easy` is a self-hosted WireGuard admin app with a Nuxt frontend, Nitro API, SQLite-backed persistence, and Docker-first deployment. The current fork matches upstream master plus a local bandwidth settings addition in the general config path.

## Current Product State

| Area              | Current state                                                                                  |
| ----------------- | ---------------------------------------------------------------------------------------------- |
| Web app           | Nuxt 4 + Vue 3 app with file-based routing under `src/app/pages`                               |
| Auth              | Session login, OAuth link/unlink, TOTP 2FA, pending-2FA flow                                   |
| Client management | CRUD, QR code, config download, one-time links, expiration, per-client firewall rules          |
| Admin config      | General settings, interface settings, hooks, user config, CIDR change, interface restart       |
| Observability     | JSON and Prometheus metrics endpoints plus in-app client transfer charts                       |
| Localization      | 24 locales in `src/nuxt.config.ts`                                                             |
| Runtime           | WireGuard config generation, `wg-quick` sync, firewall rebuild, minute cron for expiry cleanup |
| Database          | libsql/SQLite at `/etc/wireguard/wg-easy.db`                                                   |
| Docs              | Zensical docs site in `docs/`, previewed with `pnpm docs:preview`                              |

## Product Requirements

### Functional Requirements

| Requirement        | Evidence in code                                                                                                                                | Acceptance criteria                                                                                |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Client CRUD        | `src/server/api/client/*`, `src/app/pages/index.vue`, `src/app/pages/clients/[id].vue`                                                          | Admin can create, edit, enable, disable, and delete clients                                        |
| Client artifacts   | QR and config routes in `src/server/api/client/[clientId]/*`                                                                                    | Users can download configs and scan QR codes                                                       |
| One-time links     | `src/server/api/client/[clientId]/generateOneTimeLink.post.ts`, `src/server/routes/cnf/[oneTimeLink].ts`                                        | Link expiry is shortened after first download with a 10-second grace window                        |
| Setup flow         | `src/server/api/setup/*`, `src/app/pages/setup/*`                                                                                               | Fresh installs can complete guided setup and migration                                             |
| Authentication     | `src/server/api/auth/*`, `src/app/pages/login*`                                                                                                 | Password auth, OAuth, and 2FA flows work without leaking session state                             |
| Profile management | `src/app/pages/me.vue`, `src/server/api/me/*`                                                                                                   | User can edit profile, password, TOTP, and OAuth link state                                        |
| Server config      | `src/server/api/admin/interface*`, `src/server/api/admin/hooks*`                                                                                | Admin can update interface and hook settings and restart the interface                             |
| Metrics            | `src/server/routes/metrics/*`                                                                                                                   | JSON and Prometheus outputs reflect current WireGuard state                                        |
| Bandwidth settings | `src/server/database/repositories/general/*`, `src/server/api/admin/general.post.ts`, `src/server/database/migrations/0007_bandwidth_limit.sql` | Bandwidth enable/download/upload settings are stored, validated, and returned by admin config APIs |
| Localization       | `src/nuxt.config.ts`                                                                                                                            | App ships with 24 configured locales and default locale `en`                                       |
| CLI                | `src/cli/*`, `src/cli/build.js`                                                                                                                 | `db:admin:reset`, `clients:list`, and `clients:qr` run from the bundled CLI                        |

### Non-Functional Requirements

| Requirement     | What the code already does                                                                                                    |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Security        | Argon2 password hashing, permission checks, validated bodies and route params, session cookies, sanitized QR/config filenames |
| Reliability     | DB connect happens before WireGuard startup; Nitro close hook shuts WireGuard down cleanly                                    |
| Maintainability | Repository/service split under `src/server/database/repositories/*`, reusable UI components, shared validation helpers        |
| Compatibility   | Docker image runs on node24-based Alpine image with `dumb-init`, `wireguard-tools`, and iptables support                      |
| UX              | Responsive panels, dialogs, toasts, and mobile-aware auth/client pages                                                        |
| Documentation   | Root docs and site content are separate; docs preview is containerized                                                        |

## Scope Notes

- Bandwidth settings are real in storage and admin APIs, but there is no runtime traffic shaping in the current code path. Do not document it as enforced bandwidth limiting.
- `README.md` is current enough after the upstream sync and does not need a rewrite for this pass.
- The codebase has moved beyond Nuxt 3. Any docs that still say Nuxt 3 or 16 locales are stale.

## Target Tech Stack

| Layer     | Stack                                                 |
| --------- | ----------------------------------------------------- |
| Frontend  | Nuxt 4, Vue 3, Pinia, Tailwind CSS, Radix Vue, VueUse |
| Backend   | Nitro/H3, Drizzle ORM, libsql client                  |
| Database  | SQLite file at `/etc/wireguard/wg-easy.db`            |
| CLI       | `citty`, `esbuild`, `tsx`                             |
| Container | Docker, Alpine, `dumb-init`                           |
| VPN       | WireGuard, optional AmneziaWG detection               |
