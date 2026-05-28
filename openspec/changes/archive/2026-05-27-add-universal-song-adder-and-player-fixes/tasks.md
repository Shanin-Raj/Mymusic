## 1. Backend OS-Aware Fixes

- [x] 1.1 Add platform-aware python execution inside `downloader.js`.
- [x] 1.2 Add platform-aware python command detection inside `adder.js`.

## 2. Player Stream & Physics Overhaul

- [x] 2.1 Map `PlayerProvider.positionStream` to active `_audioHandler.appPositionStream` directly.
- [x] 2.2 Reconfigure `NowPlayingAnimation`'s `Row` alignment to `CrossAxisAlignment.end` to anchor bars to bottom.
- [x] 2.3 Pass parent `widget.size` dynamically to visualizer bars and scale bar height constraint (`size * heightFactor`).
- [x] 2.4 Stylize `NowPlayingAnimation` with high-contrast white in `FullScreenPlayer`.

## 3. Modular Library Adder Flow

- [x] 3.1 Place a `+` icon on default "Your Library" home tab SliverAppBar.
- [x] 3.2 Implement options bottom navigation sheet offering Add Song, Playlist, Artist, and Album sub-flows.
- [x] 3.3 Create isolated standalone stateful widget `UniversalAdderDialog` with step-by-step progress tracking loaders.
- [x] 3.4 Establish scrollable options sheets for existing Playlist (including "+ Create New Playlist"), Artist, and Album detail navigators.

## 4. Verification & Releases

- [x] 4.1 Run static analysis check `flutter analyze` ensuring zero compiler errors or warnings.
- [x] 4.2 Rebuild production Android APK (`flutter build apk --release`) ensuring perfect compiler health.
