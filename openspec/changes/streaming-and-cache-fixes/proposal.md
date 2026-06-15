## Why

1. **Streaming Bottleneck & Concurrency Conflicts:** Android's media player (ExoPlayer) issues multiple HTTP range requests simultaneously when initiating playback. Without concurrency control, every request triggered a parallel download of the same song from Telegram, resulting in bandwidth clogging, timeouts (25-second delay), and corrupted audio files (causing song mismatches).
2. **Slow / Stale Cache Refreshes:** The 30-second TTL-based cache required fetching the entire library from Firestore whenever a request was made after the TTL expired. This caused substantial request latency spikes and database read overhead, while still being delayed by up to 30 seconds for CLI additions.

## What Changes

- **Active Downloads Map (`backend/server.js`):**
  - Added `activeDownloads` Map to track ongoing downloads by song ID.
  - Added `downloadSongFromTelegram` helper that returns the existing promise if a download is already in progress, avoiding duplicate downloads.
  - Writes the downloaded buffer to a temporary file (`.tmp`) first, then atomically renames it (`fs.renameSync`) to the final destination (`.m4a`). This prevents reading threads from streaming a partially-written/corrupt file.
  - Updated `/api/stream/:id` and `/api/precache/:id` to call `downloadSongFromTelegram`.
- **Real-Time Cache Sync (`backend/server.js`):**
  - Replaced the 30-second cache TTL logic with Firestore `onSnapshot` listeners for `songs` and `playlists` collections.
  - Updated `songsCache` and `playlistsCache` dynamically in the background in response to database changes, resulting in instant client sync and 0ms database lookup latency for GET endpoints.
  - Removed manual `Cache = null` cache-clearing code across API routes.

## Capabilities

### Modified Capabilities
- `database-layer`: Configured real-time collection synchronization on startup.
- `caching-layer`: Upgraded memory caching from TTL-polling to real-time pushes.
- `streaming-layer`: Introduced atomic write renaming and active download locks to handle parallel range requests.
