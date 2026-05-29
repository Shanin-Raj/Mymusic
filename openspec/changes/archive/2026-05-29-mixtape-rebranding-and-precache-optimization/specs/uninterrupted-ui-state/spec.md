# uninterrupted-ui-state Specification

## Purpose
TBD - created by archiving change stabilize-ui-and-playback. Update Purpose after archive.
## Requirements
### Requirement: Playback Persistence during State Changes
The system SHALL NOT interrupt or restart the current audio playback when purely cosmetic UI state changes occur, such as toggling Dark/Light mode or updating the "Like" (Favorite) status of a track.

#### Scenario: Toggling Dark Mode
- **WHEN** audio is playing
- **AND** the user toggles the theme
- **THEN** the UI colors SHALL update
- **AND** the audio SHALL continue playing from the current position without interruption

#### Scenario: Liking a track
- **WHEN** audio is playing
- **AND** the user taps the Like button
- **THEN** the icon state SHALL toggle

### Requirement: Flickering-free Rebuilds
The system SHALL NOT re-trigger network requests or reset FutureBuilders when state-driven rebuilds occur (such as play/pause toggling, position tracking, or catalog liking).

#### Scenario: Toggling playback state
- **WHEN** the user pauses or plays a song
- **AND** the home view or library sliver rebuilds
- **THEN** the song lists and carousels SHALL NOT reload, flicker, or show a progress indicator
- **AND** the already fetched catalog data SHALL remain fully static and visible
