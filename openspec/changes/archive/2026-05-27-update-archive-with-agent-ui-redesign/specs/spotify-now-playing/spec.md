## MODIFIED Requirements

### Requirement: Spotify Full Screen Now Playing
The full screen player SHALL feature a top context header ("PLAYING FROM..."), a large square album art cover, song title/artist metadata on the left with a favorite button on the right, a functional seek slider with time stamps, transport controls (shuffle, previous, play/pause, next, repeat), and a bottom action bar with extra features. The system SHALL ensure the player UI respects the application's dark mode and theme settings by implementing the player layout from the Spotify-Clone repository. The UI SHALL wrap song details in a `StreamBuilder` listening to `audioHandler.mediaItem` to ensure real-time synchronization with the active track. The system SHALL pre-load the next track's audio source 30 seconds before the current track ends to ensure zero-latency transitions. The player SHALL be implemented as a fullscreen `Scaffold` route pushed onto the navigation stack via standard `Navigator.push` rather than an overlay modal bottom sheet, resolving gesture conflicts and status bar spacing.

#### Scenario: User opens full screen player
- **WHEN** the user taps the mini player
- **THEN** the full screen player is pushed onto the navigator stack as a fullscreen page route, animating into view and displaying the high-fidelity Spotify-style vertical layout with large artwork, theme-consistent styling, and prominent transport controls.
