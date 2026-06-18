## Why

Songs stutter when transitioning between tracks because the backend downloads the entire audio file from Telegram into memory before sending any bytes to the client, and the Flutter app has no local audio caching. This causes a multi-second gap where the player receives zero data.

## What Changes

- **Backend**: Rewrite `/api/stream/:id` to use a tee stream — write each chunk from Telegram to both the cache file and the HTTP response simultaneously, so the client can start buffering immediately
- **Backend**: Fix `/api/precache/:id` to use a WriteStream instead of buffering the full file in memory
- **Backend**: Add dynamic MIME type detection for audio files based on extension
- **Flutter**: Create `AudioCacheService` that pre-downloads the next song to local device storage as soon as the current song starts playing
- **Flutter**: Modify `AudioHandler` to replace streaming audio sources with local file paths once cached
- **Flutter**: Add 15-minute inactivity timer that auto-clears the audio cache when no playback activity is detected
- **Flutter**: Add `WidgetsBindingObserver` lifecycle handler — clear cache when app is removed from recents
- **Flutter**: Fix syntax errors (`showSnackBar` missing parenthesis, `debugPrint` import), const constructor lint warning, and `BuildContext` async gap warnings

## Capabilities

### New Capabilities
- `audio-progressive-streaming`: Stream audio from Telegram to client progressively — first byte arrives immediately instead of waiting for full download
- `local-audio-cache`: Pre-download next song to local storage, use local file for playback, auto-cleanup on inactivity (15min) or app remove-from-recents

### Modified Capabilities
- (none)

## Impact

- **Backend**: `backend/server.js` — stream endpoint, precache endpoint, streamFile helper, MIME type map, download queue integration
- **Flutter**: `lib/services/audio_cache_service.dart` (new), `lib/audio_handler.dart`, `lib/main.dart`
- **Dependencies**: No new dependencies — uses existing `path_provider`, `http`, `dart:io`
- **Deployment**: Backend pushed to Render (Docker), Flutter APK built
