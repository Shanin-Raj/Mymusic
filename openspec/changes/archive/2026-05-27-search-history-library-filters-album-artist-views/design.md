## Context

We are extending the visual-only Figma redesign of the Spotify clone with deep logical features. This covers persistent search history, interactive tab-filtering inside "Your Library", and fully functional dynamic Album and Artist detail screens. The core challenge is mapping the existing unstructured Firebase song metadata (which contains composite, comma-separated artist strings and generic "Unknown Album" names) into clean, navigatable lists of unique artists and albums.

## Goals / Non-Goals

**Goals:**
- Implement robust local persistence of recently searched songs using `SharedPreferences`.
- Enable users to delete individual recent searches with immediate UI updates.
- Refactor the library filter chips to remove podcasts and dynamically toggle views between Playlists, Artists, and Albums.
- Build clean, responsive Album and Artist detail screens modeled after the Figma visual blueprints, dynamically populated with matching songs from Firebase.
- Integrate shuffle play support on the new detail screens.

**Non-Goals:**
- Altering the backend DB schema or endpoints. All grouping, cleaning, and filtering must be performed dynamically on the client-side.

## Decisions

- **Search History Storage Structure**:
  - *Decision*: Store the history as a list of unique song IDs (`List<String>`) in `SharedPreferences` under the key `sv_recent_searches`.
  - *Rationale*: Storing only song IDs avoids stale cached metadata. When loading the search view, the app will map these IDs against the full Firebase song list to render the most up-to-date titles, artists, and artwork. Tapping a song will insert/move its ID to index 0, capped at 10 items.

- **Dynamic Metadata Parsing & Cleaning**:
  - *Decision*: When filtering by Artist, the app will parse composite artist lists (e.g., ` सचिन-जिगर, Shreya Ghoshal `) by splitting on commas, stripping non-standard characters (like unicode ``), and trimming spaces. 
  - *Rationale*: This guarantees that artists listed as collaborators are correctly displayed in the unique Artists list, and clicking their name shows all songs they contributed to.

- **Library View Filter State**:
  - *Decision*: Refactor `LibraryView` to track an active filter string: `String? _selectedFilter`. 
  - *Sliver Mapping*:
    - `null` (unselected): renders all songs in a list (`SongListSliver`).
    - `'Playlists'`: renders the playlist grid (`PlaylistGridSliver`).
    - `'Artists'`: renders a clean grid of unique, cleaned artists with circular thumbnails (`ArtistListSliver`).
    - `'Albums'`: renders a grid of unique albums with square artwork (`AlbumListSliver`).

- **Detail Screen Gradients & Layouts**:
  - *Decision*: Re-engineer the Figma `AlbumView` positioning into fluid, responsive Flutter widgets inside a custom pushed route.
  - *Colors*: Album uses a high-contrast red-dark gradient (`[const Color(0xFFC63224), const Color(0xFF641D17), const Color(0xFF271513), const Color(0xFF121212)]`). Artist uses a deep blue-dark gradient (`[const Color(0xFF1E3264), const Color(0xFF14142B), const Color(0xFF121212)]`).
  - *Playback Integration*: Provide a large floating green action button executing `context.read<PlayerProvider>().shufflePlay(filteredSongs)` to shuffle all tracks in that album/artist scope.

## Risks / Trade-offs

- **[Risk] High-Frequency Local I/O on Search History** → Every tap on a search result writes to disk.
  - *Mitigation*: The `SharedPreferences` package executes writes asynchronously in the background, preventing thread blocking or UI lagging.
- **[Risk] Complex Client-Side Grouping Latency** → Processing hundreds of songs dynamically on every Library load.
  - *Mitigation*: The list size is small (under 1,000 songs) which takes less than a millisecond to group in Dart. We can cache the parsed lists in memory for immediate state switches.
