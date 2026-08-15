# Synced Lyrics Feature (Phase 2)

## Why

Listening to music is an emotional and engaging experience. Real-time time-synchronized lyrics (like Apple Music and Spotify) are one of the most requested features in modern music apps. Users want to:
1. Sing along with live-scrolling lyrics synchronized line-by-line with the music.
2. Tap on any lyric line to jump/seek playback to that exact point in the song.
3. Access lyrics even when listening to downloaded songs offline.

## What Changes

- **Backend**:
  - Add `lyrics.js` service to query the free, open-source LRCLIB API with smart title/artist sanitization and duration matching.
  - Add `GET /api/songs/:id/lyrics` endpoint to retrieve lyrics, caching results in Firestore so external APIs are only queried once per song.
  - Integrate lyrics fetching into `adder.js` and `sync_engine.js` so new songs get lyrics automatically upon import.
- **Frontend (Flutter)**:
  - Add `LyricLine` and `LyricsData` models with high-performance LRC timestamp parser.
  - Add `LyricsService` with Firestore/backend integration and Hive local caching for offline mode.
  - Update `AudioProvider` to expose current song lyrics and compute active lyric line index from playback position stream.
  - Update `NowPlayingScreen` with a dedicated Lyrics toggle button in the bottom action bar.
  - Create a modern, animated `LyricsScreen` / `LyricsView` featuring Apple Music/Spotify style glassmorphic styling, bold active-line highlighting, auto-centering smooth scrolling, and interactive tap-to-seek.
  - Update `OfflineService` / `DownloadProvider` to persist song lyrics to local Hive boxes when songs are downloaded for offline listening.

## Capabilities

### New Capabilities
- `synced-lyrics-backend`: Backend service to fetch, sanitize, and cache time-synchronized (LRC) and plain lyrics into Firestore.
- `lyrics-viewer-ui`: Animated, real-time synchronized lyrics screen with auto-scroll, interactive tap-to-seek, and graceful fallbacks (plain lyrics, instrumental indicator, not found state).
- `offline-lyrics`: Automatic local caching of lyrics with downloaded songs for zero-latency, zero-network offline playback.

### Modified Capabilities
- `song-downloads`: Persist lyrics alongside audio and metadata during offline download.
- `now-playing-screen`: Add lyrics action button and interactive transition to lyrics viewer.

## Impact

- **Storage / Infrastructure Impact**: **Zero impact on Backblaze B2** (lyrics are small ~1.5 KB text strings stored in Firestore and Hive).
- **External Dependencies**: Uses free, public LRCLIB API (`https://lrclib.net/api`). No API keys or subscriptions required.
- **Risk & Non-Breaking Guarantee**: Audio playback and streaming engines remain 100% decoupled from lyrics. If lyrics are unavailable or fail to fetch, audio playback continues uninterrupted without any errors.
- **Rollback Safety**: Full snapshot tagged at `v1.0.0-phase1-complete` on branch `backup/phase-1-final`.
