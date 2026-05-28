## MODIFIED Requirements

### Requirement: Spotify Full Screen Now Playing
The full screen player SHALL feature a top context header ("PLAYING FROM..."), a large square album art cover, song title/artist metadata on the left with a favorite button on the right, a functional seek slider with time stamps, transport controls (shuffle, previous, play/pause, next, repeat), and a bottom action bar with extra features. The system SHALL ensure the player UI respects the application's dark mode and theme settings by implementing the player layout from the Spotify-Clone repository. The UI SHALL wrap song details in a `StreamBuilder` listening to `audioHandler.mediaItem` to ensure real-time synchronization with the active track. The system SHALL pre-load the next track's audio source 30 seconds before the current track ends to ensure zero-latency transitions.

#### Scenario: User opens full screen player
- **WHEN** the user taps the mini player
- **THEN** the full screen player slides up, displaying the Spotify-style vertical layout with large artwork, theme-consistent styling, and prominent transport controls based entirely on the clone's layout structures.

#### Scenario: Background pre-loading
- **WHEN** the active track has less than 30 seconds remaining
- **THEN** the system SHALL trigger the pre-fetching logic for the next song in the queue

#### Scenario: User interacts with seek bar
- **WHEN** the user drags or taps the seek slider
- **THEN** the playback position SHALL jump to the corresponding time in the track

#### Scenario: Theme consistency
- **WHEN** the application is in dark mode
- **THEN** the full screen player SHALL apply dark background and light text colors consistently using the clone's theming implementation strategy.
