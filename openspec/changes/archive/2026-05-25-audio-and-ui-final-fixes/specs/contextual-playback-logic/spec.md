## MODIFIED Requirements

### Requirement: Shuffle Toggle Functionality
The system SHALL allow users to toggle shuffle mode. When enabled, the system SHALL call `_player.setShuffleModeEnabled(true)` and shuffle the sequence to ensure native randomization.

#### Scenario: Enable shuffle
- **WHEN** the user toggles shuffle ON
- **THEN** the current playback queue SHALL be shuffled
- **AND** the shuffle indicator SHALL reflect the active state
