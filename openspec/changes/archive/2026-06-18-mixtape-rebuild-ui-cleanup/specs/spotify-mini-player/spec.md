# spotify-mini-player Specification

## Purpose
TBD - created by archiving change spotify-ui-redesign. Update Purpose after archive.
## Requirements
### Requirement: Spotify Mini Player
The mini player SHALL appear as a persistent floating or docked bar just above the bottom navigation on the main screen, and at the bottom of all secondary detail screens (including Album, Playlist, and Artist detail screens). It MUST contain a square album art thumbnail on the left, track title and artist in the center, and play/pause and next track controls on the right, with a thin progress bar at the bottom (or wrapping the container).
To ensure the progress bar updates smoothly in real-time without freezes or stalling under all circumstances (even when system-level background notifications are deactivated), the progress indicator SHALL build its values by listening to the active player's internal position stream via `positionStream` mapped to `_audioHandler.appPositionStream` directly. To protect against layout crashes and rendering failures, the progress calculation SHALL explicitly verify that the track's duration is greater than zero before performing any division, falling back safely to a progress value of zero when uninitialized.
Additionally, the global mini player itself SHALL be wrapped in a `SafeArea` with `bottom: true` to prevent it from overlapping with system gesture elements when docked. The mini player layout on all secondary detail screens SHALL also respect bottom safe area insets (such as system gesture navigation or soft keys) to avoid overlap.

#### Scenario: Music is playing while browsing main view
- **WHEN** a track is active and the user is on the Home screen
- **THEN** the mini player is visible above the bottom navigation, showing current track info, playback controls, and a progress bar that smoothly advances in real-time.

#### Scenario: Music is playing while viewing detail screen
- **WHEN** a track is active and the user navigates to Album, Playlist, or Artist detail screen
- **THEN** the mini player is visible at the bottom of that detail screen, respecting system navigation bar safe area constraints, allowing uninterrupted playback controls.

