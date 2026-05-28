# Playback Responsiveness

## Purpose
TBD
## Requirements
### Requirement: Immediate Playback UI Update
The application MUST immediately update the UI to reflect a playback transition state without blocking the main UI thread with a full-screen or prolonged loading state while the audio buffers.

#### Scenario: User starts playing a new track
- **WHEN** the user selects a track to play
- **THEN** the UI MUST immediately transition to the "now playing" state locally and show a non-blocking buffering indicator if necessary, while the actual audio data loads in the background.

### Requirement: Localized Position Updates
To prevent screen-wide and image flickering during active song playback, high-frequency position ticks from the audio stream SHALL NOT trigger global application-wide widget rebuilds or state invalidations. All active progress bars and seek sliders MUST localize their updates by listening directly to position streams using localized StreamBuilders.

#### Scenario: Audio is actively playing and position advances
- **WHEN** a song is playing and the position stream emits new values
- **THEN** only localized progress indicators rebuild to advance progress bars
- **THEN** parent widgets, lists, and images remain static and completely flicker-free

