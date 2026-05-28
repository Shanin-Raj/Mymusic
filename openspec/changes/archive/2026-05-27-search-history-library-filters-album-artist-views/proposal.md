## Why

Users need a more interactive, high-fidelity experience in the Spotify-clone application:
1. **Search History**: Tapping a search result should add it to "Recent searches", and tapping the "x" close button should remove it.
2. **Library Filters**: Tapping "Playlists", "Artists", or "Albums" should filter the library dynamically, removing the obsolete "Podcasts & Shows" chip.
3. **Dedicated Album & Artist Detail Screens**: Clicking an album or artist in the Library should navigate to dynamic, high-fidelity Figma-style screens showing their respective songs, resolving static placeholder text with real dynamic data mapped from Firebase.

## What Changes

- **Search Screen**: Integrated actual `SharedPreferences` persistence for search history. Clicking a search item adds it to recent searches. Clicking the "x" next to a recent search removes it from the screen and memory.
- **Library Screen Options**: Removed the "Podcasts & Shows" chip. Enabled interactive active states on the remaining chips: Playlists, Artists, and Albums.
- **Dynamic Grouping and Navigation**: Extracted unique artists (splitting composite comma-separated values, cleaning unicode spaces) and unique albums from Firebase song metadata.
- **New Album View Screen**: Rendered the beautiful Figma-compliant red-dark gradient page with centered album artwork, dynamic metadata (title, artist, year), shuffle play controls, and play capability.
- **New Artist View Screen**: Rendered a premium blue-dark gradient page with an oval artist profile image, dynamic artist title, shuffle play controls, and play capability.

## Capabilities

### New Capabilities
- `album-detail-view`: Standardize dynamic Album screen layout, data fetching, and shuffle play logic.
- `artist-detail-view`: Standardize dynamic Artist screen layout, data fetching, and shuffle play logic.

### Modified Capabilities
- `spotify-ui-redesign`: Support dynamic navigation to Album and Artist detail screens, and clean layout mappings.
- `spotify-search-browse`: Implement persistent search history retrieval, insertion, and deletion.
- `spotify-library-view`: Enable interactive filters for Playlists, Artists, and Albums with dynamic sliver rendering.

## Impact

- **lib/services/storage_service.dart**: Added recent searches methods.
- **lib/clone_widgets/library_options_list.dart**: Removed podcasts chip, added selection callbacks.
- **lib/screens/main_screen.dart**: Refactored `SearchView` to manage history, and `LibraryView` to manage filters and navigate.
- **lib/screens/album_detail_screen.dart**: [NEW] High-fidelity custom Album detail screen.
- **lib/screens/artist_detail_screen.dart**: [NEW] High-fidelity custom Artist detail screen.
