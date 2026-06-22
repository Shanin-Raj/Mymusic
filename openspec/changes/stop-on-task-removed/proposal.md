## Why

Currently, when the Mixtape application is removed from the recent tasks list (swiped away by the user), the background audio service and the active audio playback continue to run. While keeping audio playing in the background is desirable when navigating away from the app, explicitly swiping the app away from recents represents a user intent to close/exit the application entirely. Persisting audio playback and the notification in this scenario drains device battery, causes user confusion, and violates standard Android application lifecycle expectations.

## What Changes

- Implement task removal lifecycle detection in the Flutter audio service layer.
- Override `onTaskRemoved()` in `MyAudioHandler` (which extends `BaseAudioHandler`).
- Ensure that when the task is removed, `MyAudioHandler.stop()` is invoked to halt playback, release resources, and dismiss the ongoing media notification.

## Impact

- **Audio Handler (`flutter_app/lib/core/audio_handler.dart`)**: We will override `onTaskRemoved()` to stop playback and terminate the foreground service.
- **User Experience**: Swiping the app away from recents will immediately stop audio playback and clear the notification, matching user expectations for media applications on Android.
