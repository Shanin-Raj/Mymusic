## Why

The current Flutter application fails to render UI edge-to-edge behind the Android status bar and system navigation bar, causing overlays or clipping issues. Additionally, the application lacks visual feedback for playback (the "now playing" EQ animation) compared to the web application equivalent. Fixing these issues will improve the overall aesthetic and user experience, aligning the mobile app with modern edge-to-edge design standards.

## What Changes

- Update the application's root structure to enable Android edge-to-edge mode.
- Remove restrictive `SafeArea` wrappers that prevent drawing behind the system UI, opting instead for localized padding or `extendBody`/`extendBodyBehindAppBar` properties.
- Introduce a new animated EQ visualizer widget (`NowPlayingAnimation`) that activates conditionally when a track is playing.
- Integrate the animation widget into the list items (e.g., `SongListSliver`, `PlaylistDetailScreen`, `HomeView` mix carousel) and player views to provide clear visual playback status.

## Capabilities

### New Capabilities
- `ui-edge-to-edge`: Enables the application UI to extend seamlessly behind Android system bars (status bar and navigation bar) for a modern, immersive aesthetic.
- `playback-visualizer`: Introduces a dynamic "now playing" EQ animation that activates when audio is playing, matching the web app experience.

### Modified Capabilities

## Impact

- **Flutter Configuration**: `main.dart` or native Android files (`MainActivity.kt`, `AndroidManifest.xml`) to enforce edge-to-edge layout.
- **UI Screens**: Modifications in `MainScreen`, `FullScreenPlayer`, `SongListSliver`, `PlaylistDetailScreen`, and `HomeView` to use `extendBody: true` and appropriate `SafeArea` constraints.
- **Components**: Creation of `NowPlayingAnimation` widget and updates to existing item widgets to display it based on `PlayerProvider` state.
