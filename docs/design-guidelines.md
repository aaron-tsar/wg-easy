# Design Guidelines

## Product Direction

The UI should feel practical, dense, and predictable. This is an admin tool first, not a marketing site.

## Visual System

| Area       | Guideline                                                                                  |
| ---------- | ------------------------------------------------------------------------------------------ |
| Theme      | Respect the existing light/dark mode setup; do not hardcode one palette                    |
| Styling    | Use Tailwind utility classes and existing component wrappers                               |
| Primitives | Prefer Radix Vue and current base/form/panel components before adding new UI primitives    |
| Layout     | Keep layouts simple and responsive; most screens should work on a phone without a redesign |

## Component Behavior

- Reuse existing component groups such as `Base`, `Form`, `Panel`, `ClientCard`, `Clients`, and `Admin`.
- Keep forms explicit and readable.
- Preserve loading, disabled, and error states.
- Keep destructive actions visually distinct.
- Prefer dialogs and inline actions that match the current app patterns.

## Content and Copy

| Rule                             | Why                                                                  |
| -------------------------------- | -------------------------------------------------------------------- |
| Use i18n for all visible strings | The app ships with 24 locales                                        |
| Keep labels short                | Admin flows are dense and need scan-friendly forms                   |
| Prefer direct copy               | Users are configuring networking and auth, not reading product prose |
| Match terminology in code        | Use the same names as the app, API, and docs                         |

## Accessibility

- Keep keyboard navigation intact for forms, dialogs, menus, and auth flows.
- Preserve focus states and visible disabled states.
- Keep contrast high enough in both theme modes.
- Use semantic elements where possible.

## Motion and Feedback

- Use motion sparingly.
- Prioritize state feedback over decorative animation.
- Toasts, loading indicators, and progress states should explain what changed.

## Screens to Keep Consistent

| Screen                         | Design priority                       |
| ------------------------------ | ------------------------------------- |
| Login and 2FA                  | Fast, compact, low-friction           |
| Clients list and client detail | Dense but scannable                   |
| Admin settings                 | Form-heavy, structured, low ambiguity |
| Setup wizard                   | Step-based, clear next action         |
| Profile page                   | Simple account management flow        |

## Notes

- `src/app/app.css` only defines color-scheme behavior, so most visual identity comes from component classes and Tailwind usage.
- Avoid introducing a second design language unless the whole app is being reworked.
