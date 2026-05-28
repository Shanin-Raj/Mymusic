## ADDED Requirements

### Requirement: Lockscreen and System Media Controls
The system SHALL integrate with the Web Media Session API to provide track metadata (title, artist, artwork) to the OS, allowing users to control playback from the Android lockscreen, notification shade, and hardware media keys seamlessly.

#### Scenario: Audio starts playing
- **WHEN** audio playback is initiated
- **THEN** the system SHALL update `navigator.mediaSession.metadata` with the current track's title, artist, and a high-resolution artwork URL
- **AND** the lockscreen SHALL display this metadata accurately

#### Scenario: Lockscreen transport controls
- **WHEN** the user interacts with the lockscreen media controls (Play, Pause, Next, Previous)
- **THEN** the system SHALL receive the corresponding media session action
- **AND** the application's internal playback state and UI SHALL immediately reflect the requested change without desynchronizing

#### Scenario: System seek actions
- **WHEN** the user seeks using a system-level media slider
- **THEN** the system SHALL update the audio element's current time based on the `seekto` action detail
- **AND** the app's internal slider SHALL sync to the new position
