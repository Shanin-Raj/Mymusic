## Why

The app navigation bar was previously missing from the Album, Artist, and Playlist detail screens, making navigation inconsistent. The MiniPlayer also overlapped with the system navigation bar when on these screens. Additionally, the backend `yt-dlp` tool issued warnings and sometimes failed when a Javascript runtime wasn't explicitly provided. Finally, the `SongTile` widget required the `song` object passed to it in the Artist screen to play songs smoothly.

## What Changes

- Refactored `_BottomNav` into `AppBottomNav` and made it public in `main_screen.dart`.
- Inserted `AppBottomNav` into `AlbumDetailScreen`, `ArtistDetailScreen`, and `PlaylistDetailScreen` via the `bottomNavigationBar` scaffold slot.
- Placed `MiniPlayer` safely above `AppBottomNav` to avoid overlapping the system's gesture bar.
- Added `--js-runtimes nodejs` to `downloader.js` backend to prevent `yt-dlp` Javascript failures.
- Passed `song` to the `SongTile` widget inside `ArtistDetailScreen`.

## Capabilities

### New Capabilities
- `ui-tweaks-and-ytdlp-fix`: UI Navbar and ytdlp fixes

### Modified Capabilities

## Impact

- `lib/screens/main_screen.dart`
- `lib/screens/album_detail_screen.dart`
- `lib/screens/artist_detail_screen.dart`
- `backend/downloader.js`
