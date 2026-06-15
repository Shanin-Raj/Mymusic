## Context

- The Flutter app uses `just_audio` and `audio_service` to control music playback.
- Real-time communication is done by opening a connection to the SSE stream endpoint `/api/rooms/:roomId/stream` via standard `HttpClient` streams (pure Dart, zero dependencies).
- Positions must be aligned against the server time to compensate for local system clock offsets.
- Synchronizing player states programmatically triggers the player's listener events, which can cause feedback echo loops.

## Decisions

- **Pure Dart SSE Connection:** Use standard `dart:io` `HttpClient` to read and parse the SSE `text/event-stream` line-by-line, avoiding additional pub dependencies.
- **Persistent Storage:** Store the active `roomId` in `SharedPreferences` so that if the app is closed and reopened, it automatically attempts to re-sync to the room.
- **Audio Handler Hook Integration:** Use `MyAudioHandler`'s broadcast streams (`appMediaItemStream` for track changes, `appPlaybackStateStream` for play/pause, `appPositionStream` for seeks) to monitor local updates.
- **NTP-Style Handshake:** Align local clocks by estimating round-trip latency against `/api/time` to compensate playback positions:
  `elapsed = DateTime.now().millisecondsSinceEpoch - updatedAt`
  `targetPosition = position + (isPlaying ? elapsed : 0)`
- **Preventing Loops:** Implement `isSyncing = true` flag during sync adjustments. If the provider receives a local player change event while `isSyncing` is active, it ignores it.
