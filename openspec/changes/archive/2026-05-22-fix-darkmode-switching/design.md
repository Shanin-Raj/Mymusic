## Context

The app supports dark/light mode via the `theme` object in `app.js`, which toggles the `dark-mode` class on `<body>`. The CSS uses `body:not(.dark-mode)` to apply light mode overrides to all CSS custom properties. However, several elements use hardcoded color values instead of CSS variables, bypassing the theming system entirely.

**Known hardcoded values (from code audit):**
- `.mini-player`: `background: rgba(40, 40, 40, 0.85)` — always dark
- `.bottom-nav`: `background: rgba(20, 20, 20, 0.95)` — always dark
- `.progress-bar`: `background: rgba(255, 255, 255, 0.1)` — invisible on light backgrounds
- `#search-input`, `#main-add-url`, `#main-add-name`, `#main-add-artist` in HTML: `background:#282828` hardcoded inline style — always dark
- `#btn-theme` only exists in `#screen-home` header — no theme button in the Now Playing screen

## Goals / Non-Goals

**Goals:**
- Replace all hardcoded dark color values in `styles.css` with CSS custom property equivalents that respond to the theme.
- Add a `#btn-theme-player` button in `#screen-player .player-extras` so users can toggle dark mode from within the full player view.
- Update `theme.apply()` in `app.js` to also update the player theme button icon.
- Update inline background styles on input fields in `index.html` to use `var(--surface)`.

**Non-Goals:**
- We will not add any new screens, features, or animations.
- We will not change any backend or API logic.
- We will not move or restructure HTML elements beyond adding the one theme toggle button.

## Decisions

- **Use `var(--surface)` and `var(--glass)` for adaptive backgrounds**: These are already defined in both `:root` (dark) and `body:not(.dark-mode)` (light) overrides, so switching is automatic.
- **Progress bar track uses `var(--surface-high)`**: This has adequate contrast in both dark (`#282828`) and light (`#EBEBEF`) modes.
- **Player theme button shares same `bindThemeToggle()` function**: We bind a second `#btn-theme-player` element inside the existing function — no new functions needed.

## Risks / Trade-offs

- [Risk] Inline styles in `index.html` can be overridden again in future edits. → Mitigation: Document in the tasks that inline `background` values on inputs must always use `var(--surface)`.
- [Risk] Mini-player glass blur effect may look slightly different in light mode. → Acceptable: `var(--glass)` is defined as `rgba(255, 255, 255, 0.85)` in light mode, which is the correct glassmorphic white.
