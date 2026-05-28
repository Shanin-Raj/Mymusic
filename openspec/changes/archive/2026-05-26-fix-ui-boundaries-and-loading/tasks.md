## 1. UI Safe Area Adjustments

- [x] 1.1 Locate the main root widget (`MaterialApp` or root `Scaffold`) in the `flutter_app` codebase.
- [x] 1.2 Wrap the main screen content or scaffold body in a `SafeArea` widget to restrict UI components within system boundaries.
- [x] 1.3 Verify the "Now Playing" bar layout specifically to ensure it renders correctly above the system navigation bar on devices with edge-to-edge screens.
- [x] 1.4 Test layout constraints to ensure no unwanted letterboxing exists on screens that may require full-screen bleeds (and adjust with `AnnotatedRegion` or selective padding if needed).

## 2. Playback State Responsiveness Fix

- [x] 2.1 Locate the audio playback state management logic triggered when a track is selected to play.
- [x] 2.2 Refactor the track selection handler so that the UI state (e.g., "playing" or "buffering") updates synchronously before initiating the asynchronous audio load.
- [x] 2.3 Ensure any full-screen or blocking loading indicators are removed from the playback transition flow.
- [x] 2.4 Verify that error handling correctly resets the UI state if the asynchronous audio load fails.
