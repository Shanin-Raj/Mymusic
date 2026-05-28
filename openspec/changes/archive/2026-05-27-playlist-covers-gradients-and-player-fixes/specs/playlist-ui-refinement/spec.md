## ADDED Requirements

### Requirement: Seeded HSL Playlist Gradients
The system SHALL dynamically generate uniquely-tailored, harmonized linear gradients for each playlist detail page background. These colors MUST be calculated by hashing the playlist's unique identifier and mapping the resulting hash to stable, predefined Hue, Saturation, and Lightness (HSL) boundaries for both dark and light modes.

#### Scenario: Navigating to playlist detail page
- **WHEN** the user views a playlist detail page
- **THEN** the header background linear gradient is generated using colors seeded by the playlist ID
- **THEN** this background gradient remains perfectly consistent every time the playlist is opened

### Requirement: Dynamic Playlist Cover Asset Fallbacks
The system SHALL robustly resolve playlist cover images from both local sibling asset directories and internal packaged folders. If the primary sibling `../images` directory is absent or empty (such as in a Cloud Run container), the backend MUST fall back to reading files from the internal `backend/images` folder.

#### Scenario: Running playlist API in containerized production
- **WHEN** the backend processes a request to fetch playlists on the server
- **THEN** it resolves cover images using the internal packaged folder, returning valid absolute cover URLs to the client
