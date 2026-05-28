## Context

The app currently uses `audio_service` along with `just_audio` to manage background audio playback. However, it fails to show a media control notification on Android. This is typically caused by missing foreground service declarations, missing permissions (especially in Android 14+), or invalid notification icons.

## Goals / Non-Goals

**Goals:**
- Enable the Android background media notification for the existing `audio_service` implementation.
- Add required `WAKE_LOCK`, `FOREGROUND_SERVICE`, and `FOREGROUND_SERVICE_MEDIA_PLAYBACK` permissions.
- Declare the `com.ryanheise.audioservice.AudioService` component correctly in the Android Manifest.

**Non-Goals:**
- Migrating away from `audio_service` or redesigning the audio handler.
- Implementing iOS-specific background audio changes (assuming they already work or are out of scope for this specific Android notification fix).

## Decisions

1. **Manifest Permissions**:
   - **Decision:** Add `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />`, `<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>`, and `<uses-permission android:name="android.permission.WAKE_LOCK"/>` to `AndroidManifest.xml`.
   - **Rationale:** Android requires these permissions for any app that wants to run a foreground service, specifically for media playback in Android 14 (API 34).

2. **Service Declaration**:
   - **Decision:** Add the `<service>` tag for `com.ryanheise.audioservice.AudioService` with `android:foregroundServiceType="mediaPlayback"` in the `<application>` block of the manifest.
   - **Rationale:** The system needs this declaration to correctly bind the foreground service and display the media notification.

3. **Notification Icon Check**:
   - **Decision:** Verify and create (if missing) a silhouette icon for the notification in `android/app/src/main/res/drawable/`.
   - **Rationale:** Android media notifications require a flat silhouette icon on a transparent background, otherwise they render as a white square or cause crashes on some devices.

## Risks / Trade-offs

- [Risk] On Android 14, missing `FOREGROUND_SERVICE_MEDIA_PLAYBACK` causes a `SecurityException` crashing the app when the service starts.
  → **Mitigation:** Carefully verifying the exact permission string in the Manifest to prevent this crash.
