# spotify-now-playing Specification

## Purpose
TBD - created by archiving change spotify-ui-redesign. Update Purpose after archive.
## Requirements
### Requirement: Spotify Full Screen Now Playing
The full screen player SHALL feature a top context header ("PLAYING FROM..."), a large square album art cover, song title/artist metadata on the left with a favorite button on the right, a seek slider with time stamps, transport controls (shuffle, previous, play/pause, next, repeat), and a bottom action bar with extra features. The system SHALL pre-load the next track's audio source 30 seconds before the current track ends to ensure zero-latency transitions.

#### Scenario: User opens full screen player
- **WHEN** the user taps the mini player
- **THEN** the full screen player slides up, displaying the Spotify-style vertical layout with large artwork and prominent transport controls

#### Scenario: Background pre-loading
- **WHEN** the active track has less than 30 seconds remaining
- **THEN** the system SHALL trigger the pre-fetching logic for the next song in the queue

