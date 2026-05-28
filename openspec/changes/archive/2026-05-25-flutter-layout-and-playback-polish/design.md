## Context

The Flutter migration for the Music application is in progress. While the core structure exists, recent testing has identified several regressions and polish requirements. Specifically, the layout does not correctly account for Android's system bars (Status/Navigation), leading to clipping or awkward spacing. The 'Now Playing' screen, a central piece of the experience, has a non-functional seek bar and theme inconsistencies in dark mode. Furthermore, background playback functionality is incomplete, lacking the necessary system notifications and automatic track advancement that users expect from a music player.

## Goals / Non-Goals

**Goals:**
- Implement a robust `SafeArea` and `SystemUiOverlayStyle` strategy to handle all device aspect ratios and system bars.
- Repair the `Slider` or `ProgressBar` widget in the Now Playing screen and ensure it correctly updates the playback position via the audio service.
- Audit and fix the theme application in the Now Playing screen, ensuring full dark mode compliance.
- Configure `audio_service` and `just_audio` to properly handle track completion events and advance to the next item in the sequence.
- Ensure the `audio_service` configuration triggers the standard Android playback notification with correct metadata and controls.

**Non-Goals:**
- Implementing new UI features not mentioned in the regressions.
- Refactoring the entire audio service architecture unless necessary for the fixes.
- Modifying backend APIs.

## Decisions

- **Decision: Use `SafeArea` and `AnnotatedRegion` for Layout Polish**
  - **Rationale**: `SafeArea` is the idiomatic way in Flutter to avoid system intrusions. Combined with `AnnotatedRegion<SystemUiOverlayStyle>`, we can control the color and brightness of status/navigation bars to match the app's theme.
  - **Alternatives**: Manually calculating padding (error-prone) or using `SystemChrome` (can be harder to manage per-screen than `AnnotatedRegion`).

- **Decision: Bind Seek Bar to `just_audio` Position Stream**
  - **Rationale**: The seek bar should reflect the current position and allow seeking. `just_audio` provides streams for position, buffered position, and duration which are perfect for this.
  - **Alternatives**: Manual timer-based updates (less efficient and prone to drift).

- **Decision: Implement `onTaskFinished` and Stream Listening for Track Progression**
  - **Rationale**: By listening to the `processingState` or `playbackEvent` streams from the audio player, we can detect when a track ends and call `skipToNext()` on the `AudioHandler`.
  - **Alternatives**: Hardcoding progression in the UI layer (breaks when the app is in the background).

- **Decision: Verify `AudioHandler` Notification Config**
  - **Rationale**: The `audio_service` package automatically handles notifications if configured correctly. We need to ensure `androidNotificationChannelId`, `androidNotificationChannelName`, and the appropriate capabilities (play/pause/seek/skip) are enabled.

## Risks / Trade-offs

- **[Risk]**: `just_audio` and `audio_service` integration complexity.
  - **Mitigation**: Follow the established pattern in the codebase for `AudioHandler` and ensure all streams are properly disposed of.
- **[Risk]**: Aspect ratio issues on devices with "notches" or "hole-punches".
  - **Mitigation**: Use `SafeArea` with `minimum` padding if necessary and test on diverse emulator configurations.
- **[Risk]**: Battery optimization killing the background service.
  - **Mitigation**: Ensure `foreground` service permissions are correctly set in `AndroidManifest.xml` and the notification is persistent.

## Migration Plan

1.  **Layout Fixes**: Update the root `Scaffold` or wrapper widgets with `SafeArea` and `AnnotatedRegion`.
2.  **Audio Fixes**: Update the `AudioHandler` implementation to handle track completion and ensure notification parameters are set.
3.  **UI Fixes**: Connect the Now Playing seek bar to the position stream and fix theme/color constants.
4.  **Verification**: Test transitions, backgrounding, and manual/automatic seeking.
