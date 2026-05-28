## MODIFIED Requirements

### Requirement: Spotify Library View
The library screen SHALL include a top filter chip row containing only **Playlists**, **Artists**, and **Albums** (the "Podcasts & Shows" option SHALL be removed). Tapping any filter chip MUST update the active library view dynamically, filtering the display list. Selected chips SHALL be rendered with a solid green background (`MyColors.greenColor`) and black text.
Additionally, the system SHALL display a prominent `+` (plus) action icon in the library SliverAppBar:
- **No active filter (default tab)**: Tapping `+` opens a modular bottom sheet offering "Add Song (Sync Library)", "Playlist", "Artist", and "Album" options.
- **Playlists active**: Tapping `+` opens a quick "New Playlist" creation dialog directly.
- **Tapping Playlist in Plus menu**: Displays "+ Create New Playlist" at the top, followed by a list of available playlists.
- **Tapping Artist / Album in Plus menu**: Displays a scrollable sheet of unique artists or albums currently inside the library for instant detail navigation.

#### Scenario: User navigates to Your Library
- **WHEN** the user opens the Library tab
- **THEN** they see only three filter chips (Playlists, Artists, Albums) at the top, all their songs in a default list, and a `+` action button in the AppBar.

#### Scenario: Selecting a library filter
- **WHEN** the user taps the "Playlists" filter chip
- **THEN** the chip is styled with a solid green background, the view displays only the grid of playlists, and the `+` icon updates to trigger new playlist creation dialog.

#### Scenario: Clicking plus button on library home
- **WHEN** the user taps the `+` button while on the default Library view
- **THEN** a custom bottom sheet opens, showing clean navigation options for adding songs, creating/viewing playlists, and navigating artists or albums.
