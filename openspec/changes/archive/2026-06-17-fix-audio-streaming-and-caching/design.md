## Context

The app streams audio from a Telegram-hosted storage via a Node.js (Express 5) backend on Render. The Flutter client uses `just_audio` + `audio_service` for playback. When a song ends and the next begins, the backend had to download the **entire** file from Telegram into memory before sending any bytes to the client, causing a multi-second gap with zero data — perceived as stuttering.

The Flutter side had no local audio caching — every play was a fresh stream from the server.

## Goals / Non-Goals

**Goals:**
- Eliminate stuttering on song transitions by ensuring the next song's audio data reaches the client immediately
- Pre-download the next song to local device storage while current song plays
- Auto-cleanup cached audio files: after 15 minutes of inactivity, or when app is removed from recents
- Backward compatibility — no breaking API changes

**Non-Goals:**
- Offline playback (songs are still fetched from server on first play)
- Custom audio format transcoding
- Managing the Telegram download queue ordering beyond priority

## Decisions

1. **Tee stream (backend)**: Instead of `downloadMedia()` returning a full `Buffer`, pass a custom `Writable` that writes each chunk to both the cache file (via `fs.createWriteStream`) and the HTTP response (`res.write`). This lets the client start buffering as soon as the first bytes arrive from Telegram.

2. **Download queue (backend)**: Serialize Telegram downloads via a FIFO queue with priorities (1 = stream, 2 = precache). Prevents hammering Telegram's API with concurrent downloads and avoids file corruption from simultaneous writes to the same cache file.

3. **WriteStream over Buffer (backend)**: Use `downloadMedia(media, fileStream)` instead of `downloadMedia(media, {})` + `writeFileSync`. Eliminates the in-memory Buffer for large audio files and avoids blocking the event loop.

4. **Local pre-download (Flutter)**: When a song starts playing (`currentIndexStream`), immediately download the next song's audio to `{appDocDir}/audio_cache/{songId}` via `AudioCacheService`. Once downloaded, replace the streaming `AudioSource` with `AudioSource.file()`.

5. **Inactivity timer (Flutter)**: `AudioCacheService.touch()` is called on every playback action (play, pause, skip, seek, song change). If 15 minutes pass without a touch, the cache is cleared. This prevents unbounded storage growth.

6. **Lifecycle cleanup (Flutter)**: `MixtapeApp` (now `StatefulWidget`) observes `AppLifecycleState.detached` to clear cache when the app is swiped away.

## Risks / Trade-offs

- **First-play latency**: On first play of a song (cache miss), the client still waits for the Telegram download. Mitigation: the queue serializes downloads and the tee stream starts sending data as soon as chunks arrive, so partial playback begins much sooner than before.
- **Storage usage**: Cached songs accumulate during a session (up to ~50MB for a typical playlist). Mitigation: 15-minute inactivity auto-cleanup + lifecycle cleanup on app removal from recents.
- **`outputFile` API compatibility**: Telegram library's `downloadMedia` accepts different `outputFile` types. Using a `Writable` stream directly works because `getWriter(obj)` returns the object itself when it's not null/Buffer/string.
