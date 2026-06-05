# Capability: Native Background Audio Service

The system SHALL utilize Flutter native audio packages (`audio_service` and `just_audio`) to manage an isolated background audio isolate, ensuring playback remains persistent when the app is minimized or the screen is locked.

## Requirements

### Requirement: Native Background Audio Service
The system SHALL utilize Flutter native audio packages (`audio_service` and `just_audio`) to manage an isolated background audio isolate, ensuring playback remains persistent when the app is minimized or the screen is locked. The system MUST ensure the `MediaItem` is correctly yielded to the `audio_service` on track changes, and the `androidNotificationIcon` is explicitly set to `'drawable/ic_notification'`. The system MUST implement comprehensive error handling for all audio lifecycle events to prevent the background isolate from entering a stalled or unrecoverable state.

To guarantee that the media notification is displayed properly across all Android OEM skins (such as Xiaomi/MIUI) and build configurations:
- The system MUST preserve all media control icons (drawables) in `android/app/src/main/res/raw/keep.xml` using `@drawable/*` to prevent the R8/Proguard resource shrinker from stripping them in release builds.
- The system MUST advertise `MediaAction.play`, `MediaAction.pause`, and `MediaAction.stop` in the `systemActions` configuration of the `PlaybackState` at all times, ensuring the OS media widget detects and renders the play/pause and stop controls correctly.

#### Scenario: App goes to background
- **WHEN** audio is playing and the user minimizes the Flutter application
- **THEN** the audio playback SHALL continue uninterrupted
- **AND** the system SHALL maintain an active MediaSession native to Android OS with all required media actions advertised

#### Scenario: Recovery from unhandled exception
- **WHEN** an unhandled exception occurs in the audio isolate (e.g., network timeout)
- **THEN** the system SHALL catch the error, log it, and attempt to resume playback or notify the user of the error state without hanging.
