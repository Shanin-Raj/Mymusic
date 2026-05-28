## 1. Layout Refinement

- [x] 1.1 Refactor `MainScreen` layout to ensure `SafeArea` is applied correctly and the content area uses `Expanded` or `Flexible` for dynamic scaling.
- [x] 1.2 Verify that the `MiniPlayer` and `BottomNavigationBar` are correctly positioned and don't overlap with system safe areas.
- [x] 1.3 Ensure the top app bars in all views (`HomeView`, `SearchView`, `LibraryView`, etc.) correctly account for status bar height.

## 2. Playlist Reactivity Fix

- [x] 2.1 Investigate why `_refreshPlaylist` in `PlaylistDetailScreen` might not be showing newly added songs immediately.
- [x] 2.2 Implement a more robust state management pattern (e.g., using a Provider notifier) for playlists so that additions are reflected across the app.
- [x] 2.3 Optimistically update the UI when a song is added to a playlist to provide instant feedback.

## 3. Verification

- [x] 3.1 Test the layout on multiple device configurations (different aspect ratios and notch types).
- [x] 3.2 Verify that adding a song to a playlist results in an immediate UI update in the `PlaylistDetailScreen`.
- [x] 3.3 Ensure system bars (top and bottom) are correctly themed and positioned.
