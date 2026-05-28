## Why

1. The audio playback notification was not displaying on Android 13+ and Android 14 devices due to runtime permission blocks, foreground launch constraints, vector icon layout inflation issues, and old silent channel registrations.
2. In detail screens (Playlist, Artist, Album), there is **no bottom navigation bar**. However, the floating `MiniPlayer` was wrapped inside a `SafeArea` bottom widget, which created an unnecessary, thick black padding block underneath the player.
3. In `PlaylistDetailScreen`, the list bottom padding was set using `MediaQuery.of(context).padding.bottom + 100` (which created massive empty space), and the empty list illustration did not have enough bottom padding to clear the active `MiniPlayer`.

## What Changes

- Add the `permission_handler` package to request runtime permissions.
- Asynchronously request `Permission.notification` inside the `initState` of `_MainScreenState` in `main_screen.dart` when the user enters the app.
- Update `compileSdk` to `36` and `targetSdk` to `34` in `build.gradle.kts` to enable standard Android 14 background foreground service compatibility.
- Streamline `PlaybackState` broadcasts inside `audio_handler.dart` to listen to both `playerStateStream` and `playbackEventStream` simultaneously, mapping all state transitions instantly.
- Inject immediate synchronous `playing: true` updates in `play()` and `playing: false` in `pause()` to ensure foreground service promotion is handled *during the user click context window*, avoiding silent system blocks.
- Inject immediate metadata updates inside `skipToQueueItem` so that lockscreens and notifications display current track details without delay.
- Keep the highly compatible transparent, white-only stenciled vector icon `ic_notification.xml` under `drawable/` to ensure absolute compliance with status bar design regulations.
- Increment the `androidNotificationChannelId` to `'com.example.sonic_vault_flutter.dev.channel.audio_v3'` to force a fresh system registration with high-importance defaults.
- **Remove SafeArea wrappers** from around the `MiniPlayer` at the bottom of the column inside `AlbumDetailScreen` and `ArtistDetailScreen` to eliminate the thick, unnecessary black padding block at the bottom of the screen.
- Adjust `PlaylistDetailScreen` empty view bottom padding to a flat `90` and the "Add Songs" bottom padding to a flat `90` to clear the `MiniPlayer` without creating double spacing or giant empty spaces.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `background-audio-notification`: Standardize foreground service configurations, runtime permissions, and metadata synchronization to reliably display playback notifications on Android 13+ and 14+.
- `album-detail-view`: Polished layout and removed unnecessary bottom padding block under the mini player.
- `artist-detail-view`: Polished layout and removed unnecessary bottom padding block under the mini player.
- `playlist-detail-view`: Optimized bottom scroll padding to clear active mini players.

## Impact

- `pubspec.yaml` ([pubspec.yaml](file:///d:/music/flutter_app/pubspec.yaml))
- `build.gradle.kts` ([build.gradle.kts](file:///d:/music/flutter_app/android/app/build.gradle.kts))
- `main_screen.dart` ([main_screen.dart](file:///d:/music/flutter_app/lib/screens/main_screen.dart))
- `audio_handler.dart` ([audio_handler.dart](file:///d:/music/flutter_app/lib/services/audio_handler.dart))
- `main.dart` ([main.dart](file:///d:/music/flutter_app/lib/main.dart))
- `album_detail_screen.dart` ([album_detail_screen.dart](file:///d:/music/flutter_app/lib/screens/album_detail_screen.dart))
- `artist_detail_screen.dart` ([artist_detail_screen.dart](file:///d:/music/flutter_app/lib/screens/artist_detail_screen.dart))
- `ic_notification.xml` ([ic_notification.xml](file:///d:/music/flutter_app/android/app/src/main/res/drawable/ic_notification.xml))
