## 1. Investigation

- [x] 1.1 Inspect `flutter_app/lib/services/audio_handler.dart` to determine which audio package is used and how it initializes background/media session notifications.

## 2. Implementation

- [x] 2.1 Update the audio player initialization configuration to omit or disable the ongoing media notification.
- [x] 2.2 Verify that the status bar icon for media playback is no longer shown.
- [x] 2.3 Verify that audio can still play, pause, and handle focus changes properly (like incoming phone calls) while the app is in the foreground, without the notification.
