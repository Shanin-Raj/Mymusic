## ADDED Requirements

### Requirement: FFMPEG Path Configuration
The system SHALL determine the ffmpeg location dynamically rather than using a hardcoded path.

#### Scenario: FFMPEG_LOCATION is set in environment
- **WHEN** the `FFMPEG_LOCATION` environment variable is defined
- **THEN** the `--ffmpeg-location` argument with the environment variable's value is passed to `yt-dlp`

#### Scenario: FFMPEG_LOCATION is not set
- **WHEN** the `FFMPEG_LOCATION` environment variable is undefined or empty
- **THEN** the `--ffmpeg-location` argument is omitted when calling `yt-dlp`
