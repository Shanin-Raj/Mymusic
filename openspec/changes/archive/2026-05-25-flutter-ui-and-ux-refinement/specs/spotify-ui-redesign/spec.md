## MODIFIED Requirements

### Requirement: Spotify Brand Color Palette
The system SHALL utilize a high-contrast dark theme centered around **Spotify Green (#1FDF64)** for primary actions and **Spotify Black (#191414)** for base backgrounds. The UI SHALL be polished with consistent padding, rounded corners, and smooth transitions.

#### Scenario: Active state styling
- **WHEN** an element is in an active or selected state
- **THEN** it SHALL be colored with #1FDF64

### Requirement: Immersive "Now Playing" View
The system SHALL feature a centered artwork card with a **4px corner radius** (small devices) or **8px corner radius** (large devices) on a dark gradient background. The view SHALL include all functional transport controls and utility buttons (Like, Queue, Sleep Timer) in a clean, balanced layout.

#### Scenario: Viewing active track
- **WHEN** the user opens the "Now Playing" screen
- **THEN** the artwork SHALL be the primary visual focus, perfectly centered without cropping or overlays
