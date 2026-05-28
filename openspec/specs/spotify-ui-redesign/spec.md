# spotify-ui-redesign Specification

## Purpose
TBD - created by archiving change design-spotify-ui. Update Purpose after archive.
## Requirements
### Requirement: Spotify Brand Color Palette
The system SHALL utilize a high-contrast dark theme centered around **Spotify Green (#1FDF64)** for primary actions and **Spotify Black (#191414)** for base backgrounds, incorporating the specific gradient structures and color tokens provided by the Spotify-Clone widgets.

#### Scenario: Active state styling
- **WHEN** an element is in an active or selected state
- **THEN** it SHALL be colored with #1FDF64 and match the clone's active state styling.

### Requirement: Platform-Native Typography
The system SHALL implement Google Fonts' Montserrat typeface globally as the application's geometric font structure to provide a premium "Spotify Mix" aesthetic. All typography sizes and weights (titles, headers, body, metadata) SHALL be scaled up to match webapp standards for improved readability.

#### Scenario: Font rendering
- **WHEN** the application is loaded on a device
- **THEN** the text SHALL render using Montserrat from the Google Fonts package, displaying at the scaled-up sizes specified in the visual redesign

### Requirement: Simplified "Like" Interaction
The system SHALL replace the heart icon with a **"+" icon** for the "Like" feature. Upon selection, the system SHALL display a confirmation toast.

#### Scenario: Adding to Liked Songs
- **WHEN** the user taps the "+" icon on a track
- **THEN** the icon SHALL toggle its active state and the system SHALL display a message: "Added to Your Library"

### Requirement: Immersive "Now Playing" View
The system SHALL feature a centered artwork card with a **4px corner radius** (small devices) or **8px corner radius** (large devices) on a dark gradient background, matching the layout and aesthetic of the Spotify-Clone's player widgets.

#### Scenario: Viewing active track
- **WHEN** the user opens the "Now Playing" screen
- **THEN** the artwork SHALL be the primary visual focus, perfectly centered without cropping or overlays, rendering with the exact margins and padding defined in the clone widgets.

### Requirement: Essential Playback Controls
The system SHALL provide a minimalist and intuitive control set consisting of **Skip Previous**, **Play/Pause**, and **Skip Next** buttons.

#### Scenario: Playback control interaction
- **WHEN** the user interacts with the central play button
- **THEN** the system SHALL toggle between play and pause states instantly

### Requirement: Android TWA Manifest Compatibility
The PWA manifest and HTML meta tags SHALL include all necessary configurations for Trusted Web Activity identification, specifically matching the Android package name.

#### Scenario: Manifest validation
- **WHEN** the Android TWA shell is initialized
- **THEN** it SHALL find a `related_applications` entry in `manifest.json` pointing to the `com.musicvault.twa` package

