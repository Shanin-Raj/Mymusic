## Context

To enhance application stability and aesthetic fidelity, we have deployed critical UI, player, and asset pipeline refinements to the Mixtape Spotify-clone application. This document details the technical and design choices behind these updates to serve as a long-term reference.

## Goals / Non-Goals

**Goals:**
- Resolve missing playlist cover images by bundling cover assets inside the backend deployment and using robust dual-path resolving.
- Replace static backgrounds in `PlaylistDetailScreen` with dynamic, seeded, HSL-based linear gradients tailored to each playlist's identifier.
- Protect progress indicators inside `MiniPlayer` from division-by-zero (`NaN`/`Infinity`) failures when track duration is zero or uninitialized.
- Eliminate layout-related flickering in `NowPlayingAnimation` by wrapping animated equalizer bars in a static size boundary.
- Integrate a premium refresh action in the Library view to pull newly added songs and force clear cache.

**Non-Goals:**
- Implementing any new database collections or schemas.
- Modifying the underlying `just_audio` playback engine behaviors.

## Decisions

- **Bundled Backend Cover Images and Dual-Path Resolving**:
  - *Decision*: Copied local images from `d:\music\images\` to `d:\music\backend\images/` so they are fully packaged with the backend code, and refactored `server.js` to check both sibling `../images` and internal `images/` directory.
  - *Rationale*: Google Cloud Run isolation prevents access to directories outside the deployed `backend/` folder. Storing assets internally ensures that containerized environments can successfully serve cover artwork.

- **Seeded HSL Gradient Generator**:
  - *Decision*: Implemented `_getPlaylistGradient(String id, bool isDark)` that hashes the playlist ID and maps it to specific HSL boundaries.
  - *Rationale*: Hardcoded static backgrounds feel generic. Using seeded dynamic HSL gradients ensures each playlist gets a distinct, stunning linear background that is completely stable and consistent across page navigations.

- **Progress Bar Division-by-Zero Protection**:
  - *Decision*: Refactored `MiniPlayer` progress calculation to verify `duration.inMilliseconds > 0` before division, defaulting safely to `0.0`.
  - *Rationale*: When a track is loading or manually added without metadata, track duration resolves to `0` or `null`. Dividing by zero in double division results in `NaN`/`Infinity` in Dart, which crashes or blocks the rendering of the progress indicator.

- **Static Size Equalizer Boundary Isolation**:
  - *Decision*: Wrapped each dynamically-resized equalizer `_Bar` container in a static `SizedBox` with `Align(alignment: Alignment.bottomCenter)`.
  - *Rationale*: Animating equalizer container heights directly inside a standard `Row` forces high-frequency layout changes and repaints. Isolating the bars inside a static box ensures the layout engine sees a static boundary, preventing layout thrashing and parent widget flickering.

- **Library Force Refresh Button**:
  - *Decision*: Added a refresh icon button in the `LibraryView` AppBar actions to force reload `ApiService.fetchSongs(forceRefresh: true)`.
  - *Rationale*: Allows users to manually clear the local cache and fetch newly added tracks from both CLI and background workers immediately without restarting the app.

## Risks / Trade-offs

- **[Risk] HSL Vibe Mismatch** → Seeded HSL calculations could select a color that is too bright or dull for the dark/light mode.
  - *Mitigation*: Strictly constrained the Saturation and Lightness values in both modes (Saturation: 25%–55%, Lightness: 10%–30% in dark, 75%–95% in light) to guarantee all generated colors maintain a high-contrast, premium, cohesive look.
