## Context

The Sonic Vault web application currently uses a custom editorial styling that looks nice but deviates significantly from expected standard music player UX patterns (e.g., Spotify). To improve usability and familiarity, we're transitioning the entire frontend — layout, color palette, navigation, and player controls — to a Spotify-like dark theme design. The backend API (`server.js` and `/api/*` endpoints) will remain entirely unchanged.

## Goals / Non-Goals

**Goals:**
- Completely replace the visual aesthetic with a Spotify dark UI clone.
- Re-layout the Home, Search, Library, and Now Playing screens to mirror Spotify's mobile layout.
- Restructure CSS using variables that match Spotify's design system.
- Maintain existing playback functionality, queue management, and playlist syncing without touching the backend or database.

**Non-Goals:**
- No backend code changes.
- No changes to the database schema or data fetching logic.
- We will not add new features (e.g., social sharing, lyrics), just redesign the existing features to look like Spotify.

## Decisions

- **CSS Variables Update**: We will rewrite the `:root` variables in `styles.css` to use Spotify's exact color codes:
  - Background: `#121212`
  - Surfaces/Cards: `#181818`
  - Elevated surfaces: `#282828`
  - Primary accent (Green): `#1DB954` (bright: `#1ed760`)
  - Typography colors: `#FFFFFF` (primary), `#B3B3B3` (secondary)
- **DOM Restructuring**: The `index.html` structure will be modified to support the new layouts:
  - Add filter chips to Home and Library screens.
  - Convert bottom nav to a 5-item layout (`Home`, `Search`, `Your Library`, `Premium`, `Create`).
  - The Mini Player will be pinned above the bottom navigation, with a progress bar underneath.
  - The Full Screen Player will adopt the vertical layout: Header → Art → Meta → Seek Bar → Controls → Bottom Actions.
- **Font Stack Replacement**: The font will be updated to a standard clean sans-serif like 'Inter' or system fonts, moving away from 'Hanken Grotesk' to better approximate Spotify's 'Circular'.
- **Iconography**: We will continue using Google Material Symbols Rounded but will map them more closely to Spotify's iconography (e.g., solid vs outline icons for active states).

## Risks / Trade-offs

- **Risk: Breaking existing DOM selectors.** The `app.js` heavily relies on specific IDs and classes.
  - *Mitigation*: We will reuse the exact same IDs (`#screen-home`, `#search-input`, `#btn-play`, etc.) and data attributes in the new `index.html` structure to ensure the JS logic continues functioning without major rewrites. We will only modify JS where the interaction paradigm fundamentally changes (e.g., handling new filter chips if we make them interactive).
- **Risk: Responsive mobile scaling.** Spotify's UI is highly tuned for mobile screens.
  - *Mitigation*: Ensure the new CSS relies on Flexbox/CSS Grid with relative units and respects safe area insets for mobile rendering. Keep max-width constraints for desktop views as currently implemented.
