## ADDED Requirements

### Requirement: Playback visualizer animation
The application MUST display a dynamic EQ animation (visualizer) next to or on top of the artwork of the currently playing track.

#### Scenario: Track starts playing
- **WHEN** a user plays a track
- **THEN** the playback visualizer for that track's list item or player view begins animating.

#### Scenario: Track pauses
- **WHEN** the user pauses the currently playing track
- **THEN** the playback visualizer stops animating and displays a static indicator.
