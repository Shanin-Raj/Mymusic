## Why

During local Windows development of the SonicVault Spotify-clone application, attempting to add songs through the API crashed with `exit code 1` due to the backend code hardcoding `python3`, which does not exist by default on Windows. Additionally, the bottom mini player progress bar was frozen because it was bound to `AudioService.position`, which is idle when notifications are deactivated. The equalizer visualizer animation expanded from the center, causing flickering/vertical jitter, and failed to scale dynamically, overlapping with the artwork in an unappealing way. 

To solve these visual and operational issues, we need a platform-aware backend python command resolver, real-time position stream routing, a bottom-anchored hardware-style visualizer, and a beautifully modular, completely self-contained UI-based universal adder flow to safely integrate link-based and manual song sync without affecting existing features.

## What Changes

- **OS-Aware Python Sync**: Refactored the backend execution blocks in `downloader.js` and `adder.js` to dynamically detect the platform (`win32` vs `linux`) and call `python` on local Windows hosts while maintaining `python3` for Linux Cloud Run deploys.
- **Real-Time MiniPlayer Progress**: Connected the progress stream in `PlayerProvider` to `_audioHandler.appPositionStream` so that the mini player linear progress bar and full screen seeker track playback progress perfectly in real-time.
- **Physical Equalizer Mechanics**: Reconfigured the `Row` vertical alignment in the `NowPlayingAnimation` to `CrossAxisAlignment.end` so that animation bars are anchored at the bottom and animate cleanly upwards. Scaled bar heights dynamically to match the parent size constraint.
- **Modular Library Adder Menu**: Extended the home Library tab (`_selectedFilter == null`) to display a `+` AppBar icon, opening a modern option sheet with options for Playlist, Artist, Album, and Sync Song.
- **Decoupled Universal Adder Dialog**: Formulated the entire Adder Form overlay as a completely separate standalone stateful widget `UniversalAdderDialog` in `main_screen.dart` with elegant links inputs, manual overrides, and progress-tracking loaders.

## Capabilities

### New Capabilities
- `universal-library-adder`: Enables users to sync Spotify/YouTube tracks or type manual metadata directly into their private Telegram/Firestore cloud vault via a modular, isolated adder form dialog in the UI.

### Modified Capabilities
- `spotify-library-view`: Adds support for the `+` primary action button on the library home tab and modular bottom navigation sheets.
- `spotify-mini-player`: Redefines progress tracking to use active internal playback positions rather than idle system-notification streams.
- `spotify-now-playing`: Integrates bottom-anchored hardware-style EQ bars with custom scaling and high-contrast color styling.

## Impact

- **d/music/backend/downloader.js**: Checks `process.platform` to select the correct python executable.
- **d/music/backend/adder.js**: Uses dynamic platform-aware command strings when running yt-dlp metadata extraction.
- **d/music/flutter_app/lib/providers/player_provider.dart**: Redirects `positionStream` to return `_audioHandler.appPositionStream`.
- **d/music/flutter_app/lib/widgets/now_playing_animation.dart**: Implements `CrossAxisAlignment.end` and `size * heightFactor` dynamic bar sizing.
- **d/music/flutter_app/lib/screens/main_screen.dart**: Integrates the library `+` button, option sheets, sub-flow overlays, and defines the isolated `UniversalAdderDialog` widget.
