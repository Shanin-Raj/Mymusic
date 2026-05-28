## Why

The Flutter application currently has several UI and playback-related issues that degrade the user experience. The layout doesn't perfectly fit all aspect ratios (missing system bar handling), the 'Now Playing' screen has functional and visual regressions (seek bar not working, dark mode not applied), and background playback is inconsistent with missing notifications and no automatic track progression.

## What Changes

- **Layout Refinement**: Adjust the app layout to portrait primary with proper handling of top (status bar) and bottom (navigation bar) spaces.
- **Now Playing Fixes**:
    - Fix the scroll/seek bar functionality.
    - Apply dark mode/theme consistency to the Now Playing screen.
- **Playback Improvements**:
    - Implement/Fix background playback notifications.
    - Enable automatic progression to the next track when the current song ends.

## Capabilities

### New Capabilities
- `playback-lifecycle-management`: Handles automatic track progression and consistent playback state transitions.

### Modified Capabilities
- `spotify-now-playing`: Fixing the seek bar functionality and ensuring dark mode/theming is correctly applied.
- `background-audio-continuity`: Ensuring background play shows correctly as a notification and survives app backgrounding.
- `flutter-native-app`: Refining the layout aspect ratio and system bar integrations.

## Impact

- **Frontend (Flutter)**: `lib/` screens (Now Playing, Main Layout), theme configuration, and audio service integration.
- **Android Integration**: `android/` manifest and service configurations for background audio.
- **Dependencies**: `audio_service`, `just_audio` (or relevant playback packages).
