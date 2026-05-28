## ADDED Requirements

### Requirement: Add Songs to Playlist from Detail View
The system SHALL provide a button within the playlist detail view to add songs to that specific playlist.

#### Scenario: User clicks "Add Songs"
- **WHEN** the user is viewing a playlist's details
- **AND** clicks the "Add Songs" button
- **THEN** the system SHALL present a selection UI with all available library songs

### Requirement: Reactive Playlist Updates
The system SHALL ensure the playlist detail view updates immediately when a song is added to it, without requiring an application restart.

#### Scenario: Song added to playlist
- **WHEN** a song is added to the current playlist
- **THEN** the track list in the playlist detail view SHALL refresh to include the new song
