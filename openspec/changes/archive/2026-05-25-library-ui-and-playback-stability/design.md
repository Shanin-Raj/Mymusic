## Context

The Music application's Library view currently provides basic functionality but lacks the visual refinement and "premium" feel expected of a modern media player. More critically, the playback engine occasionally enters a stalled state where audio stops and cannot be resumed without restarting the entire application process. This suggests lifecycle issues or unhandled exceptions within the background audio isolate.

## Goals / Non-Goals

**Goals:**
- Refine the `LibraryView` UI with improved spacing, typography, and professional icons.
- Implement a robust "watchdog" mechanism to detect and recover from playback hangs.
- Audit and harden `SonicAudioHandler` error handling to prevent state machine deadlocks.
- Improve the visual consistency of the Library tab to match the Spotify-inspired theme.

**Non-Goals:**
- Changing the underlying audio package (`just_audio`).
- Implementing new backend endpoints.

## Decisions

- **Decision 1: Refactor LibraryView with Slivers**
  - *Rationale*: Using `CustomScrollView` and `Sliver` components allows for more fluid scroll animations and professional header behaviors that standard lists cannot easily replicate.
- **Decision 2: Implement a Playback Watchdog in AudioHandler**
  - *Rationale*: By monitoring the playback position while in a "playing" state, the system can detect when audio has effectively stalled (e.g., position not advancing for >5 seconds) and trigger a safe reset of the player.
- **Decision 3: Global Error Boundary for Background Isolate**
  - *Rationale*: Ensuring all `just_audio` and `audio_service` calls are wrapped in robust try-catch blocks will prevent the background isolate from entering an unrecoverable state.

## Risks / Trade-offs

- **[Risk]**: The watchdog mechanism might trigger a reset during legitimate buffering on extremely slow connections.
  - **Mitigation**: The watchdog will only trigger after a significant threshold (e.g., 10 seconds of no progress while in 'ready' state) and will attempt a 'seek(current)' before a full reset.
- **[Risk]**: UI refactoring might introduce regressions in list performance.
  - **Mitigation**: Use `SliverList.builder` to ensure lazy loading is maintained.
