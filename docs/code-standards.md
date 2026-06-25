# Code Standards

## Scope

These standards describe how this repo is organized and how new code should fit into the existing structure.

## Repository Structure

| Path                               | Responsibility                                                                    |
| ---------------------------------- | --------------------------------------------------------------------------------- |
| `src/app`                          | Nuxt pages, layouts, middleware, stores, and reusable UI components               |
| `src/server/api`                   | JSON and form-style Nitro route handlers                                          |
| `src/server/routes`                | Public non-API routes such as metrics and one-time config downloads               |
| `src/server/database/repositories` | Database schemas, types, and repository services                                  |
| `src/server/utils`                 | Shared server utilities, WireGuard runtime helpers, validation, command execution |
| `src/cli`                          | Bundled CLI entry points and commands                                             |
| `docs/content`                     | Published docs site content                                                       |

## File and Module Rules

- Keep file names descriptive.
- Prefer small modules over large mixed-purpose files.
- Split code when a file starts crossing roughly 200 lines and the logic can stand on its own.
- Put behavior in the existing layer before creating a new abstraction.
- Do not add plan IDs or finding codes to code comments, filenames, or migrations.

## Frontend Standards

| Rule        | Expected shape                                                                 |
| ----------- | ------------------------------------------------------------------------------ |
| Routing     | Use file-based pages in `src/app/pages`                                        |
| State       | Use Pinia stores for shared app state                                          |
| Components  | Reuse `Base`, `Form`, `Panel`, `Clients`, `Admin`, and similar feature folders |
| Styling     | Tailwind utility classes plus existing Radix Vue primitives                    |
| Locale text | Route all user-facing strings through i18n                                     |
| UI feedback | Preserve loading, success, and error states; use toasts for async actions      |

## Server Standards

| Rule              | Expected shape                                                                      |
| ----------------- | ----------------------------------------------------------------------------------- |
| Input validation  | Validate route params and request bodies with shared Zod schemas                    |
| Permission checks | Use the existing permission-aware handlers for admin and metrics access             |
| Error handling    | Throw or return explicit HTTP errors; do not hide failures in silent fallback logic |
| DB access         | Go through repository services instead of querying tables directly in routes        |
| Runtime effects   | WireGuard and firewall changes should go through `WireGuard.ts` / `firewall.ts`     |

## Database Standards

- Keep schema changes in Drizzle repository files and migration SQL together.
- Update types when schema fields change.
- Prefer explicit defaults for persisted settings.
- Treat generated snapshots as derived artifacts, not hand-edited design docs.

## Testing and Verification

| Command                                              | Purpose                               |
| ---------------------------------------------------- | ------------------------------------- |
| `pnpm lint`                                          | ESLint across the source tree         |
| `pnpm typecheck`                                     | Nuxt and TypeScript validation        |
| `pnpm test:unit`                                     | Vitest unit suite                     |
| `pnpm build`                                         | Docker image build path from the root |
| `pnpm format:check:docs`                             | Markdown formatting check for `docs/` |
| `node $HOME/.claude/scripts/validate-docs.cjs docs/` | Docs structure and link validation    |

## Documentation Rules

- Keep docs aligned with code, not with memory.
- If a feature exists only in storage or API, say that explicitly.
- Do not claim runtime enforcement unless a runtime code path exists.
- Use relative links inside `docs/`.
- Keep docs concise and evergreen.

## Operational Rules

- The app expects Docker and WireGuard-capable Linux hosts.
- The runtime container needs `NET_ADMIN` and `SYS_MODULE`.
- Docker image defaults are `PORT=51821`, `HOST=0.0.0.0`, `INSECURE=false`, `INIT_ENABLED=false`, and `DISABLE_IPV6=false`.
- CLI commands are bundled into `.output/server/cli.mjs`.
