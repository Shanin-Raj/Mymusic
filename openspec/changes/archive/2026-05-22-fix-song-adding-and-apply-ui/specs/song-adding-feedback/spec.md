## ADDED Requirements

### Requirement: Detailed Error Feedback for Song Adding
The system SHALL provide specific error messages to the frontend when a song adding request fails, distinguishing between network timeouts, invalid URLs, and server-side errors.

#### Scenario: Telegram Timeout Error
- **WHEN** the backend fails to upload a song due to a Telegram connection timeout
- **THEN** the frontend SHALL display a user-friendly message such as "Connection to storage timed out. Retrying..." instead of a generic "Code Error 1"

### Requirement: Real-time Status Updates
The system SHALL communicate the progress of the song adding flow (e.g., "Fetching metadata", "Downloading", "Uploading to Vault") to the user.

#### Scenario: User Adds a Spotify Link
- **WHEN** a user submits a valid Spotify track URL
- **THEN** the UI SHALL show the current stage of the process until completion or failure
