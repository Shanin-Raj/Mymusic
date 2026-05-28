## Context

The Flutter application currently uses an audio playback mechanism (likely `audio_service`, `just_audio_background`, or a similar package) that integrates with the Android and iOS media session APIs. As a result, when music plays, the OS automatically displays a media control notification and a status bar icon. The user desires to turn off this integration so the app plays music without showing these system-level indicators.

## Goals / Non-Goals

**Goals:**
- Disable the ongoing media notification shown during playback.
- Disable the status bar media playing icon.
- Ensure audio continues to play correctly within the app itself without the system-level notification hooks.

**Non-Goals:**
- Modifying the in-app player UI.
- Changing how the app handles audio focus (we still want to pause on phone calls, but we just don't want the notification).

## Decisions

- **Audio Service Configuration:** We will modify the audio handler setup in `flutter_app/lib/services/audio_handler.dart`. If the app uses `audio_service`, we will explore disabling the notification by overriding the `PlaybackState` to not include `playing` or by not calling the background task setup, depending on the specific package used. If it uses `just_audio_background`, we may need to remove it and revert to standard `just_audio` without background notification support, assuming background playback isn't strictly required to have a notification (note: Android requires a foreground service notification for long-running background tasks, so removing the notification might mean playback stops when the app is backgrounded unless handled carefully).
- **Alternative:** If background playback *is* required, Android 13+ requires a notification for foreground services. If the user absolutely wants no notification, we may have to accept that background playback could be killed by the OS, or we use a "stealth" transparent notification (which is against Android guidelines and might still show an empty space). The primary decision is to disable the `MediaStyle` notification.

## Risks / Trade-offs

- **Risk**: On Android, background playback is tied to Foreground Services, which *require* a visible notification. Removing the notification entirely might cause the OS to kill the audio playback when the app goes into the background.
  - **Mitigation**: We need to configure the audio player to not use a foreground service if we don't want a notification, understanding the trade-off that true background play might be restricted, or we find a configuration that avoids the *media* style notification specifically, though a basic notification might still be required by Android if it's a foreground service.
