## MODIFIED Requirements

### Requirement: Native Background Audio Service
The system SHALL utilize Flutter native audio packages (`audio_service` and `just_audio`) to manage an isolated background audio isolate, ensuring playback remains persistent when the app is minimized or the screen is locked. The system MUST declare the necessary Android service and receiver components in the application manifest to support this native background context.

#### Scenario: App goes to background
- **WHEN** audio is playing and the user minimizes the Flutter application
- **THEN** the audio playback SHALL continue uninterrupted
- **AND** the system SHALL maintain an active MediaSession native to Android OS

#### Scenario: Service component binding
- **WHEN** the `AudioService` is initialized by the plugin
- **THEN** the Android OS SHALL successfully instantiate the background isolate as declared in the manifest
