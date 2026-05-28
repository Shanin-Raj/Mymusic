## MODIFIED Requirements

### Requirement: Playlist Creation
The system SHALL allow users to create new playlists with a custom name.

#### Scenario: User creates a playlist
- **WHEN** the user taps the "Add Playlist" button and enters a name
- **THEN** the system SHALL send a request to the backend to create the playlist
- **AND** the new playlist SHALL appear in the Library view

### Requirement: Add Song to Playlist
The system SHALL allow users to add any track from the library to an existing playlist through an intuitive UI component.

#### Scenario: User adds a track to a playlist
- **WHEN** the user selects "Add to Playlist" from a track's context menu
- **THEN** the system SHALL display a list of available playlists
- **AND** add the track to the selected playlist upon confirmation
- **AND** show a confirmation toast "Added to [Playlist Name]"
