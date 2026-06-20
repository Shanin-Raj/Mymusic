## Context

The "Mixtape" application has reached a stable visual baseline with the "Bright Editorial" redesign, but several user-experience "glitches" have been identified in the production environment. These range from branding inconsistencies (old name/logo) to critical playback interruptions. Most notably, UI interactions that should be purely cosmetic (like toggling Dark Mode or "Liking" a song) are triggering full audio reloads, which is unacceptable for a premium streaming experience.

## Goals / Non-Goals

**Goals:**
- **Branding Audit**: Finalize "Mixtape" as the name and the vinyl record as the logo across Web and Android.
- **Uninterrupted Audio**: Refactor UI state updates to be "audio-agnostic," ensuring that changing theme or track metadata does not reset the playback buffer.
- **Visibility Pass**: Hardened CSS for Dark Mode to ensure all player controls (especially the Like/Favorite button) are clearly visible.
- **Lockscreen Stability**: Ensure the "Pre-cache & Play Next" sequence fires reliably on mobile devices even when the screen is locked.

**Non-Goals:**
- Modifying the backend API or Firestore schema.
- Changing the PWA's service worker strategy for offline assets.

## Decisions

- **UI vs Engine Separation**: 
  - **Decision**: Refactor `app.js` to separate `playSong()` (which controls the audio engine) from `renderPlayerUI()` (which controls the visuals).
  - **Rationale**: Currently, `playSong()` is called during "Like" and "Theme" changes, which re-sets `audio.src`. By isolating the UI rendering, we can update the heart/plus icon state or theme colors without interrupting the stream.

- **Branding Standardization**:
  - **Decision**: Overwrite all instances of "Limitless" or placeholder titles with "Mixtape." Force the Android TWA manifest to use the latest vinyl logo PNGs.

- **Dark Mode Contrast**:
  - **Decision**: Explicitly set the `color` of `.player-extras` buttons to `var(--primary)` or `var(--on-surface)` in the `body.dark-mode` block.

- **Background Continuity**:
  - **Decision**: Utilize the `MediaSession` API's state tracking to signal to the OS that the app is an active media player. We will also ensure the `ended` event listener is registered globally once, rather than per-track, to avoid listener duplication or misses.

## Risks / Trade-offs

- **[Risk] State Desync**: If the UI is updated without re-calling the play logic, the active song object must be carefully tracked.
  - *Mitigation*: Use a global `currentSong` reference that persists across UI renders.
- **[Risk] Android Studio Complexity**: Updating the APK requires a manual build.
  - *Mitigation*: We will provide a specific "APK Finalization Checklist" for the user to follow in Android Studio Panda 4.

## Rethink Check: Regression Safety

Before touching the `audio.addEventListener` blocks, we must rethink the entire playback lifecycle. The current "Pre-caching" logic works well on the home screen; we must ensure that any "High Priority" locks added for the lockscreen do not block the existing shuffle/sequential prediction logic.
