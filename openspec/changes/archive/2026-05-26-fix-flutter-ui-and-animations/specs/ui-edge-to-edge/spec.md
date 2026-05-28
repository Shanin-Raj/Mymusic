## ADDED Requirements

### Requirement: Android edge-to-edge UI
The application MUST configure Android system UI overlays (status bar and navigation bar) to be transparent, allowing the application's background and gradients to draw fully edge-to-edge.

#### Scenario: Edge-to-edge rendering
- **WHEN** the application is launched on a compatible Android device
- **THEN** the system navigation bar and status bar should have transparent backgrounds, with app content visible beneath them.

### Requirement: Safe content padding
The application MUST prevent interactive elements (like buttons or list items) from being obscured by the system navigation bar or status bar.

#### Scenario: Scrollable content visibility
- **WHEN** a user scrolls to the bottom of a list (e.g., in `SongListSliver`)
- **THEN** the last item must remain fully visible and interactive above the bottom navigation bar and system gesture area.
