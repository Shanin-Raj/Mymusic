## ADDED Requirements

### Requirement: Dark Mode Toggle
The system SHALL provide a switch to toggle the application between Light and Dark themes.

#### Scenario: User switches to Light mode
- **WHEN** the user toggles the "Dark Mode" switch to OFF
- **THEN** the system SHALL apply the Light theme colors to all screens
- **AND** persist this preference across app restarts

### Requirement: Sleep Timer
The system SHALL allow users to set a timer that automatically pauses audio playback after a specified duration.

#### Scenario: User sets 15-minute timer
- **WHEN** the user selects "15 minutes" in the sleep timer settings
- **THEN** the system SHALL start a countdown
- **AND** pause the `AudioPlayer` when the countdown reaches zero
