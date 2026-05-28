## 1. Shuffle Functionality

- [x] 1.1 In `d:\\music\\flutter_app\\lib\\providers\\player_provider.dart`, ensure `toggleShuffle` correctly calls the `AudioHandler` to set shuffle mode and update the queue.
- [x] 1.2 In `SonicAudioHandler`, implement shuffle logic (if not handled natively by `just_audio`'s shuffle mode) to shuffle the `effectiveQueue` and update the `AudioService` queue.

## 2. Playlist UI & State

- [x] 2.1 In `PlaylistDetailView` (or equivalent), add an \"Add Songs\" button below the track list. Clicking this should open the library view or a bottom sheet to select songs to add.
- [x] 2.2 Ensure that adding a song to a playlist (from either the library or the new button) triggers a state update in the relevant provider so the `PlaylistDetailView` re-renders immediately with the new song.

## 3. Remove Manual Add Feature

- [x] 3.1 Locate the manual add song UI component (likely a FloatingActionButton in `LibraryView` or `HomeView`).
- [x] 3.2 Remove the button and its associated logic/dialog from the Flutter codebase entirely.

## 4. Verification

- [x] 4.1 Run the app. Verify the manual add button is gone.
- [x] 4.2 Play a list of songs, toggle shuffle, and verify the next song is randomized.
- [x] 4.3 Open a playlist, add a song, and verify it appears immediately in the list without restarting the app.
