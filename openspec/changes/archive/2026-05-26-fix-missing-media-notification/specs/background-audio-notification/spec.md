## ADDED Requirements

### Requirement: Android Media Notification
The system SHALL display a persistent media control notification on Android devices when audio is playing in the background.

#### Scenario: Background audio playback starts
- **WHEN** the user starts playing a track and backgrounds the app
- **THEN** a media control notification MUST appear in the system notification shade showing the current track info and playback controls.

### Requirement: Android Foreground Service Permissions
The app MUST request and declare the appropriate foreground service and media playback permissions to satisfy Android 14+ requirements.

#### Scenario: App requests foreground service
- **WHEN** the audio service attempts to run as a foreground service
- **THEN** the Android system MUST grant permission without throwing a `SecurityException`, allowing the background service to run correctly.
