## Context

The SonicVault web/mobile application has implemented deep custom Spotify aesthetics and offline caching, but suffered from operating-system command mismatches, background position stream deactivations, centered alignment equalizer visualizers, and a lack of user-facing song addition dialogues in the mobile application shell. This design outlines how we cleanly integrate these platform-aware fixes and modular additions.

## Goals / Non-Goals

**Goals:**
- Resolve backend yt-dlp binary spawn crashes on Windows development servers dynamically while maintaining Cloud Run compatibilities.
- Map the progress-bar duration tracking to the active `appPositionStream` directly to bypass silent background service notifications.
- Anchor the equalizer animation to bottom layouts, scaling bar heights dynamically to match sizing constraints.
- Implement a highly decoupled, modular universal song adder dialog that is safely removable and self-contained.

**Non-Goals:**
- Rewriting or replacing backend downloader engines or the private Telegram media channel vaults.
- Redesigning other parts of the home feed, search tab, or media controllers.

## Decisions

### 1. Platform-Aware Python Commands
- **Choice**: Checking `process.platform === 'win32'` at runtime inside Node.js.
- **Why**: Windows command prompt identifies Python as `python`, whereas Linux shells typically call it `python3`. Dynamically setting this command string prevents exit code 1 failures in development without breaking production Docker container builds.
- **Alternatives considered**: Setting a `PYTHON_CMD` environment variable, which requires manual setup by developer, adding friction.

### 2. Stream Mapping for Seek Bars
- **Choice**: Directing `PlayerProvider.positionStream` to return `_audioHandler.appPositionStream` (mirroring `just_audio` player position).
- **Why**: Since system-facing notifications were deactivated, the global `AudioService.position` remains completely idle. Redirecting the provider stream ensures the progress bar updates in real-time under all circumstances.
- **Alternatives considered**: Polling player position every 500ms via custom timers, which adds cpu overhead and is less reactive.

### 3. Bottom-Anchored Equalizer Animation
- **Choice**: Placing bars in a Row styled with `crossAxisAlignment: CrossAxisAlignment.end` and scaling bar heights by `size * heightFactor`.
- **Why**: Anchoring to the bottom and dynamically calculating height relative to the parent sizing constraint guarantees smooth, hardware-style equalizer growth without vertical jitter or clipping.
- **Alternatives considered**: Hardcoding height heights or letting items stretch vertically, causing erratic visual jumps.

### 4. Fully Isolated Standalone Adder Class
- **Choice**: Packaging all forms inputs, checkboxes, loaders, and success screens inside a single self-contained `UniversalAdderDialog` class.
- **Why**: This complies perfectly with the requirement that the adder is safely removable at any time by simply deleting the `+` action icon callback or removing the widget class with zero side-effects.

## Risks / Trade-offs

- **[Risk]** Slow networks during yt-dlp metadata downloads could cause timeouts or freezes in the adder form.
  - **[Mitigation]** Replaced the form with a high-fidelity loading overlay with distinct text progress states ("Extracting metadata...", "Syncing media files...") to keep the user informed.
