## 1. Background Notification Fix

- [x] 1.1 In `d:\music\flutter_app\lib\main.dart`, ensure `AudioServiceConfig` sets `androidNotificationIcon: 'mipmap/ic_launcher'`.
- [x] 1.2 In `SonicAudioHandler`, ensure `MediaItem` is correctly yielded to the `audio_service` whenever the track changes.
- [x] 1.3 Check `AndroidManifest.xml` for `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_MEDIA_PLAYBACK` permissions.

## 2. Shuffle Functionality

- [x] 2.1 In `SonicAudioHandler` (or `PlayerProvider`), implement the shuffle toggle to call `_player.setShuffleModeEnabled(true)` and shuffle the sequence.

## 3. Player Screen Reactive State & Theming

- [x] 3.1 Open `PlayerScreen` (`d:\music\flutter_app\lib\screens\player_screen.dart`).
- [x] 3.2 Wrap the song details (title, artist, image) in a `StreamBuilder<MediaItem?>` listening to the `audioHandler.mediaItem` stream so it updates automatically.
- [x] 3.3 Audit `PlayerScreen` for hardcoded colors and replace them with `Theme.of(context)` references to support Dark Mode properly.

## 4. UI Layout & Safe Areas

- [x] 4.1 In `MainScreen` and other top-level scaffolds, ensure the body is wrapped in a `SafeArea` widget so the UI doesn't bleed under the notch, status bar, or bottom navigation gesture area.
- [x] 4.2 Fix the `PlaylistDetailView` so that the track list uses `StreamBuilder` or `Consumer` to reactively update when the playlist data changes (so it's not empty).

## 5. Duration Parsing Fix

- [x] 5.1 In `SonicAudioHandler` (where JSON from API is mapped to `MediaItem`), ensure the track `duration` is safely parsed, applying a default value or fetching it dynamically if `duration_ms` is null or invalid for manually added tracks.

## 4. Verification

- [x] 4.1 Play a song and minimize the app; verify music continues and the notification appears.
- [x] 4.2 Verify shuffle randomizes the queue.
- [x] 4.3 Verify the Player Screen updates when a new song starts and switches correctly between light/dark themes.
