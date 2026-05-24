## Why

After multiple UI build iterations (spotify-ui-redesign, spotify-ui-fixes, fix-bottom-black-bar, fix-song-adding-and-apply-ui), the dark/light mode toggle exists but several UI elements remain hard-coded to dark colors — making them look broken or invisible when switching to light mode. The screenshots confirm three specific failures: the progress bar track becomes invisible, the mini-player stays dark, and the bottom nav stays dark even in light mode.

## What Changes

- Fix hardcoded dark backgrounds on `.mini-player` and `.bottom-nav` to use theme-aware CSS variables.
- Fix the `.progress-bar` background to be visible in both modes (`var(--surface-high)` instead of `rgba(255,255,255,0.1)`).
- Add a dark mode toggle button (`#btn-theme`) to the Now Playing screen (`#screen-player`) player-extras section so users can switch themes while in the full player view.
- Update `theme.apply()` in `app.js` to sync the icon for the new player-screen theme button as well.
- Fix hardcoded dark `#282828` background on search inputs and add inputs in `index.html` to use `var(--surface)` so they are visible in light mode.
- Fix the `#mini-progress-fill` selector in `app.js` — currently it targets `#mini-progress` but the progress fill element is defined inline and the selector updates the container, not the fill width correctly.

## Capabilities

### New Capabilities
- `theme-aware-player`: The Now Playing screen provides a dark mode toggle button accessible in the player-extras row.

### Modified Capabilities
- 

## Impact

- Only touches frontend UI files: `backend/public/styles.css`, `backend/public/index.html`, `backend/public/app.js`
- No backend changes
- No structural changes to screens — only targeted CSS and minor HTML additions
