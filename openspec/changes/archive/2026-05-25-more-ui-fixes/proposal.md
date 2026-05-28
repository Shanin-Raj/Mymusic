## Why

The user has identified three additional UI and functionality issues that need resolving:
1. **Shuffle not working**: The shuffle feature is either unresponsive or not randomizing the queue correctly.
2. **Playlist Management Friction**: There is no button inside a playlist to add songs to it, and when songs are added from the library, they don't appear in the playlist immediately (likely a state/refresh issue).
3. **Manual Add Feature Removal**: The manual "add new song" feature in the app UI is no longer needed since backend scripts handle adding songs.

## What Changes

- **Playback Logic**: Fix the shuffle toggle in the player to correctly randomize the `audio_service` queue.
- **Playlist UI**: Add an "Add Songs" button within the playlist detail view. Fix state management so the playlist view updates instantly when a new song is added to it.
- **UI Cleanup**: Remove the manual song addition form/button from the library or home screen.

## Capabilities

### Modified Capabilities
- `flutter-playlist-management`: Adding "Add Songs" button to the playlist view and fixing state reactivity.
- `contextual-playback-logic`: Fixing shuffle functionality.
- `spotify-ui-redesign`: Removing the manual song add UI element.

## Impact

- Users can shuffle songs correctly.
- Users can easily add songs to playlists from within the playlist itself.
- Playlists will accurately reflect newly added songs without requiring an app restart.
- A cleaner UI by removing the unused manual add feature.
