## MODIFIED Requirements

### Requirement: Native Background Audio Service
The system SHALL utilize Flutter native audio packages (`audio_service` and `just_audio`) to manage an isolated background audio isolate, ensuring playback remains persistent when the app is minimized or the screen is locked. The system MUST ensure the `MediaItem` is correctly yielded to the `audio_service` on track changes and the `androidNotificationIcon` is explicitly set to 'mipmap/ic_launcher'.

#### Scenario: App goes to background
- **WHEN** audio is playing and the user minimizes the Flutter application
- **THEN** the audio playback SHALL continue uninterrupted
- **AND** the system SHALL maintain an active MediaSession native to Android OS
