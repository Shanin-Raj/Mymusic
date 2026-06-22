## Context

The Mixtape Flutter app currently streams songs from a remote API. It has an existing `AudioCacheService` for temporary pre-caching (auto-cleared after 15-min inactivity), but no persistent offline playback. Songs are represented as `Map<String, dynamic>` fetched from the API. State management uses Provider/ChangeNotifier.

## Goals / Non-Goals

**Goals:**
- Allow users to download individual songs for persistent offline playback
- Auto-detect network status and switch to offline mode
- Show download progress with visual indicators
- Provide a downloads management screen
- Integrate with existing playback — prefer local files over streaming
- Zero breaking changes to existing features

**Non-Goals:**
- Bundle songs inside the APK (device storage only)
- Automatic download of entire library
- Streaming-quality selection per download
- P2P or multi-device sync of downloads

## Decisions

**1. Hive over sqflite / SharedPreferences**
- Hive is lightweight, NoSQL, Dart-native, and fast for simple key-value/document storage
- No native platform dependencies (unlike sqflite)
- Perfect for storing song metadata objects without SQL schema overhead
- Alternatives considered: sqflite (heavier, overkill for this use case), SharedPreferences (limited to primitive types, no querying)

**2. Separate download directory from temp cache**
- User downloads go to `<appDir>/offline_downloads/` — never auto-cleared
- Temp cache stays at `<appDir>/audio_cache/` — keeps existing 15-min auto-cleanup
- Prevents accidental deletion of user-downloaded files

**3. DownloadProvider as the state manager**
- Follows existing Provider pattern used by AudioProvider and ThemeProvider
- Encapsulates all download state (progress, active downloads, downloaded set)
- Fits naturally into the existing ChangeNotifier + Provider architecture

**4. Stream-based progress via isolate-saved http download**
- Use `http.Client` with `StreamedResponse` to capture bytes and compute progress
- Progress emitted via `StreamController<double>` per download
- DownloadProvider listens and exposes state to widgets

**5. ConnectivityService as a singleton listening to connectiviy_plus stream**
- Exposes `Stream<bool> isOnline` and `bool currentStatus`
- AudioProvider subscribes to changes and updates behavior
- No polling needed — event-driven via platform connectivity changes

## Risks / Trade-offs

- **Storage growth**: Downloads accumulate device storage → Mitigation: Display storage usage in DownloadsScreen, allow easy per-song and bulk deletion
- **Download failures mid-transfer**: File may be partially saved → Mitigation: Write to temp file first, rename on completion; on failure, delete temp file
- **Offline metadata staleness**: Song metadata (name, artist) could change on server after download → Acceptable trade-off: snapshot metadata at download time, no auto-update
- **Concurrent downloads**: Multiple simultaneous downloads could saturate network → Mitigation: Queue downloads sequentially (max 3 concurrent)
