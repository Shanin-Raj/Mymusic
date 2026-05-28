## Why

The current Flutter application, while visually resembling the target music app, suffers from critical functional gaps and UI inconsistencies. Key issues include a non-responsive "Now Playing" interface, broken queue management where clicking any song defaults to the start of the library, and missing essential features like playlist creation and comprehensive search. To provide a seamless "native" evolution of the web app, we must fix the underlying state synchronization between the audio engine and the UI while implementing the missing feature set.

## What Changes

- **Audio Engine State Sync**: Fix the `SonicAudioHandler` to correctly broadcast the current `mediaItem` and playback index, ensuring the UI (Mini Player and Full Screen Player) stays in sync.
- **Queue Logic Fix**: Refactor the playback logic to ensure that tapping a specific song plays *that* song and correctly populates the upcoming queue from the current context (Mix or Library).
- **UI Replication**:
    - Implement the missing "Now Playing" bar and its transition to the full-screen player.
    - Add horizontal carousels for "Mixes" and "Recently Synced" on the Home screen to match the web app.
    - Implement a functional Search page with real-time filtering.
    - Add UI for Playlist creation and management.
- **Feature Completion**:
    - Implement the "Add Music" interface for syncing YouTube/Spotify links.
    - Add the "Queue" and "Sleep Timer" buttons to the player window.
    - Implement the "Like" button with persistence.

## Capabilities

### New Capabilities
- `flutter-state-sync`: Robust synchronization between `audio_service` and the UI providers to ensure real-time metadata and position updates.
- `flutter-playlist-crud`: Ability to create, view, and modify playlists within the Flutter app.
- `flutter-enhanced-search`: Real-time searching and filtering of the music vault.
- `flutter-add-music-flow`: Integration with the backend `/api/add-song` endpoint for adding new tracks via URLs.

### Modified Capabilities
- `flutter-audio-player`: Overhauling the queue and index management to support context-aware playback.
- `spotify-now-playing`: Completing the player window UI with all functional utility buttons (Like, Queue, Timer).

## Impact

- **UI/UX**: Transition from a static/broken UI to a fully interactive, Spotify-style experience.
- **Logic**: Centralization of playback state in the `AudioHandler` with reliable propagation to the UI.
- **Stability**: Fixing the "play from beginning" bug and ensuring playback continues across tracks in the queue.
