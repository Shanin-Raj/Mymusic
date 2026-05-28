# spotify-now-playing Specification

## Purpose
TBD - created by archiving change spotify-ui-redesign. Update Purpose after archive.
## Requirements
### Requirement: Spotify Full Screen Now Playing
The full screen player SHALL feature a top context header ("PLAYING FROM..."), a large square album art cover, song title/artist metadata on the left with a favorite button on the right, a functional seek slider with time stamps, transport controls (shuffle, previous, play/pause, next, repeat), and a bottom action bar with extra features. The system SHALL ensure the player UI respects the application's dark mode and theme settings by implementing the player layout from the Spotify-Clone repository. The UI SHALL wrap song details in a `StreamBuilder` listening to `audioHandler.mediaItem` to ensure real-time synchronization with the active track. The system SHALL pre-load the next track's audio source 30 seconds before the current track ends to ensure zero-latency transitions. The player SHALL be implemented as a fullscreen `Scaffold` route pushed onto the navigation stack via standard `Navigator.push` rather than an overlay modal bottom sheet, resolving gesture conflicts and status bar spacing.
To guarantee real-time progression tracking and zero freezes, the functional seek slider SHALL listen to the active player's internal position stream via `positionStream` mapped to `_audioHandler.appPositionStream` directly.
Additionally, when a song is playing, the album artwork SHALL display an overlay equalizer visualizer (`NowPlayingAnimation`). To prevent vertical jitter and flickering, the visualizer bars MUST align using `CrossAxisAlignment.end` in the container `Row`, forcing all equalizer bars to be anchored at the bottom and animate upwards. The maximum height of these animation bars MUST dynamically scale with the parent `size` parameter (`size * heightFactor`) rather than utilizing hardcoded values, preventing clipping and visual misplacement.

#### Scenario: User opens full screen player
- **WHEN** the user taps the mini player
- **THEN** the full screen player is pushed onto the navigator stack as a fullscreen page route, animating into view and displaying the high-fidelity Spotify-style vertical layout with large artwork, theme-consistent styling, and prominent transport controls.

#### Scenario: Real-time seek bar progress
- **WHEN** a song is active and playing in the full screen player
- **THEN** the seek slider and elapsed time stamp update smoothly in real-time, accurately reflecting the playback position.

#### Scenario: Anchored equalizer animation
- **WHEN** music is playing in the full screen player
- **THEN** the equalizer bars overlaying the album art grow cleanly upwards from the bottom boundary with zero center-jitter or flickering, colored in high-contrast white.

