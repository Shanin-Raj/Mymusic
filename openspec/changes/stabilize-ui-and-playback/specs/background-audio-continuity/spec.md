## MODIFIED Requirements

### Requirement: Automatic Track Advancement on Lockscreen
The system SHALL transition to the next track in the queue automatically when the current track ends, regardless of whether the device screen is locked or the application is in the background. The system SHALL pre-load the metadata and pre-cache the audio stream of the subsequent track at least 45 seconds before the current track finishes to ensure a seamless background transition.

#### Scenario: Successful transition in background
- **WHEN** the current track reaches its end (`ended` event) while the phone is locked
- **THEN** the system SHALL immediately load and play the next track in the current playlist
- **THEN** the Android system notification SHALL update to show the new track metadata

#### Scenario: Background pre-caching
- **WHEN** the active track has 45 seconds remaining
- **AND** the device is locked
- **THEN** the system SHALL trigger a pre-cache request for the next song to ensure it is ready for an offline/background start
