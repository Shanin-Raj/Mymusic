# Background Audio Notification

## Purpose
Handles background audio notification, system media session, and foreground service requirements on Android 13+ and Android 14+.

## Requirements

### Requirement: Android Media Notification
The system SHALL display a persistent media control notification on Android devices when audio is playing.

#### Scenario: Background audio playback starts
- **WHEN** the user starts playing a track and backgrounds the app
- **THEN** a media control notification MUST appear in the system notification shade showing the current track info, playback controls, and lockscreen integration.

### Requirement: Android Foreground Service Permissions & Configs
The app MUST request and declare the appropriate foreground service and media playback permissions to satisfy Android 14+ requirements (API 34).

#### Scenario: App requests foreground service
- **WHEN** the audio service attempts to run as a foreground service
- **THEN** the Android system MUST grant permission without throwing a `SecurityException`, allowing the background service to run correctly compile-time and runtime.

### Requirement: Runtime Notification Permission
On Android 13+ (API 33+), the app MUST request POST_NOTIFICATIONS runtime permission before attempts to show notifications.

#### Scenario: Startup permission check
- **WHEN** the user launches the application
- **THEN** a prompt MUST check and request the notification permission if it has not been previously granted.

### Requirement: Standard PNG Drawable Icon
The notification icon MUST be a standard rasterized PNG resource located in the `drawable` folder to avoid system-level vector rendering or mipmap format crashes.
