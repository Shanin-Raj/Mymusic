## 1. Native Edge-to-Edge Setup

- [x] 1.1 Enable edge-to-edge mode in `main.dart` using `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)`.
- [x] 1.2 Validate Android `MainActivity.kt` or `styles.xml` configuration to ensure no native overlays prevent edge-to-edge rendering.

## 2. UI Constraints & Padding

- [x] 2.1 Update `AnnotatedRegion<SystemUiOverlayStyle>` in `MainScreen` to set `statusBarColor` and `systemNavigationBarColor` to `Colors.transparent`.
- [x] 2.2 Add `extendBody: true` to the main `Scaffold` configurations in `MainScreen`, `FullScreenPlayer`, `QueueScreen`, and `SettingsScreen`.
- [x] 2.3 Remove top-level `SafeArea` wrappers that restrict full-screen drawing in `MainScreen` and `FullScreenPlayer`.
- [x] 2.4 Apply localized padding (e.g., top padding for AppBar, bottom padding for lists) to prevent scrollable content from being hidden behind the system navigation bar or `BottomNavigationBar`.

## 3. Now Playing Visualizer

- [x] 3.1 Create `NowPlayingAnimation` widget using lightweight standard Flutter animation components (e.g., `AnimatedContainer` or `AnimationController`).
- [x] 3.2 Update `SongListSliver` to display the `NowPlayingAnimation` overlaid on or next to the song image when the `PlayerProvider` indicates the song is actively playing.
- [x] 3.3 Apply the `NowPlayingAnimation` logic to `PlaylistDetailScreen` list items.
- [x] 3.4 Apply the `NowPlayingAnimation` logic to `HomeView` mix carousel items.
