# spotify-search-browse Specification

## Purpose
TBD - created by archiving change spotify-ui-redesign. Update Purpose after archive.
## Requirements
### Requirement: Spotify Search Browse View
The search screen SHALL feature a rounded search input bar at the top, followed by a "Start browsing" heading and a 2-column grid of colorful category cards (e.g., Music, Podcasts, Live Events), structured exactly like the Spotify-Clone repository's search view.

#### Scenario: User views the default search screen
- **WHEN** the user navigates to Search without typing a query
- **THEN** they see the rounded search bar and a grid of brightly colored, rounded category cards styled identically to the clone.

#### Scenario: User interacts with the search bar
- **WHEN** the user types in the search bar
- **THEN** the category cards are hidden and search results (track list) are shown instead using the clone's search result list tiles.

### Requirement: Persistent Recent Searches
The search screen SHALL maintain a list of persistent recent searches using `SharedPreferences`. Tapping a song from the search results MUST add it to the top of the recent searches list. The list SHALL display a maximum of 10 unique recently searched songs.

#### Scenario: Tap search result adds to history
- **WHEN** the user searches for a track and taps it to play
- **THEN** the track ID is saved locally and placed at the top of the "Recent searches" list.

### Requirement: Recent Search Deletion
Each recent search list item SHALL feature a close ("x") icon on the right. Tapping the close icon MUST remove that item from the recent searches list and delete it from local persistence instantly.

#### Scenario: Deleting a recent search
- **WHEN** the user taps the close ("x") icon next to a song in the "Recent searches" list
- **THEN** the song is removed from the screen immediately and deleted from SharedPreferences history.

