## Why

The MiniPlayer in the Album and Artist detail screens overlaps with the system navigation bar (such as gesture navigation bar or soft keys) because it is not safe-area aware. Additionally, the bottom padding of the song list is too small (16 px), resulting in the final song tile being obscured underneath the MiniPlayer when active.

## What Changes

- Wrap the `MiniPlayer` widget in both `AlbumDetailScreen` and `ArtistDetailScreen` inside a `SafeArea` with `top: false` to ensure it clears the system navigation bar.
- Increase the bottom padding of the `SliverPadding` element in `AlbumDetailScreen` and `ArtistDetailScreen` from `16` to `90` to allow the last song tile to be fully visible and scrollable above the MiniPlayer.
- Ensure signed release APK builds successfully.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `spotify-mini-player`: The mini player must respect bottom safe area insets on detail screens.
- `album-detail-view`: The album detail view layout must provide adequate bottom padding for the song list to prevent overlap with the mini player.
- `artist-detail-view`: The artist detail view layout must provide adequate bottom padding for the song list to prevent overlap with the mini player.

## Impact

- `AlbumDetailScreen` ([album_detail_screen.dart](file:///d:/music/flutter_app/lib/screens/album_detail_screen.dart))
- `ArtistDetailScreen` ([artist_detail_screen.dart](file:///d:/music/flutter_app/lib/screens/artist_detail_screen.dart))
