## MODIFIED Requirements

### Requirement: Album Detail View Layout
The application SHALL provide a dedicated dynamic screen for viewing album details, styled with a high-fidelity red-to-black background gradient: `[const Color(0xFFC63224), const Color(0xFF641D17), const Color(0xFF271513), const Color(0xFF121212)]`. It MUST show the album artwork, the album title, the artist's name, and a list of all songs belonging to that album. The system MUST NOT group songs belonging to the `"Manual Addition"` album under `"Spotify Songs"`; `"Manual Addition"` SHALL be treated as its own separate and distinct album.

#### Scenario: User navigates to album detail
- **WHEN** the user selects an album in their library
- **THEN** the application transitions to the custom Album detail screen, displaying the corresponding album artwork, dynamic metadata, and its filtered list of tracks loaded from Firebase.

#### Scenario: User views manual addition album
- **WHEN** the user views the dedicated "Manual Addition" album
- **THEN** only manually synced/added songs are displayed in the track list

### Requirement: Album Shuffle Playback
The Album detail screen SHALL include a green play/shuffle floating action button which, when pressed, triggers shuffled playback of all songs belonging to this specific album.

#### Scenario: Shuffling album tracks
- **WHEN** the user taps the play/shuffle button on the Album screen
- **THEN** the audio player starts playing the first track of a randomized queue containing only this album's songs.
