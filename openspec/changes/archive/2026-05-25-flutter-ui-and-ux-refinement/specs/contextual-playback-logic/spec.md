## ADDED Requirements

### Requirement: Targeted Track Playback
The system SHALL ensure that when a user selects a specific track from any list (Library, Search results, or Playlist), that exact track begins playing immediately.

#### Scenario: User plays a song from search
- **WHEN** the user taps the 3rd track in a list of search results
- **THEN** the system SHALL start playback of the 3rd track
- **AND** SHALL NOT default to the first track in the entire library ("Safar")

### Requirement: Playback Queue Context
The system SHALL populate the upcoming queue based on the current view's context.

#### Scenario: User plays a track in a playlist
- **WHEN** a track is selected within a playlist
- **THEN** the system SHALL set the upcoming queue to be the subsequent tracks in that specific playlist only
