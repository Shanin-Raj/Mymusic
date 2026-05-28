# UI Edge to Edge

## Purpose
TBD
## Requirements
### Requirement: Android edge-to-edge UI
The application MUST configure Android system UI overlays (status bar and navigation bar) to be transparent, allowing the application's background and gradients to draw fully edge-to-edge.

#### Scenario: Edge-to-edge rendering
- **WHEN** the application is launched on a compatible Android device
- **THEN** the system navigation bar and status bar should have transparent backgrounds, with app content visible beneath them.

### Requirement: Safe content padding
#### Scenario: Global navigation bar and player padding
- **WHEN** the application is rendered in edge-to-edge mode
- **THEN** the bottom-most interactive elements (specifically the custom `BottomNavigationBar` container) MUST include bottom padding equivalent to the system navigation bar inset.

