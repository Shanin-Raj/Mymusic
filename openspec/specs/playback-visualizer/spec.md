## Purpose
This specification defines the requirements for the playback visualizer animations in the SonicVault application to ensure seamless, real-time playback state synchronization.
## Requirements
### Requirement: Playback visualizer animation
The application MUST display a dynamic EQ animation (visualizer) next to or on top of the artwork of the currently playing track. To prevent layout thrashing and high-frequency repainting that causes visible screen/image flickering on high-refresh-rate devices, the visualizer SHALL isolate its height animations within a static, fixed-height boundary container using independent alignment scaling.

#### Scenario: Track starts playing
- **WHEN** a user plays a track
- **THEN** the playback visualizer for that track's list item or player view begins animating.

#### Scenario: Track pauses
- **WHEN** the user pauses the currently playing track
- **THEN** the playback visualizer stops animating and displays a static indicator.

