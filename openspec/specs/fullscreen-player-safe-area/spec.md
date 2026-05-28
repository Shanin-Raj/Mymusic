# Capability: fullscreen-player-safe-area

## Purpose
Handles the safe area constraints and status bar styling specifically for the full-screen now playing view.
## Requirements
### Requirement: Full-Screen Player Status Bar Safe Area
#### Scenario: Header and metadata visibility
- **WHEN** the user opens the full-screen player
- **THEN** the top-level controls (e.g., the collapse arrow) and the "PLAYING FROM..." header MUST be padded from the top to ensure they do not overlap with the system status bar icons.

### Requirement: Status Bar Icon Brightness
The full-screen player MUST set the status bar icon brightness to match its theme (light icons for dark backgrounds, dark icons for light backgrounds).

#### Scenario: Full-screen player is displayed with dark theme
- **WHEN** the app is using a dark theme and the full-screen player is open
- **THEN** the status bar icons must be light in color.

