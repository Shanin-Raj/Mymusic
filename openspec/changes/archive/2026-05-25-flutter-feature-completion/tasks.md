## 1. Global State Management & Audio Setup

- [x] 1.1 Add `provider` dependency to `pubspec.yaml` and run `flutter pub get`.
- [x] 1.2 Create `PlayerProvider` class to manage current track, playback status, position, and volume.
- [x] 1.3 Initialize `SonicAudioHandler` in `main.dart` and wrap the app in a `MultiProvider`.
- [x] 1.4 Update `ApiService` to include a method for adding new music (`/api/add-song`).

## 2. Audio Playback Integration

- [x] 2.1 Connect the `playSong` method in `PlayerProvider` to the `SonicAudioHandler`.
- [x] 2.2 Wire up the Mini Player's Play/Pause button and tap gesture to open the Player.
- [x] 2.3 Implement the Seek Bar in the Player using the `StreamBuilder` from `audio_service`.
- [x] 2.4 Functionalize the Next, Previous, Shuffle, and Repeat buttons in the Player UI.

## 3. Screen Implementation: Library & Search

- [x] 3.1 Refactor `LibraryView` to fetch and display actual track data from `ApiService`.
- [x] 3.2 Implement the "Playlists" sub-view in Library and the navigation to playlist details.
- [x] 3.3 Functionalize the `SearchView` with real-time filtering logic and "tap to play" from results.
- [x] 3.4 Implement the Swipe-to-Delete functionality on tracks in the Library view.

## 4. Settings & Utility Features

- [x] 4.1 Create the `SettingsScreen` UI and add it to the navigation stack.
- [x] 4.2 Implement the Dark Mode toggle using a `ThemeProvider` and persist the value.
- [x] 4.3 Add the Sleep Timer picker and the background timer logic in `PlayerProvider`.
- [x] 4.4 Functionalize the "Queue" button in the Player to show a list of upcoming tracks.

## 5. Music Addition & Finalization

- [x] 5.1 Implement the "Add Music" UI (Sync from URL/Search) and connect it to `ApiService`.
- [x] 5.2 Functionalize the "Like" button (Heart icon) with persistence via `StorageService`.
- [x] 5.3 Conduct a full pass of the app to ensure all "static" buttons now have functional logic.
