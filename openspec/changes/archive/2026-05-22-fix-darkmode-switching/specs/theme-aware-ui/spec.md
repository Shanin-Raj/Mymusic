## ADDED Requirements

### Requirement: Theme Toggle in Now Playing Screen
The Now Playing screen (`#screen-player`) SHALL provide a dark mode toggle button (`#btn-theme-player`) in the player-extras row, identical in behavior to the existing `#btn-theme` button.

#### Scenario: Player screen theme button is present
- **WHEN** the user opens the Now Playing screen
- **THEN** a dark mode toggle icon button is visible in the player-extras row

#### Scenario: Player screen theme button toggles the theme
- **WHEN** the user taps `#btn-theme-player`
- **THEN** the theme toggles (dark↔light) and both `#btn-theme` and `#btn-theme-player` icons update accordingly

## ADDED Requirements

### Requirement: Theme-Aware Progress Bar
The seek/progress bar track background in the Now Playing screen SHALL use a theme-aware CSS variable so it remains visible in both dark and light mode.

#### Scenario: Progress bar visible in light mode
- **WHEN** the app is in light mode
- **THEN** the `.progress-bar` track has a visible background that contrasts with the white player background

#### Scenario: Progress bar visible in dark mode
- **WHEN** the app is in dark mode
- **THEN** the `.progress-bar` track has a visible background that contrasts with the dark player background

## ADDED Requirements

### Requirement: Theme-Aware Mini Player and Bottom Nav
The mini-player and bottom navigation bar SHALL use theme-aware CSS variables for their backgrounds instead of hardcoded dark colors.

#### Scenario: Mini player adapts to light mode
- **WHEN** the app is switched to light mode
- **THEN** the mini-player background uses the light theme glass variable (`rgba(255,255,255,0.85)`)

#### Scenario: Bottom nav adapts to light mode
- **WHEN** the app is switched to light mode
- **THEN** the bottom nav background uses the light theme surface variable

## ADDED Requirements

### Requirement: Theme-Aware Input Fields
Input fields in the Add Music screen and modals SHALL use `var(--surface)` for their background to adapt to theme switching.

#### Scenario: Inputs visible in light mode
- **WHEN** the app is in light mode
- **THEN** input fields in the Create/Add screen have a visible light background rather than a dark `#282828` background
