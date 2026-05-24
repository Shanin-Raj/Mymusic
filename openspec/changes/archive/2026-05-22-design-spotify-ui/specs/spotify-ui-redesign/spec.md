## ADDED Requirements

### Requirement: Spotify Brand Color Palette
The system SHALL utilize a high-contrast dark theme centered around **Spotify Green (#1FDF64)** for primary actions and **Spotify Black (#191414)** for base backgrounds.

#### Scenario: Active state styling
- **WHEN** an element is in an active or selected state
- **THEN** it SHALL be colored with #1FDF64

### Requirement: Platform-Native Typography
The system SHALL implement a platform-native sans-serif font stack to ensure maximum legibility and integration consistency across iOS, Android, and Web.

#### Scenario: Font rendering
- **WHEN** the application is loaded on a device
- **THEN** the text SHALL render using the default system sans-serif font (e.g., San Francisco on iOS, Roboto on Android)

### Requirement: Simplified "Like" Interaction
The system SHALL replace the heart icon with a **"+" icon** for the "Like" feature. Upon selection, the system SHALL display a confirmation toast.

#### Scenario: Adding to Liked Songs
- **WHEN** the user taps the "+" icon on a track
- **THEN** the icon SHALL toggle its active state and the system SHALL display a message: "Added to Your Library"

### Requirement: Immersive "Now Playing" View
The system SHALL feature a centered artwork card with a **4px corner radius** (small devices) or **8px corner radius** (large devices) on a dark gradient background.

#### Scenario: Viewing active track
- **WHEN** the user opens the "Now Playing" screen
- **THEN** the artwork SHALL be the primary visual focus, perfectly centered without cropping or overlays

### Requirement: Essential Playback Controls
The system SHALL provide a minimalist and intuitive control set consisting of **Skip Previous**, **Play/Pause**, and **Skip Next** buttons.

#### Scenario: Playback control interaction
- **WHEN** the user interacts with the central play button
- **THEN** the system SHALL toggle between play and pause states instantly
