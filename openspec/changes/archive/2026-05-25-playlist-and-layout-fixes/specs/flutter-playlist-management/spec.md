## MODIFIED Requirements

### Requirement: Reactive Playlist Updates
The system SHALL ensure the playlist detail view updates immediately when a song is added to it, without requiring an application restart. The UI SHALL be synchronized with the underlying state provider to reflect changes in real-time.

#### Scenario: Song added to playlist
- **WHEN** a song is added to the current playlist
- **THEN** the track list in the playlist detail view SHALL refresh immediately to include the new song
- **AND** the change SHALL be reflected across all views displaying that playlist
