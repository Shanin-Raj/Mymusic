## 1. Backend Cover Images Sync

- [x] 1.1 Copy all local images from `d:\music\images\` to `d:\music\backend\images\` for packaging.
- [x] 1.2 Modify `backend/server.js` dynamic images directory fallback search logic.

## 2. Now Playing Equalizer Layout Isolation

- [x] 2.1 Refactor `NowPlayingAnimation` in `now_playing_animation.dart` to use static `SizedBox` and `Align` layout boundaries.

## 3. Player UI and Progress Protection

- [x] 3.1 Refactor `MiniPlayer`'s progress bar in `main_screen.dart` to check `duration.inMilliseconds > 0` and prevent division-by-zero.
- [x] 3.2 Implement `_getPlaylistGradient` seeded HSL linear gradient background in `main_screen.dart`.
- [x] 3.3 Add refresh icon button and force-invalidation SnackBar trigger to `LibraryView`'s app bar in `main_screen.dart`.

## 4. Verification & Packaging

- [x] 4.1 Run `flutter analyze` to ensure code compiles cleanly with zero compilation warnings.
- [x] 4.2 Compile and package release APK using `flutter build apk --release`.
