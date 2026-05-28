## Why

There are a few critical usability bugs remaining in the Flutter app that block a fully native feel:
1. **Background Playback & Notification**: Background playback stops when the app is minimized, and there is no persistent media notification showing the current song.
2. **Shuffle Mode**: Shuffle mode is completely unresponsive.
3. **NowPlaying UI Stuck**: The Now Playing screen gets stuck on a specific track and does not handle theme (dark mode) changes correctly.
4. **Layout and Safe Areas**: The UI ignores system navigation bars and status bars, causing elements to go under them and become unusable.
5. **Playlist State**: Playlists appear empty and lack reactive state management.
6. **Seek Bar Issues**: Non-Spotify or manually added songs (like "Safar") have duration/scroll bar issues in the Now Playing screen.

## What Changes

- **Audio Service Notification Configuration**: Update `SonicAudioHandler` and Android configuration to ensure the media notification is properly built and broadcast to the OS, keeping the app alive in the background.
- **Shuffle Implementation**: Fix the shuffle toggle to interact directly with the `just_audio` and `audio_service` queues.
- **Now Playing State & Theming**: Ensure `PlayerScreen` correctly listens to the `currentMediaItem` stream for UI updates and correctly applies the global theme context.
- **Safe Area Implementation**: Wrap main layout scaffolds in `SafeArea` to prevent content from bleeding under system bars.
- **Reactive Playlists**: Implement a listener for playlist data so the UI updates when tracks are fetched or modified.
- **Duration Parsing Fix**: Ensure the audio service correctly extracts and streams the duration for manually added songs where metadata might be slightly different.

## Capabilities

### Modified Capabilities
- `flutter-audio-service`: Add background notification and foreground service requirements.
- `contextual-playback-logic`: Define proper shuffle behavior.
- `spotify-ui-redesign`: Fix the PlayerScreen state update and dark mode aesthetics.

## Impact

- Users can lock their phones or minimize the app without music stopping.
- Users can control playback from their lock screen or notification shade.
- Shuffle behaves as expected.
- The UI stays synchronized with the actual playing track and respects system theme settings.
