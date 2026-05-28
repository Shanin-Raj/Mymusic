## ADDED Requirements

### Requirement: Full-Screen Player Status Bar Safe Area
The full-screen now playing player MUST constrain its body content below the system status bar safe area so that no UI elements (album art, controls, text) are obscured by the status bar.

#### Scenario: User opens the full-screen player
- **WHEN** the full-screen player is opened as a modal bottom sheet
- **THEN** the body content must be rendered below the system status bar, not behind it.

### Requirement: Status Bar Icon Brightness
The full-screen player MUST set the status bar icon brightness to match its theme (light icons for dark backgrounds, dark icons for light backgrounds).

#### Scenario: Full-screen player is displayed with dark theme
- **WHEN** the app is using a dark theme and the full-screen player is open
- **THEN** the status bar icons must be light in color.
