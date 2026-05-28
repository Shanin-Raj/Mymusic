## ADDED Requirements

### Requirement: Playlist Visualization
The system SHALL fetch and display a list of all user-created playlists from the `/api/playlists` endpoint.

#### Scenario: User opens playlists view
- **WHEN** the user navigates to the Library and taps "Playlists"
- **THEN** the system SHALL display a grid or list of playlist cards with their names and track counts

### Requirement: Playlist Content View
The system SHALL allow users to view all songs contained within a specific playlist.

#### Scenario: User taps a playlist
- **WHEN** the user selects a playlist card
- **THEN** the system SHALL navigate to a detailed view showing all songs in that playlist
- **AND** allow the user to play any song from that view
