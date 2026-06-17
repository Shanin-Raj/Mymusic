# Tasks - Streaming and Cache Fixes

- [x] Backend: Add `activeDownloads` promise Map and `downloadSongFromTelegram(song)` helper in `backend/server.js`
- [x] Backend: Implement atomic temp file renaming to prevent read/write stream corruption
- [x] Backend: Refactor stream and precache routes to consume the single-flight download helper
- [x] Backend: Set up real-time `onSnapshot` listeners in `listenToLibrary()` and call it in `start()`
- [x] Backend: Remove stale manual cache invalidations `Cache = null` across all routes
