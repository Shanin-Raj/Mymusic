## ADDED Requirements

### Requirement: YouTube/Spotify URL Synchronization
The system SHALL provide an interface for users to submit external music URLs for backend synchronization.

#### Scenario: User adds a YouTube link
- **WHEN** the user pastes a YouTube URL into the "Add Music" modal and taps "Sync"
- **THEN** the system SHALL send the URL to the backend `/api/add-song` endpoint
- **AND** display a success notification when the sync process starts
