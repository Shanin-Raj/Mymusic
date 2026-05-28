## ADDED Requirements

### Requirement: Real-time Audio Streaming
The system SHALL stream audio from the backend `/api/stream/{id}` endpoints using the `just_audio` engine.

#### Scenario: User plays a track
- **WHEN** the user taps a track in the library or home feed
- **THEN** the system SHALL load the stream URL for that track
- **AND** the audio SHALL begin playing immediately

### Requirement: Interactive Seek Bar
The system SHALL allow users to change the current playback position by dragging a progress slider.

#### Scenario: User seeks in a track
- **WHEN** the user drags the slider in the player window
- **THEN** the system SHALL update the `AudioPlayer` position to the selected time
- **AND** the playback SHALL continue from that position
