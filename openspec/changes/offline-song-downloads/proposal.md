## Why

Users cannot listen to songs when offline or when network connectivity is poor. Adding the ability to download songs for offline playback provides a core music app expectation (like Spotify, Apple Music) and improves user experience in low-connectivity environments.

## What Changes

- Add a persistent song download system where users can choose individual songs to save for offline playback
- Add network connectivity auto-detection to switch between online/offline modes
- Add a downloads management screen showing downloaded songs and storage usage
- Add download progress indicators on song tiles and the now-playing screen
- Add Hive for persistent local storage of download metadata
- Existing audio caching, streaming, and playback systems remain untouched
- No breaking changes to existing features

## Capabilities

### New Capabilities
- `song-downloads`: Core download functionality - download/remove songs, progress tracking, persistent storage of audio files and metadata using Hive, playback integration to prefer local files over streaming
- `offline-mode`: Auto-detect network status via connectivity_plus, automatically filter content to show only downloaded songs when offline, offline indicator in UI
- `downloads-management`: Dedicated screen to view all downloaded songs, per-song delete, clear all downloads, storage usage display

### Modified Capabilities

None. No existing specs require changes.

## Impact

- **New dependencies**: `hive`, `hive_flutter`, `connectivity_plus`
- **New service**: `OfflineService` (Hive-based metadata + file storage)
- **New service**: `ConnectivityService` (network status detection)
- **New provider**: `DownloadProvider` (download state + progress management)
- **New files**: `download_button.dart` widget, `downloads_screen.dart`, `download_tile.dart`
- **Modified files**: `main.dart`, `audio_cache_service.dart`, `audio_handler.dart`, `song_tile.dart`, `now_playing_screen.dart`, `settings_screen.dart`, `home_screen.dart`, `search_screen.dart`, `library_screen.dart`, `playlist_detail_screen.dart`
