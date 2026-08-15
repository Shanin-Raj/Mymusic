# Synced Lyrics Implementation Tasks

## 1. Backend Service & Endpoints
- [x] 1.1 Create `backend/lyrics.js` with LRCLIB query logic, title/artist sanitization, and duration validation
- [x] 1.2 Add `GET /api/songs/:id/lyrics` endpoint in `backend/server.js` with Firestore read/write caching
- [x] 1.3 Update `backend/adder.js` to automatically fetch and save lyrics to Firestore when adding songs
- [x] 1.4 Update `deploy_hf/backend` with identical backend changes to ensure parity

## 2. Flutter Models & Services
- [x] 2.1 Create `flutter_app/lib/models/lyrics_model.dart` with `LyricLine`, `LyricsData`, and LRC parser
- [x] 2.2 Create `flutter_app/lib/services/lyrics_service.dart` to fetch lyrics from backend and handle Hive local caching
- [x] 2.3 Update `flutter_app/lib/services/api_service.dart` with `getSongLyrics(songId, songName, artist, durationMs)` method
- [x] 2.4 Update `flutter_app/lib/services/offline_service.dart` to persist lyrics during song download

## 3. Audio Provider & State Management
- [x] 3.1 Add `LyricsData? currentLyrics`, `bool isLoadingLyrics`, and `int activeLyricIndex` to `flutter_app/lib/providers/audio_provider.dart`
- [x] 3.2 Listen to `positionStream` in `AudioProvider` to calculate and notify `activeLyricIndex` in real-time
- [x] 3.3 Automatically trigger `fetchLyricsForCurrentSong()` whenever `currentSong` changes
- [x] 3.4 Provide `seekToLyric(Duration timestamp)` method

## 4. UI Widgets & Screen
- [x] 4.1 Create `flutter_app/lib/features/player/lyrics_screen.dart`:
  - [x] 4.1.1 Fullscreen glassmorphism design with animated album art blur background
  - [x] 4.1.2 Auto-scrolling list maintaining active line at center
  - [x] 4.1.3 Active line styling: enlarged, bold, high contrast / neon glow
  - [x] 4.1.4 Inactive lines styling: subtle opacity gradient (35-40% opacity)
  - [x] 4.1.5 Interactive tap-to-seek on any lyric line
  - [x] 4.1.6 Plain lyrics fallback view
  - [x] 4.1.7 Instrumental track UI state
  - [x] 4.1.8 "No lyrics found" empty state with retry button
- [x] 4.2 Update `flutter_app/lib/features/player/now_playing_screen.dart`:
  - [x] 4.2.1 Add Lyrics icon button (`Icons.lyrics_outlined`) in bottom action bar next to timer, download, and queue
  - [x] 4.2.2 Navigate smoothly to `LyricsScreen` on tap

## 5. Verification & Testing
- [x] 5.1 Test backend endpoint `GET /api/songs/:id/lyrics` with synced songs, unsynced songs, and instrumental songs
- [x] 5.2 Test Firestore caching (confirm 2nd call does not query external API)
- [x] 5.3 Test Flutter UI synced scrolling and tap-to-seek functionality
- [x] 5.4 Test offline mode lyrics retrieval with downloaded songs
- [x] 5.5 Confirm zero regressions in audio streaming, playback, rooms, or downloads
- [x] 5.6 Build Flutter release APK (`build/app/outputs/flutter-apk/app-release.apk`)
