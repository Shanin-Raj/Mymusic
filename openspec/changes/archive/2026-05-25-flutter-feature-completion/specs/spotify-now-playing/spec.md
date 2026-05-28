## MODIFIED Requirements

### Requirement: Spotify Full Screen Now Playing
The full screen player SHALL feature a top context header, large album art, interactive transport controls, and utility buttons (Like, Shuffle, Repeat, Queue, Sleep Timer).

#### Scenario: User likes a track
- **WHEN** the user taps the heart icon in the Player
- **THEN** the system SHALL toggle the track's liked status in the global state
- **AND** persist the updated favorites list to `shared_preferences`
