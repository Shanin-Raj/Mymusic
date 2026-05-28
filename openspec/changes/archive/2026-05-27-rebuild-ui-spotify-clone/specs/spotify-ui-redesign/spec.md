## MODIFIED Requirements

### Requirement: Spotify Brand Color Palette
The system SHALL utilize a high-contrast dark theme centered around **Spotify Green (#1FDF64)** for primary actions and **Spotify Black (#191414)** for base backgrounds, incorporating the specific gradient structures and color tokens provided by the Spotify-Clone widgets.

#### Scenario: Active state styling
- **WHEN** an element is in an active or selected state
- **THEN** it SHALL be colored with #1FDF64 and match the clone's active state styling.

### Requirement: Immersive "Now Playing" View
The system SHALL feature a centered artwork card with a **4px corner radius** (small devices) or **8px corner radius** (large devices) on a dark gradient background, matching the layout and aesthetic of the Spotify-Clone's player widgets.

#### Scenario: Viewing active track
- **WHEN** the user opens the "Now Playing" screen
- **THEN** the artwork SHALL be the primary visual focus, perfectly centered without cropping or overlays, rendering with the exact margins and padding defined in the clone widgets.
