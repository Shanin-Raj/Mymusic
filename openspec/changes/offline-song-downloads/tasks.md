## 1. Dependencies & Setup

- [x] 1.1 Add `hive`, `hive_flutter`, and `connectivity_plus` to pubspec.yaml
- [x] 1.2 Initialize Hive in main.dart before runApp
- [x] 1.3 Open Hive boxes (`offline_songs`, `download_state`) after initialization

## 2. Connectivity Service

- [x] 2.1 Create `services/connectivity_service.dart` — singleton listening to Connectivity().onConnectivityChanged
- [x] 2.2 Expose `Stream<bool> isOnline` and `bool currentStatus` getter
- [x] 2.3 Initialize ConnectivityService in main.dart and pass to AudioProvider

## 3. Offline Service (Hive + File Storage)

- [x] 3.1 Create `services/offline_service.dart` — Hive box for download metadata
- [x] 3.2 Implement `downloadSong(songId, metadata, onProgress)` — stream download with progress, write to temp file, rename on completion
- [x] 3.3 Implement `removeSong(songId)` — delete audio file and Hive metadata
- [x] 3.4 Implement `isDownloaded(songId)` — check Hive + file existence
- [x] 3.5 Implement `getAllDownloaded()` — return all songs from Hive box
- [x] 3.6 Implement `getDownloadedCount()` and `getStorageUsed()` helpers
- [x] 3.7 Implement `clearAll()`, cleanup stale metadata (file missing from disk)

## 4. Download Provider

- [x] 4.1 Create `providers/download_provider.dart` extending ChangeNotifier
- [x] 4.2 Track active downloads with progress (`Map<String, double>`)
- [x] 4.3 Expose `isDownloading(songId)`, `getProgress(songId)`, `isDownloaded(songId)`
- [x] 4.4 Implement `startDownload(Map<String, dynamic> song)` method
- [x] 4.5 Implement concurrent download queue (max 3 at a time)
- [x] 4.6 Implement `removeDownload(songId)` method
- [x] 4.7 Refresh state on app start from Hive boxes

## 5. Playback Integration

- [x] 5.1 Add `getOfflinePath(songId)` method to AudioCacheService (checks OfflineService)
- [x] 5.2 Update `MyAudioHandler._buildSources()` — check OfflineService first, then temp cache, then streaming
- [x] 5.3 Handle stale download scenario: file missing → fallback to stream + clean up metadata

## 6. Download Button Widget

- [x] 6.1 Create `widgets/download_button.dart` — small icon button with 3 states: not downloaded, downloading (progress indicator), downloaded
- [x] 6.2 Integrate with DownloadProvider for state and progress
- [x] 6.3 On tap: start download if not downloaded, show confirmation then remove if downloaded

## 7. UI: Add Download Buttons to Existing Screens

- [x] 7.1 Update `widgets/song_tile.dart` — add DownloadButton next to heart icon
- [x] 7.2 Update `features/player/now_playing_screen.dart` — add DownloadButton in bottom action row
- [x] 7.3 Update `features/library/playlist_detail_screen.dart` — add download option per song

## 8. Downloads Management Screen

- [x] 8.1 Create `features/downloads/downloads_screen.dart` — list of downloaded songs
- [x] 8.2 Show storage usage at top (formatted in KB/MB/GB)
- [x] 8.3 Implement per-song delete with confirmation dialog
- [x] 8.4 Implement "Clear All" with confirmation dialog showing storage to free
- [x] 8.5 Implement tappable song to play from local file
- [x] 8.6 Implement empty state with illustration and explore button

## 9. Settings Integration

- [x] 9.1 Update `features/player/settings_screen.dart` — add "Downloads" list tile with count
- [x] 9.2 Navigate to DownloadsScreen on tap

## 10. Offline Mode — Connectivity Integration

- [x] 10.1 Provide ConnectivityService to AudioProvider
- [x] 10.2 Add `isOnline` boolean and stream in AudioProvider
- [ ] 10.3 When offline: filter APIs to show only downloaded songs
- [ ] 10.4 Show offline indicator/banner on HomeScreen, SearchScreen, LibraryScreen
- [ ] 10.5 When offline: block playing non-downloaded songs with error message

## 11. Offline Filtering by Screen

- [ ] 11.1 Update `features/home/home_screen.dart` — show downloaded section when offline
- [ ] 11.2 Update `features/search/search_screen.dart` — filter to downloaded songs when offline
- [ ] 11.3 Update `features/library/library_screen.dart` — filter playlists/artists/albums when offline

## 12. Playlist Download (Bonus)

- [ ] 12.1 Add "Download All" button in playlist detail header
- [ ] 12.2 Implement sequential download of all playlist songs with overall progress
