## ADDED Requirements

### Requirement: Playback Persistence during State Changes
The system SHALL NOT interrupt or restart the current audio playback when purely cosmetic UI state changes occur, such as toggling Dark/Light mode or updating the "Like" (Favorite) status of a track.

#### Scenario: Toggling Dark Mode
- **WHEN** audio is playing
- **AND** the user toggles the theme
- **THEN** the UI colors SHALL update
- **AND** the audio SHALL continue playing from the current position without interruption

#### Scenario: Liking a track
- **WHEN** audio is playing
- **AND** the user taps the Like button
- **THEN** the icon state SHALL toggle
- **AND** the audio SHALL continue playing without restarting from the beginning
