## ADDED Requirements

### Requirement: Music Synchronization via URL
The system SHALL provide an interface for users to submit YouTube or Spotify URLs to the backend `/api/add-song` endpoint for synchronization.

#### Scenario: User adds track via link
- **WHEN** the user pastes a YouTube URL into the "Add Music" field and taps "Sync"
- **THEN** the system SHALL send the request to the server
- **AND** show a loading indicator or progress status during the sync process
