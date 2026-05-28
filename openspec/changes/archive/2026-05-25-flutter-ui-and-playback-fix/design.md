## Context

The current Flutter implementation is a skeleton that lacks functional state synchronization and several core features present in the original web app. Most notably, the "Now Playing" UI is invisible due to broken stream listeners, and the playback engine always starts from the first track regardless of user selection. We need to unify the state management between the `just_audio` engine and the Flutter UI.

## Goals / Non-Goals

**Goals:**
- Fix the `AudioHandler` to reliably broadcast the current song metadata (`mediaItem`).
- Implement the "Now Playing" bar and the full-screen player with 1:1 parity with the web app.
- Re-architect the playback logic to support playing a specific song and maintaining a contextual queue.
- Replicate the Home, Search, and Library screens including playlist management.
- Ensure the app provides a cohesive "Spotify-like" UX.

**Non-Goals:**
- Implementing offline caching (to be addressed in a future change).
- Redesigning the API endpoints.

## Decisions

- **Decision 1: Use `currentIndexStream` for Metadata Updates**
  - *Rationale*: The `audio_service` needs to know which track is playing from the `ConcatenatingAudioSource`. We will listen to the player's index changes within the `AudioHandler` and update the `mediaItem` sink immediately. This will trigger the `MiniPlayer` to become visible.

- **Decision 2: Contextual Playback Logic**
  - *Rationale*: When a user taps a song, they expect *that* specific song to play and the rest of the list to become the upcoming queue. We will modify `playSong` to accept a list of tracks and an initial index, clearing the existing `ConcatenatingAudioSource` and rebuilding it for every new context (e.g., tapping a song in a Search result vs. a Mix).

- **Decision 3: Modularize Player UI**
  - *Rationale*: To match the web app's sophisticated player, we will build a `FullScreenPlayer` widget that uses `StreamBuilder` and `Provider` to react to position and metadata changes without full-page rebuilds.

- **Decision 4: Real-time Search Filtering**
  - *Rationale*: We will implement a `SearchProvider` or use local state within the `SearchView` to filter the library in real-time using a `TextEditingController`.

## Risks / Trade-offs

- **Risk: Memory leaks with streams** → *Mitigation*: Ensure all stream subscriptions in `AudioHandler` and `PlayerProvider` are cancelled or managed by the lifecycle of the handler/provider.
- **Risk: UI lag during queue rebuild** → *Mitigation*: Using `just_audio`'s `ConcatenatingAudioSource` allows for efficient updates without stopping the audio.

## Migration Plan

1. **Fix Audio Core**: Update `SonicAudioHandler` to correctly handle index changes and metadata propagation.
2. **Implement MiniPlayer**: Ensure the persistent bar is visible and functional across all navigation tabs.
3. **Build Full-Screen Player**: Implement the sliding player window with all transport controls.
4. **Functionalize Navigation Tabs**:
    - **Home**: Add carousels for Mixes and Recently Synced.
    - **Search**: Implement real-time library filtering.
    - **Library**: Add playlist creation and song management.
5. **Fix Add Music**: Wire up the "Add Music" FAB and sync logic.
