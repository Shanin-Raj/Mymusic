## ADDED Requirements

### Requirement: Disable Media Notifications
The system SHALL NOT display a media playback notification in the system notification shade when audio is playing.

#### Scenario: Audio playback starts
- **WHEN** the user initiates audio playback within the app
- **THEN** the system does not create a media notification for the app

### Requirement: Disable Status Bar Icon
The system SHALL NOT display a media playing icon in the system status bar during playback.

#### Scenario: Audio is playing
- **WHEN** audio is actively playing in the app
- **THEN** the status bar remains clear of any media-related icons for this app
