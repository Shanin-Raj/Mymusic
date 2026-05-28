## 1. Eliminate Global Position Rebuilds

- [x] 1.1 Remove `notifyListeners()` from the position stream listener in `PlayerProvider` (_init method).

## 2. Verification

- [x] 2.1 Verify that localized `StreamBuilder` widgets in `MiniPlayer` and `FullScreenPlayer` still progress smoothly in real-time.
- [x] 2.2 Verify that parent views and images remain completely static and flicker-free during playback.
- [x] 2.3 Run `flutter analyze` and build production release APK to compile the changes.
