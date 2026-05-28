## 1. Audio Engine and State Management Fixes

- [x] 1.1 In `flutter_app/lib/services/audio_handler.dart`, add a listener to `_player.currentIndexStream` to update the `mediaItem` sink with the current track metadata.
- [x] 1.2 Refactor `updateQueue` in the `AudioHandler` to ensure that setting a new queue always refreshes the player's audio source.
- [x] 1.3 In `flutter_app/lib/providers/player_provider.dart`, update the `playSong` method to accept a list of songs and an initial index, clearing the old queue and rebuilding the new one contextual to the UI.
- [x] 1.4 Implement a robust position stream in `PlayerProvider` that listens to both `audio_service` position updates and a periodic timer to ensure smooth UI progress bars.

## 2. Persistent Now Playing UI

- [x] 2.1 Update `flutter_app/lib/screens/main_screen.dart` to ensure the `MiniPlayer` is visible whenever `PlayerProvider.currentSong` is not null.
- [x] 2.2 Replicate the web app's MiniPlayer styling: slim bar, album art on left, title/artist in center, and play/pause button on right.
- [x] 2.3 Implement the "Progress Line" (thin 2px line) on top of the MiniPlayer that reflects current playback position.

## 3. Full-Screen Player Implementation

- [x] 3.1 Build the `FullScreenPlayer` screen using a `showModalBottomSheet` transition from the MiniPlayer.
- [x] 3.2 Replicate the large square album art, song title, and artist layout from the web app.
- [x] 3.3 Functionalize the `Slider` widget for seeking, ensuring it syncs with the `PlayerProvider` position.
- [x] 3.4 Wire up the Like (Heart), Shuffle, Repeat, Queue, and Sleep Timer buttons to their respective methods in `PlayerProvider`.

## 4. Home Screen Completion

- [x] 4.1 Update `HomeView` to include horizontal carousels for "Mixes" (e.g., Happy Mix, Chill Mix) fetching from the backend.
- [x] 4.2 Replicate the "Recently Synced" grid exactly as it appears in the web app.
- [x] 4.3 Ensure tapping any song card in Home starts contextual playback of that entire carousel.

## 5. Search and Library Functionality

- [x] 5.1 Refactor `SearchView` to include a persistent search bar and real-time filtering logic that updates the track list as the user types.
- [x] 5.2 In `LibraryView`, implement the "Playlists" section with the ability to create a new playlist via a modal dialog.
- [x] 5.3 Implement the "Add to Playlist" context menu item for songs in the Library list.
- [x] 5.4 Fix the "Library Shuffle" button to populate the queue with all library songs in random order and start playback.

## 6. Add Music Integration

- [x] 6.1 Ensure the "Add Music" FAB in the Library view correctly opens the `AddMusicScreen`.
- [x] 6.2 Connect the "Sync" button in `AddMusicScreen` to the `ApiService.addSong` method and show a success snackbar.
