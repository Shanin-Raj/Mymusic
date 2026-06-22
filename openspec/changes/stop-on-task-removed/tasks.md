# Tasks: Stop Playback on Task Removed

## Phase 1: Code Implementation
- [x] 1.1 Locate `MyAudioHandler` in `flutter_app/lib/core/audio_handler.dart`.
- [x] 1.2 Override the `onTaskRemoved()` lifecycle method.
- [x] 1.3 Call `stop()` to halt playback and clear the notification service.
- [x] 1.4 Call `super.onTaskRemoved()` to pass the lifecycle call back to the library.

## Phase 2: Verification
- [ ] 2.1 Launch the application on a physical device or emulator.
- [ ] 2.2 Play a track.
- [ ] 2.3 Swipe the app away from the "Recents" screen.
- [ ] 2.4 Verify that playback stops and the media notification is dismissed.
