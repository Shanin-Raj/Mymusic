## MODIFIED Requirements

### Requirement: Contextual Track Playback
The system SHALL support playing a specific song within a given context (Playlist, Search, or Library) and automatically populate the upcoming queue with the remaining tracks from that context.

#### Scenario: User plays a song from a playlist
- **WHEN** the user taps the 5th song in a playlist of 20 tracks
- **THEN** the system SHALL immediately start playback of the 5th song
- **AND** the queue SHALL contain tracks 6 through 20 as the "Up Next" items

#### Scenario: User plays a song from search results
- **WHEN** the user taps a song in a filtered search result
- **THEN** the system SHALL play that song
- **AND** the upcoming queue SHALL contain only the other songs currently visible in the search results
