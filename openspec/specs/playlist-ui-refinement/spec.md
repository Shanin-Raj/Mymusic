## Purpose
This specification defines the requirements for the playlist interface, specifically controls and navigation, to provide a premium, modern user experience.
## Requirements
### Requirement: Playback Controls in Playlist
The system SHALL only display a shuffle button for initiating playback in the playlist view. The play button SHALL be removed to reduce visual clutter.

#### Scenario: Displaying controls
- **WHEN** user views a playlist
- **THEN** system displays a shuffle button and no play button

### Requirement: Shuffle Playback Behavior
The system SHALL always start playback with the first song in the shuffled list when the shuffle button is pressed. The system MUST ensure the audio queue is properly shuffled.

#### Scenario: Pressing shuffle
- **WHEN** user presses the shuffle button in the playlist view
- **THEN** the playlist queue is shuffled
- **THEN** playback starts immediately with the first song of the newly shuffled queue

### Requirement: Playlist UI Padding
The system SHALL display padding above the list of songs to prevent the top song from being hidden by the top navigation bar. The system SHALL display padding between the shuffle button and the first song in the list.

#### Scenario: Viewing top of playlist
- **WHEN** user views the top of the playlist
- **THEN** the top song is fully visible below the top navigation bar
- **THEN** there is visual separation between the top controls (shuffle button) and the first song item

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

