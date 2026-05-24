## ADDED Requirements

### Requirement: Spotify-Themed Dark Mode
The application SHALL implement a dark color theme as the default, using the "Sonic Immersion" palette: Background `#121414`, Surface `#1e2020`, Primary `#1db954`, and On-Surface `#e3e2e2`.

#### Scenario: App Loads
- **WHEN** the user opens the application
- **THEN** the UI SHALL render with the dark monochromatic background and high-contrast text

### Requirement: 5-Tab Navigation Layout
The application SHALL implement a persistent bottom navigation bar with 5 distinct sections: Home, Search, Your Library, Premium, and Create.

#### Scenario: Navigating Between Screens
- **WHEN** the user taps a navigation icon
- **THEN** the corresponding screen SHALL become active and the icon SHALL be highlighted in the primary accent color

### Requirement: Glassmorphic Mini-Player
The UI SHALL include a persistent mini-player at the bottom of the screen (above the navigation bar) with a glassmorphic effect (`backdrop-filter: blur(20px)`) and integrated progress indicator.

#### Scenario: Music Playing in Background
- **WHEN** a track is playing and the user is browsing other screens
- **THEN** the mini-player SHALL remain visible, showing the current track's artwork and playback status
