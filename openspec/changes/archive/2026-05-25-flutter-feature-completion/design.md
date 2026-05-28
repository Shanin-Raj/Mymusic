## Context

The current Flutter application serves as a visual prototype with limited functionality. While the layout exists, the "engine" (audio playback, state management, and page transitions) is missing. To achieve feature parity with the existing web-based TWA, we need to implement a robust state management system and integrate the necessary native plugins.

## Goals / Non-Goals

**Goals:**
- Implement global state management to handle audio playback, favorites, and the current queue.
- Make the Music Player fully interactive (Seek, Play/Pause, Next/Prev, Like, Queue).
- Create and wire up the missing screens: Search, Settings, and Add Music.
- Replicate utility features like the Sleep Timer and Dark Mode toggle.
- Ensure the app is no longer static and reacts to data from the backend.

**Non-Goals:**
- Completely rewriting the existing UI layouts (we will fix and extend them, not replace them).
- Modifying the Node.js backend or Firebase structure.

## Decisions

- **Decision 1: State Management with `Provider`**
  - *Rationale*: For a music app of this scale, `Provider` with `ChangeNotifier` offers a balanced approach to managing the playback state (current track, position, isPlaying) and user data (favorites) across multiple screens (Home, Player, Library).
  
- **Decision 2: Persistent Background Audio via `audio_service`**
  - *Rationale*: To solve the background audio issues of the PWA, we will fully implement the `SonicAudioHandler`. This handler will be the single source of truth for the `just_audio` player and will interface with the Android OS for lockscreen controls.

- **Decision 3: Modular Screen Architecture**
  - *Rationale*: We will refactor the `MainScreen`'s `IndexedStack` to include the Search and Settings views. The "Add Music" interface will be implemented as a Modal or a dedicated route to maintain the clean Spotify-style navigation.

- **Decision 4: Local Persistence for Preferences**
  - *Rationale*: Use `shared_preferences` to store the user's Dark Mode preference, recently played tracks, and favorites to ensure they persist across app restarts.

## Risks / Trade-offs

- **Risk: Audio State Desync** → *Mitigation*: The `SonicAudioHandler` will emit streams of playback state that the `Provider` will listen to, ensuring the UI always reflects the actual player status.
- **Risk: UI Complexity in Player** → *Mitigation*: We will break the Player skeleton into smaller components (Playback Controls, Progress Bar, Metadata) to make implementation and debugging manageable.

## Migration Plan

1. **Phase 1: Audio Core**: Connect `just_audio` to the `playSong` logic and wire up the Mini Player and Full Screen Player buttons.
2. **Phase 2: Library & Search**: Implement the `ApiService` calls in the Search and Library views to make the track lists interactive and searchable.
3. **Phase 3: Settings & Utility**: Add the Dark Mode switch and Sleep Timer logic.
4. **Phase 4: Refinement**: Finalize the Queue management and "Add Music" workflows.
