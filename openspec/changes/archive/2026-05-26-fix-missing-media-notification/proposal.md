## Why

The app plays audio in the background, but the media notification is missing on Android. This prevents users from controlling playback (play, pause, skip) from their lock screen or notification shade, which is a standard expectation for audio apps.

## What Changes

- Add missing foreground service and media playback permissions to `AndroidManifest.xml`.
- Register the `audio_service` service in `AndroidManifest.xml` for `mediaPlayback`.
- Ensure a valid silhouette notification icon is provided for the Android media notification.

## Capabilities

### New Capabilities
- `background-audio-notification`: Enables persistent media controls and notifications when audio plays in the background on Android.

### Modified Capabilities

## Impact

- `android/app/src/main/AndroidManifest.xml`: Will include new permissions and service declarations.
- Android Assets: Need to ensure a valid white/transparent silhouette icon exists for notifications.
