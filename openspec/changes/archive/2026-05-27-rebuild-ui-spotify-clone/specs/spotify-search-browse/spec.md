## MODIFIED Requirements

### Requirement: Spotify Search Browse View
The search screen SHALL feature a rounded search input bar at the top, followed by a "Start browsing" heading and a 2-column grid of colorful category cards (e.g., Music, Podcasts, Live Events), structured exactly like the Spotify-Clone repository's search view.

#### Scenario: User views the default search screen
- **WHEN** the user navigates to Search without typing a query
- **THEN** they see the rounded search bar and a grid of brightly colored, rounded category cards styled identically to the clone.

#### Scenario: User interacts with the search bar
- **WHEN** the user types in the search bar
- **THEN** the category cards are hidden and search results (track list) are shown instead using the clone's search result list tiles.
