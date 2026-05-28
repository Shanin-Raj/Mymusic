# contextual-playback-logic Specification

## Purpose
Defines logic for playback behavior based on context (shuffling, repeating, queue management).
## Requirements
### Requirement: Shuffle Toggle Functionality
The system SHALL allow users to toggle shuffle mode. When enabled, the system SHALL call `_player.setShuffleModeEnabled(true)` and shuffle the sequence to ensure native randomization. When initiating playback using the playlist shuffle button, the system MUST manually shuffle the list and set the player shuffle mode to `none` (off) to prevent a double-shuffling bug that causes queue index mismatch.

#### Scenario: Enable shuffle
- **WHEN** the user toggles shuffle ON
- **THEN** the current playback queue SHALL be shuffled
- **AND** the shuffle indicator SHALL reflect the active state

#### Scenario: Playlist shuffle button pressed
- **WHEN** the user triggers shuffle play on a playlist
- **THEN** the list of songs is shuffled manually
- **AND** the audio player queue is updated with the shuffled list
- **AND** the active player shuffle mode is set to off to prevent double-shuffle

