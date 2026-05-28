## Why

The Library UI needs refinements to match modern design standards and provide a more professional feel. Additionally, intermittent playback stability issues where songs stop playing unexpectedly are degrading the user experience and requiring app restarts.

## What Changes

- **Library UI Refinement**: Update the `LibraryView` with improved aesthetics, better spacing, and professional-grade typography/icons.
- **Playback Stability Fixes**: Investigate and resolve the root cause of intermittent playback hangs, ensuring the `AudioHandler` remains active and recovers from errors gracefully.
- **Improved Lifecycle Management**: Ensure the background service is robust against system-level kills and correctly handles audio focus and track transitions.

## Capabilities

### New Capabilities
- `playback-stability-monitoring`: Monitors the health of the background audio isolate and automatically attempts recovery from hangs or silence.

### Modified Capabilities
- `spotify-library-view`: Refine the visual design and layout of the library screen for a more professional aesthetic.
- `flutter-audio-service`: Enhance the robustness of the background service to prevent unexpected stops.

## Impact

- **Frontend (Flutter)**: `lib/screens/main_screen.dart` (LibraryView), `lib/services/audio_handler.dart`.
- **User Experience**: Smoother browsing and reliable playback without needing to "clear from recents".
