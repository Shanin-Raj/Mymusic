## ADDED Requirements

### Requirement: Smooth Seek Bar Interaction
The music player's seek bar (progress slider) MUST support smooth sliding/dragging interactions. It MUST NOT be restricted to click/tap-to-seek functionality.

#### Scenario: User drags the seek bar handle
- **WHEN** the user presses and drags the thumb on the seek bar
- **THEN** the progress visually updates in real-time, and upon release (or during the drag), the audio playback position seeks to the corresponding timestamp.
