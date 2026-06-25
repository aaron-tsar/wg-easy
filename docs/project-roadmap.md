# Project Roadmap

## Status

This roadmap tracks the repo's current maintenance and product priorities. It is not a release schedule.

## Now

| Area                  | Status | Notes                                                               |
| --------------------- | ------ | ------------------------------------------------------------------- |
| Upstream sync hygiene | Active | Keep the fork aligned with `wg-easy/wg-easy` master                 |
| Documentation parity  | Active | Keep root docs and site content aligned with actual code            |
| Auth and account flow | Active | Preserve login, OAuth, pending 2FA, and profile management behavior |
| Client management     | Active | Maintain CRUD, QR, config download, and one-time link flows         |

## Next

| Area                | Why it matters                         | What to watch                                              |
| ------------------- | -------------------------------------- | ---------------------------------------------------------- |
| Runtime reliability | It drives self-hosting trust           | Boot/shutdown behavior, cron expiry, and config sync paths |
| Observability       | Users depend on it for troubleshooting | Metrics shape and endpoint auth behavior                   |
| Deployment docs     | Most users install through Docker      | Compose defaults, volumes, caps, and env vars              |
| Localization        | The app is translated heavily          | Keep locale count and docs current when new strings land   |

## Later

| Area                  | Decision needed | Current note                                                           |
| --------------------- | --------------- | ---------------------------------------------------------------------- |
| Bandwidth enforcement | Product choice  | Config exists in DB/API, but no traffic shaping runtime is implemented |
| UI polish             | Ongoing         | Keep responsive layouts and component reuse, but avoid design churn    |
| CLI expansion         | Optional        | Current CLI is small and focused on admin/inspection tasks             |

## Maintenance Rules

- Update this file after major feature work or upstream syncs.
- Mark a topic complete only when code, tests, and docs all agree.
- If a change affects runtime behavior, update `system-architecture.md` and `deployment-guide.md` too.
