# Codebase Summary

Generated from Repomix analysis on 2026-06-25.

## Pack Summary

| Metric           | Value     |
| ---------------- | --------- |
| Total files      | 354       |
| Total tokens     | 283,311   |
| Total characters | 1,029,667 |

## Token Hotspots

Most of the packed size is in generated and historical artifacts, not hand-written app logic.

| Rank | File                                                     | Tokens |
| ---- | -------------------------------------------------------- | ------ |
| 1    | `LICENSE`                                                | 7,275  |
| 2    | `src/server/database/migrations/meta/0007_snapshot.json` | 6,683  |
| 3    | `src/server/database/migrations/meta/0006_snapshot.json` | 6,519  |
| 4    | `src/server/database/migrations/meta/0005_snapshot.json` | 6,438  |
| 5    | `src/server/database/migrations/meta/0004_snapshot.json` | 6,307  |

## Main Areas

| Area           | Purpose                                                                             |
| -------------- | ----------------------------------------------------------------------------------- |
| `src/app`      | Nuxt UI, pages, layouts, middleware, stores, reusable components                    |
| `src/server`   | Nitro API routes, routes, plugins, database repositories, WireGuard runtime helpers |
| `src/cli`      | Small bundled admin/inspection CLI                                                  |
| `src/i18n`     | Locale catalog and translation data                                                 |
| `docs/content` | Published documentation site content                                                |
| `src/shared`   | Shared utility code used by app and server                                          |

## Repository Shape

- File-based UI routes live under `src/app/pages`.
- Server APIs live under `src/server/api`, with public routes under `src/server/routes`.
- Database access is split by repository under `src/server/database/repositories`.
- Migration SQL and Drizzle snapshots live under `src/server/database/migrations`.
- The docs site is separate from the app and is served from `docs/` via Zensical.

## Runtime Notes

- App startup connects to the database first, then starts WireGuard.
- WireGuard config is rendered to `/etc/wireguard/{interface}.conf`, synced with `wg syncconf`, and cleaned up on Nitro shutdown.
- The cron loop expires clients and one-time links once per minute.
- Bandwidth settings are present in the general config schema, but there is no traffic shaper in the current runtime path.

## Security Check

No suspicious files detected during packing.

## Refresh

Regenerate this summary after large upstream syncs or structural changes.
