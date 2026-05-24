## Context

The "Sonic Vault" application currently utilizes a "Sonic Clarity" design system characterized by Montserrat/Hanken Grotesk typography and a Light/Dark monochromatic aesthetic with red accents. To achieve a more professional and recognizable identity, we are transitioning the entire frontend to Spotify's official design language. This involves shifting from light mode/red accents to a signature high-contrast dark theme with "Spotify Green" as the primary action color.

## Goals / Non-Goals

**Goals:**
- Implement a high-fidelity "Spotify-inspired" UI that adheres to official developer design guidelines.
- Standardize typography to platform-native sans-serif fonts for a seamless integration feel.
- Optimize the "Now Playing" view for content immersion using artwork-responsive backgrounds.
- Simplify playback controls to focus on the essential Play/Pause/Skip actions.

**Non-Goals:**
- Modifying the Telegram-based audio streaming logic or Firestore database schema.
- Implementing a real-time dominant color extraction algorithm (we will use fallback gradients and artwork overlays for performance).
- Changing the existing playlist creation or search backend functionality.

## Decisions

- **Color System Refresh**: 
  - **Decision**: Adopt `#191414` as the base background and `#1FDF64` for primary actions.
  - **Rationale**: These are the official Spotify brand colors, optimized for dark-mode readability and brand recognition.
  - **Alternative**: Keeping the current `#000000` base was considered, but `#191414` provides a softer, more "premium" dark gray feel.

- **Typography Transition**:
  - **Decision**: Shift from custom Google Fonts to a native font stack: `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif`.
  - **Rationale**: Spotify guidelines emphasize platform-native fonts for third-party integrations to ensure maximum legibility and reduced load times.

- **"Now Playing" Visualization**:
  - **Decision**: Use a large, centered artwork card (8px corner radius) with a static dark gradient background as the primary fallback.
  - **Rationale**: Ensures the artwork remains the "hero" of the view without the complexity of dynamic canvas-based extraction.

- **Interaction Patterns**:
  - **Decision**: Replace the "Heart" like button with the Spotify-standard **"+" icon**. Tapping it will trigger a "Added to Liked Songs" toast notification.
  - **Rationale**: Directly follows the "Like Feature" requirement in the Spotify design documentation.

## Risks / Trade-offs

- **[Risk] Browser Incompatibility with native fonts** → **Mitigation**: Use a robust font stack with `sans-serif` as the final fallback.
- **[Risk] Metadata Truncation** → **Mitigation**: Implement strict CSS rules (`white-space: nowrap`, `overflow: hidden`, `text-overflow: ellipsis`) and ensure touch-hold or hover allows viewing the full name.
- **[Risk] Contrast on Mobile** → **Mitigation**: Verify all color pairings against WCAG 2.1 AA standards, especially for `#1FDF64` on dark backgrounds.

## Migration Plan

1.  **Frontend Asset Update**: Overwrite `backend/public/styles.css` with the new Spotify-compliant variables and component rules.
2.  **HTML Refinement**: Update `backend/public/index.html` to reflect structural changes, particularly in the player controls and iconography.
3.  **Logic Synchronization**: Adjust `backend/public/app.js` to handle the new `+` icon state and any visual transitions between screens.
4.  **Verification**: Test responsiveness on mobile and desktop views.
5.  **Deployment**: Execute `gcloud builds submit` and `gcloud run deploy` to the `music-vault-shanin` service.
