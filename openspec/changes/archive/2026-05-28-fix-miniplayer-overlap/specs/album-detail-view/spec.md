## MODIFIED Requirements

### Requirement: Album Detail View Layout
The application SHALL provide a dedicated dynamic screen for viewing album details, styled with a high-fidelity red-to-black background gradient: `[const Color(0xFFC63224), const Color(0xFF641D17), const Color(0xFF271513), const Color(0xFF121212)]`. It MUST show the album artwork, the album title, the artist's name, and a list of all songs belonging to that album. The system MUST NOT group songs belonging to the `"Manual Addition"` album under `"Spotify Songs"`; `"Manual Addition"` SHALL be treated as its own separate and distinct album.
To prevent the list content from being obscured when the mini player is active, the album details screen list container SHALL support scrolling with a bottom padding of at least 90 px.

#### Scenario: User navigates to album detail
- **WHEN** the user selects an album in their library
- **THEN** the application transitions to the custom Album detail screen, displaying the corresponding album artwork, dynamic metadata, and its filtered list of tracks loaded from Firebase.

#### Scenario: User views manual addition album
- **WHEN** the user views the dedicated "Manual Addition" album
- **THEN** only manually synced/added songs are displayed in the track list

#### Scenario: User scrolls to bottom of album details
- **WHEN** the user scrolls to the bottom of the album details page while mini player is visible
- **THEN** all track items (including the last track) are fully visible above the mini player.
