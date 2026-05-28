## Why

Currently, when the app plays audio, it shows a media playback notification in the notification shade and a media icon in the status bar. The user requested to disable this behavior so that the app's playback is not advertised in the system notification shade or status bar. This provides a more "stealthy" or uninterrupted experience without cluttering the user's system UI.

## What Changes

- Disable the foreground service notification that typically shows media controls (play/pause, next, previous).
- Prevent the app from showing a media playback icon in the Android/iOS status bar.
- Modify the `audio_service` or underlying audio player configuration so it does not register as a standard system media session that requires an ongoing notification.

## Capabilities

### New Capabilities
- `disable-media-notifications`: Ensures that media playback does not trigger system-level notifications, media control widgets, or status bar icons.

### Modified Capabilities

## Impact

- `flutter_app/lib/services/audio_handler.dart`: The initialization and configuration of the `AudioService` (or `just_audio_background`) will be modified to disable system notifications.
- Dependencies: May require adjusting how `audio_service` or `just_audio` plugins are initialized, possibly dropping `just_audio_background` if it forces a notification.
