## Why

1. **Overlay & SafeArea Incompatibilities**: The custom bottom mini player was clipping or overlapping with device system gesture bars and list elements on certain views (like Playlist, Album, and Artist detail screens).
2. **Persistent Empty Padding**: When the mini player was inactive (no song playing), screens maintained a hardcoded bottom padding (e.g., 80px), creating ugly blank voids at the bottom of the Home, Search, and Library lists.
3. **Now Playing Occursions**: The bottom-row controls (sleep timer and queue buttons) in the full-screen player were too close to the screen edge and cut off on some devices.
4. **Non-Functional UI Features**: The Home screen settings gear icon did not open the settings screen. There was no capability to add a cover art image when creating a playlist.
5. **Branding Inconsistencies**: The app was compiled with default Flutter launcher icons, and the root folder was cluttered with multiple duplicate logo images and obsolete legacy code.

## What Changes

- **Mini Player Layout Safety**: Wrapped the global mini player and detail-screen bottom navigation bars in `SafeArea` to respect system bar insets.
- **Dynamic List Padding**: Modified `HomeScreen`, `LibraryScreen`, and `SearchScreen` bottom padding to dynamically collapse when the player is not active.
- **Full-Screen Playback Polish**: Added extra bottom spacing (`SizedBox(height: 24)`) below the sleep timer and queue controls.
- **Settings Screen Integration**: Fully connected the settings button to navigate to `SettingsScreen`.
- **Playlist Image Selection**: Added a horizontal image gallery selector to `_showCreatePlaylistDialog` utilizing `ApiService.fetchAvailableImages()`.
- **Rebranding & App Logo**: Configured `flutter_launcher_icons` using `assets/mixtapelogo.jpeg` to generate Android and iOS launcher icons, and compiled a release APK.
- **Cleanup**: Purged redundant and legacy structures from the root directory (`flutter_app_legacy/`, `Flutterlegacy_image/`, old shell scripts, obsolete images).
