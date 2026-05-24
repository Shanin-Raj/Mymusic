## 1. styles.css — Fix Hardcoded Dark Colors

- [x] 1.1 In `.mini-player`, replace `background: rgba(40, 40, 40, 0.85)` with `background: var(--glass)`.
- [x] 1.2 In `.bottom-nav`, replace `background: rgba(20, 20, 20, 0.95)` with `background: var(--glass)`.
- [x] 1.3 In `.progress-bar`, replace `background: rgba(255,255,255,0.1)` with `background: var(--surface-high)`.
- [x] 1.4 In `#search-input` CSS rule, replace `background: #282828` with `background: var(--surface-high)` and update `:focus` state to use `background: var(--surface-highlight)`.

## 2. index.html — Fix Hardcoded Inline Input Backgrounds

- [x] 2.1 In `#screen-search`: Remove `background: ...` from inline style on `#search-input` (the CSS rule now handles it).
- [x] 2.2 In `#screen-add-music`: Replace `background:#282828` inline style on `#main-add-url` with `background:var(--surface)`.
- [x] 2.3 In `#screen-add-music`: Replace `background:#282828` inline style on `#main-add-name` with `background:var(--surface)`.
- [x] 2.4 In `#screen-add-music`: Replace `background:#282828` inline style on `#main-add-artist` with `background:var(--surface)`.
- [x] 2.5 In `#screen-player .player-extras`, add a `#btn-theme-player` icon button (dark mode toggle) alongside the existing airplay/sleep/queue buttons.

## 3. app.js — Wire Player Theme Button

- [x] 3.1 In `theme.apply()`, add a second selector for `#btn-theme-player .material-symbols-rounded` and update its icon text alongside `#btn-theme`.
- [x] 3.2 In `bindThemeToggle()`, add an event listener for `#btn-theme-player` that calls `theme.toggle()`.

## 4. styles.css — Fix Invisible Player-Extras Buttons in Dark Mode

- [x] 4.1 In `styles.css`, add an explicit `color: var(--on-surface-dim)` rule for `.player-extras button` so that `#btn-sleep-timer`, `#btn-queue`, and any future buttons inside `.player-extras` correctly inherit a visible color (browsers do not auto-inherit `color` on `<button>` elements).
- [x] 4.2 Add a hover rule `.player-extras button:hover { color: var(--on-surface); }` for interactive feedback.

## 5. Verification

- [x] 5.1 Switch to light mode via the `#btn-theme` button on the Home screen and visually confirm: mini-player is white/glass, bottom nav is white/glass, progress bar track is visible.
- [x] 5.2 Navigate to the Now Playing screen in light mode and confirm: `#btn-theme-player` is present and clicking it switches back to dark mode.
- [x] [x] 5.3 Confirm all input fields in the Create/Add screen are visible in light mode.
- [x] [x] 5.4 Switch back to dark mode and confirm all components still render correctly.
- [x] [x] 5.5 In dark mode, open the Now Playing screen and confirm the sleep timer (`bedtime` icon) and queue (`queue_music` icon) buttons are both visible in the player-extras row.
