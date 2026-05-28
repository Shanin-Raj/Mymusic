## ADDED Requirements

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
