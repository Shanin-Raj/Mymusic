## ADDED Requirements

### Requirement: Immediate Playback UI Update
The application MUST immediately update the UI to reflect a playback transition state without blocking the main UI thread with a full-screen or prolonged loading state while the audio buffers.

#### Scenario: User starts playing a new track
- **WHEN** the user selects a track to play
- **THEN** the UI MUST immediately transition to the "now playing" state locally and show a non-blocking buffering indicator if necessary, while the actual audio data loads in the background.
