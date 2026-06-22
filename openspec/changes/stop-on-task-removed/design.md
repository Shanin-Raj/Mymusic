## Context

The Flutter application utilizes the `audio_service` package to run a background service with a persistent notification. This prevents Android from garbage collecting the audio player's process while in the background. However, when the user swiped the app out of the Android "Recents" task list, the foreground service remained active, continuing playback and keeping the media notification on the lock screen/notification drawer.

## Decisions

**1. Leverage `audio_service` Lifecycle Callbacks:**
*Decision:* Override `onTaskRemoved` in our custom `MyAudioHandler`.
*Rationale:* `audio_service` binds to Android's service lifecycle. When the application task is swiped away from recents, the Android system notifies the service via `onTaskRemoved`. `audio_service` translates this Android service hook into the `onTaskRemoved()` callback in Dart.

**2. Synchronous/Immediate Stop Sequence:**
*Decision:* Stop the player, clean up active timers, and shut down the service.
*Rationale:* Inside `onTaskRemoved()`, we call `stop()`. This performs:
- `_player.stop()`: Stops the audio decoder immediately.
- `_watchdogTimer?.cancel()`: Prevents any background playback recovery watchdog from trying to resume playback.
- `super.stop()`: Notifies the OS that the media session is inactive, allowing the foreground service to stop and the notification to be removed.
- `super.onTaskRemoved()`: Finalizes the service destruction.

## Alternatives Considered

- **Using a native Android BroadcastReceiver/Service check**: This requires custom Java/Kotlin platform code in `MainActivity.kt`. Since `audio_service` already wraps this lifecycle event in the `onTaskRemoved()` hook, implementing it in Dart is cleaner, safer, and keeps lifecycle logic centralized in the handler.

## Risks / Trade-offs

- **Risk:** Some users might swipe the app away expecting audio to continue playing (a behavior of some older players).
- **Mitigation:** The industry standard (e.g., Spotify, YouTube Music, Apple Music) stops playback when the app is swiped away from recents. This change aligns the application with modern UX expectations.
