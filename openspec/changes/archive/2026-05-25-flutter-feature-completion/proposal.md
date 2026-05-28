## Why

The current Flutter application is a static UI skeleton without functional logic. Users can see track metadata, but cannot play music, manage playlists, search for songs, or adjust settings. This change is needed to bridge the gap between the static prototype and a fully functional music player, ensuring it perfectly replicates the features of the original web application.

## What Changes

- **Audio Playback Engine**: Implementation of the `just_audio` and `audio_service` logic to actually play music from the backend.
- **Interactive Player Controls**: Adding functionality to the Like, Shuffle, Repeat, and Queue buttons.
- **Playlist Management**: Implementing the Playlist view, including the ability to see tracks within a playlist and add songs to them.
- **Search System**: Implementing a functional search page to find songs in the library.
- **Settings Page**: Adding a dedicated settings screen with a Dark Mode toggle and Sleep Timer.
- **Music Addition**: Implementing the "Add" button and its interface to sync new music from YouTube or Spotify links.
- **Queue Management**: Adding a functional queue system to manage upcoming tracks.

## Capabilities

### New Capabilities
- `flutter-audio-player`: Core audio playback logic, including background service integration and transport controls.
- `flutter-playlist-management`: Interface and logic for viewing, creating, and managing playlists.
- `flutter-search`: Real-time search functionality across the music library.
- `flutter-settings`: Settings screen featuring appearance controls (Dark Mode) and utility features like Sleep Timer.
- `flutter-add-music`: UI and logic for adding new tracks to the vault via URLs.
- `flutter-queue-system`: Logic for managing the current playback queue and the "Up Next" list.

### Modified Capabilities
- `flutter-native-app`: Transitioning the app from a static skeleton to a state-managed, functional application.
- `spotify-now-playing`: Updating the player UI to include interactive elements (Like, Queue, Sleep Timer buttons).

## Impact

- **UI/UX**: Transition from static screens to a responsive, functional app.
- **Logic**: Migration of complex state management (audio, playback, queue) to Flutter.
- **Persistence**: Usage of `shared_preferences` or local storage to save user favorites and settings.
