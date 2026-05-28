## Why

This change delivers requested premium feature additions and visual polish:
1. Playlists needed custom cover support instead of purely random generation, pulling choices from a static directory of 20 images.
2. Playlists could not be deleted from the client UI once created.
3. Song removal from playlists lacked standard swipe-to-delete UX and clarity that it only removes the item from the playlist and not the main library.
4. Empty playlist views suffered from a minor layout boundary bug where the "ADD SONGS" CTA overlapped the device bottom safe zones.
5. Manually added songs (marked with `'Manual Addition'`) were incorrectly merged into the generic `'Spotify Songs'` album block.

## What Changes

- Add a GET `/api/images` endpoint in the Node.js backend to serve all custom cover image options dynamically to the client.
- Update playlist creation forms to fetch choices, display a horizontal preview, highlight selection with green borders, and persist it to Firestore.
- Add a Delete icon in `PlaylistDetailScreen` header that deletes the playlist and returns to the library.
- Wrap song rows in `Dismissible` to remove the song from that playlist on swipe left, prompting a confirmation dialog first.
- Apply bottom media safe padding dynamically on the empty playlist view.
- Exclude `'Manual Addition'` from `'Spotify Songs'` filtering/grouping throughout the app.

## Capabilities

### New Capabilities

### Modified Capabilities
- `flutter-playlist-management`: Extend the playlist management capabilities to support custom covers, playlist deletion, swipe-to-remove song mechanics, and empty-state layout adjustments.
- `album-detail-view`: Refine album categorization to separate `"Manual Addition"` songs into their own distinct album view.

## Impact

- Modified files: `server.js`, `api_service.dart`, `playlist_provider.dart`, `main_screen.dart`, `album_detail_screen.dart`.
