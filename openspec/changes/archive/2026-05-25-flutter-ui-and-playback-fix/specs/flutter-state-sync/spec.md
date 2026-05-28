## ADDED Requirements

### Requirement: Metadata Synchronization
The system SHALL update the `mediaItem` stream in the `AudioHandler` whenever the playback index changes within a `ConcatenatingAudioSource`.

#### Scenario: Track transition
- **WHEN** the `just_audio` player transitions to the next track in the playlist
- **THEN** the `AudioHandler` SHALL emit the new track's metadata to the `mediaItem` stream
- **AND** the UI components (MiniPlayer, FullScreenPlayer) SHALL update their display immediately

### Requirement: Position Persistence
The system SHALL broadcast the current playback position through the `playbackState` stream at regular intervals.

#### Scenario: Continuous playback
- **WHEN** music is playing
- **THEN** the system SHALL update the `position` in the `playbackState` at least every 500ms
- **AND** the player's progress bar SHALL move smoothly in the UI
