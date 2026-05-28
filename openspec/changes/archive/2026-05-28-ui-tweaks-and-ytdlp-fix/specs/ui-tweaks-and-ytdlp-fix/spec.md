## ADDED Requirements

### Requirement: Unified Detail Screen Navigation
The AppBottomNav SHALL be presented at the bottom of the AlbumDetailScreen, ArtistDetailScreen, and PlaylistDetailScreen.

#### Scenario: Displaying Nav Bar on detail screens
- **WHEN** the user navigates to an Album, Artist, or Playlist
- **THEN** they see the AppBottomNav at the bottom of the screen with Home, Search, and Library icons.

### Requirement: MiniPlayer over System Gestures
The MiniPlayer SHALL sit cleanly above the bottom navigation bar so it is never clipped or blocked by Android's system gesture bar.

#### Scenario: MiniPlayer placement
- **WHEN** the user has a song playing and visits a detail screen
- **THEN** the MiniPlayer is stacked cleanly on top of the AppBottomNav.

### Requirement: JavaScript Runtime for Audio Extraction
The yt-dlp backend extraction tool MUST be invoked with the `--js-runtimes nodejs` argument.

#### Scenario: Ciphered Youtube video extraction
- **WHEN** downloading a ciphered or age-restricted music video via yt-dlp
- **THEN** it successfully executes the javascript challenge without logging JS runtime warnings and proceeds to download.

### Requirement: Song argument for SongTile (Artist screen)
The ArtistDetailScreen MUST pass the current `song` object into the `SongTile`'s play tap callback.

#### Scenario: Playing an artist song
- **WHEN** the user taps a song inside ArtistDetailScreen
- **THEN** it successfully loads the correct `song` into the `PlayerProvider`.
