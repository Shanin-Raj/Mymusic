## 1. FullScreenPlayer Safe Area Fix

- [x] 1.1 In `lib/screens/main_screen.dart`, remove `extendBody: true` from the `FullScreenPlayer`'s `Scaffold`.
- [x] 1.2 Move the `SafeArea` wrapper from the `body` to wrap the entire `Container`/`Scaffold` so that the `AppBar` is also inset from the system status bar.
- [x] 1.3 Build and verify that the AppBar content is no longer overlapped by the status bar.

