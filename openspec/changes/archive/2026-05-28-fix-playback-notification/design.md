## Context

On newer Android versions (Android 13+ and Android 14), strict runtime permission models and foreground service constraints block playback notifications unless:
1. `POST_NOTIFICATIONS` is explicitly declared in the manifest and requested via runtime prompts.
2. The compilation target matches dependencies, while target SDK satisfies Android 14 requirements.
3. MediaSession events and PlaybackState changes are mapped in real-time.
4. PlaybackState transitions (playing: true) are broadcast synchronously during the user click context window to bypass Android 12+ Foreground Service launch restrictions.
5. The small icon resource is a compliant transparent stenciled vector drawable.
6. The notification channel ID is refreshed to override old system properties.
7. Unnecessary safe area blocks are removed in screens that do not possess a bottom navigation bar, letting the player sit close to the bottom edge.

## Goals / Non-Goals

**Goals:**
- Implement robust runtime notification permission requesting via `permission_handler` on startup.
- Compile with `compileSdk = 36` to satisfy dependency requirements, keeping `targetSdk = 34` for Android 14 behaviors.
- Ensure 100% notification visibility by implementing a unified state update stream, immediate click-time state updates, direct metadata injection on skips, stenciled vector icons, and refreshed channel configurations.
- Polish layout paddings inside Playlist, Artist, and Album detail views, eliminating the unnecessary bottom safe area padding underneath the player and standardizing bottom list paddings to clear the floating player beautifully.

**Non-Goals:**
- Modify visual player layouts or home feed UI.
- Change the core backend APIs or local audio parsing schemes.

## Decisions

- **Listen to both playerStateStream and playbackEventStream:** This eliminates edge cases where state transitions (like direct UI play/pause toggles) aren't caught by only listening to platform events.
- **Synchronous playing: true broadcasts on click:** Bypasses OS foreground service blocks by promoting the service inside the active user interaction window rather than waiting for player buffering.
- **Retain stenciled vector drawable ic_notification.xml:** Android status bar rules dictate transparent, single-color alpha stencil masks. Full-color launcher images are discarded by system builders.
- **Refresh channel ID to audio_v3:** Forces a clean registration of the notification channel with high-importance defaults.
- **Remove SafeArea wrapping MiniPlayer in detail screens:** Since these detail views have no bottom navigation bar, removing `SafeArea` allows the player to sit natively and beautifully close to the bottom edge, overlaying gestural lines perfectly.
- **Standardize scroll paddings to flat 90:** Polishes scroll layouts inside the playlist view (both empty and populated) to clear the active `MiniPlayer` without creating double spaces.

## Risks / Trade-offs

- None expected.
