## 1. Backend — Progressive Streaming

- [x] 1.1 Add MIME type map in `server.js` for audio file extensions
- [x] 1.2 Rewrite `streamFile()` helper to accept `res` and support range requests
- [x] 1.3 Implement tee stream in `/api/stream/:id` — write Telegram chunks to both cache file and `res`
- [x] 1.4 Implement download queue with two priority levels (1=stream, 2=precache)
- [x] 1.5 Rewrite `/api/precache/:id` to use `WriteStream` instead of memory buffer
- [x] 1.6 Update precache endpoint to use download queue at priority 2

## 2. Flutter — Local Audio Cache

- [x] 2.1 Create `AudioCacheService` with `downloadSong()`, `touch()`, `clearCache()`, and inactivity timer
- [x] 2.2 Wire `AudioHandler` to pre-download next song on `currentIndexStream` change
- [x] 2.3 Replace streaming `AudioSource` with `AudioSource.file()` when local cache available
- [x] 2.4 Add `WidgetsBindingObserver` lifecycle listener in `main.dart` — clear cache on `detached`

## 3. Flutter — Lint & Syntax Fixes

- [x] 3.1 Fix syntax errors: `showSnackBar` missing closing parenthesis, `debugPrint` import
- [x] 3.2 Fix `const` constructor lint warning in `song_tile.dart`
- [x] 3.3 Fix `BuildContext` async gap warnings in `main_screen.dart`

## 4. Merge & Deploy

- [x] 4.1 Resolve merge conflicts with remote download queue changes
- [x] 4.2 Push to GitHub to trigger Render auto-deploy
- [x] 4.3 Build debug and release APKs
