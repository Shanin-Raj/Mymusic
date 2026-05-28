## MODIFIED Requirements

### Requirement: Global Library Search
The system SHALL provide a search interface that filters all tracks in the library by name or artist. The search view SHALL remain in an empty or placeholder state until a user enters a query.

#### Scenario: User types in search bar
- **WHEN** the user enters characters into the search field
- **THEN** the system SHALL update the track list in real-time to match the query
- **AND** allow the user to play any matching track immediately

#### Scenario: Search bar is empty
- **WHEN** the search input is empty
- **THEN** the system SHALL NOT display the library tracks
- **AND** SHALL show a "Start browsing" heading with a grid of colorful placeholder category cards (e.g., Music, Podcasts, Live Events) matching the UI design reference.
