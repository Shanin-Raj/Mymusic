## MODIFIED Requirements

### Requirement: Spotify Design Tokens
The application SHALL use a curated high-fidelity typography and color system defining Spotify's core color palette and brand identity. It SHALL use Google Fonts' `Montserrat` as the global typeface. The system SHALL support both dark and light modes: dark mode uses `#121212` as the screen background, `#111111` for elevated surfaces, `#282828` for cards/chips, and primary text colored white; light mode uses off-white `#F5F5F7` as the background, `#FFFFFF` for elevated surfaces/cards, and dark text. The primary brand green accent SHALL be `#1ED760` (dark mode) and `#1DB954` (light mode).

#### Scenario: App loads in default theme
- **WHEN** the application is loaded
- **THEN** the interface is rendered using the high-fidelity Spotify-style dark theme colors (#121212, #111111) and Google Fonts' Montserrat typography

#### Scenario: Active theme toggle
- **WHEN** the user switches between dark and light themes
- **THEN** the application colors change between dark (#121212 background, #111111 surfaces) and light (#F5F5F7 off-white, #FFFFFF surfaces) while maintaining Montserrat as the global typeface
