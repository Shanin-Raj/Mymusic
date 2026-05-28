## MODIFIED Requirements

### Requirement: Spotify Full Screen Now Playing
The full screen player UI SHALL correctly apply the global theme context (Dark Mode) to all background, text, and icon elements. The UI SHALL wrap song details in a `StreamBuilder` listening to `audioHandler.mediaItem` to ensure real-time synchronization with the active track.

#### Scenario: User opens full screen player
- **WHEN** the user taps the mini player
- **THEN** the full screen player slides up, displaying the Spotify-style vertical layout with theme-consistent styling and auto-updating track metadata
