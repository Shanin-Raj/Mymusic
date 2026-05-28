## 1. Library UI Refinement

- [x] 1.1 Refactor `LibraryView` in `main_screen.dart` to use `CustomScrollView` and `Sliver` widgets for fluid scrolling.
- [x] 1.2 Implement a refined header with professional-grade typography and Spotify-style filter chips.
- [x] 1.3 Audit and update list items for songs and playlists with consistent spacing, high-quality icons, and improved text styling.

## 2. Playback Stability Fixes

- [x] 2.1 Wrap all `just_audio` calls (play, seek, load) in `SonicAudioHandler` with `try-catch` blocks to prevent isolate stalls.
- [x] 2.2 Implement a `Timer`-based watchdog in `SonicAudioHandler` that monitors `playbackState.position` and triggers a recovery seek if progress stalls while playing.
- [x] 2.3 Add error logging to the background isolate to help diagnose any remaining edge-case hangs.

## 3. Verification

- [x] 3.1 Verify the Library UI looks professional and behaves correctly on devices with different aspect ratios and safe areas.
- [x] 3.2 Simulate a network interruption during playback and confirm that the system recovers gracefully once the connection returns.
- [x] 3.3 Confirm that manual app restarts (clearing from recents) are no longer required for playback continuity.
