## MODIFIED Requirements

### Requirement: Spotify Library View
The library screen SHALL include a top filter chip row containing only **Playlists**, **Artists**, and **Albums** (the "Podcasts & Shows" option SHALL be removed). Tapping any filter chip MUST update the active library view dynamically, filtering the display list:
- **Playlists active**: Render grid of playlists (`PlaylistGridSliver`).
- **Artists active**: Render grid/list of unique, cleaned artists (`ArtistListSliver`).
- **Albums active**: Render grid/list of unique albums (`AlbumListSliver`).
- **No active filter**: Render the default list of all songs (`SongListSliver`).
Selected chips SHALL be rendered with a solid green background (`MyColors.greenColor`) and black text.

#### Scenario: User navigates to Your Library
- **WHEN** the user opens the Library tab
- **THEN** they see only three filter chips (Playlists, Artists, Albums) at the top, and all their songs in a default list.

#### Scenario: Selecting a library filter
- **WHEN** the user taps the "Playlists" filter chip
- **THEN** the chip is styled with a solid green background, and the view displays only the grid of playlists.
