## ADDED Requirements

### Requirement: User can download a song

The system SHALL allow users to download individual songs for offline playback. Downloaded songs SHALL persist across app restarts and SHALL NOT be auto-cleared.

#### Scenario: User taps download button on song tile

- **WHEN** user taps the download icon on a song tile
- **THEN** the system starts downloading the song
- **THEN** the icon changes to a circular progress indicator showing download progress

#### Scenario: User taps download button on now-playing screen

- **WHEN** user taps the download icon on the now-playing screen
- **THEN** the system starts downloading the current song
- **THEN** the icon changes to a circular progress indicator showing download progress

#### Scenario: Download completes successfully

- **WHEN** the download reaches 100%
- **THEN** the progress indicator changes to a filled download icon
- **THEN** the song appears in the Downloads management screen
- **THEN** the song plays from local storage on subsequent plays

#### Scenario: Download fails

- **WHEN** the download fails due to network error
- **THEN** the icon reverts to the not-downloaded state
- **THEN** the system SHALL clean up any partial file

### Requirement: User can remove a downloaded song

The system SHALL allow users to remove downloaded songs, freeing device storage.

#### Scenario: User removes a download from song tile

- **WHEN** user taps the filled download icon on a song tile
- **THEN** the system deletes the audio file and metadata
- **THEN** the icon reverts to not-downloaded state

#### Scenario: User removes a download from now-playing screen

- **WHEN** user taps the filled download icon on the now-playing screen
- **THEN** the system deletes the audio file and metadata
- **THEN** the icon reverts to not-downloaded state

### Requirement: Downloads persist across sessions

The system SHALL persist download metadata using Hive and audio files in `<appDir>/offline_downloads/`.

#### Scenario: App restarts with existing downloads

- **WHEN** the app starts
- **THEN** the system reads Hive box to restore downloaded song metadata
- **THEN** the system marks all previously downloaded songs as downloaded

### Requirement: Downloaded songs play from local file

The playback system SHALL prefer local downloaded files over streaming URLs.

#### Scenario: Song is downloaded and user plays it

- **WHEN** user plays a song that is downloaded
- **THEN** the system uses the local file path instead of the streaming URL
- **THEN** playback works without internet connectivity

#### Scenario: Downloaded file is missing from disk

- **WHEN** user plays a song marked as downloaded
- **THEN** the system checks if the file exists on disk
- **THEN** if the file is missing, the system falls back to streaming URL
- **THEN** the system removes the stale download metadata

### Requirement: Download progress is visible

The system SHALL show real-time download progress percentage.

#### Scenario: Downloading with progress indicator

- **WHEN** a download is in progress
- **THEN** the UI SHALL display a circular progress indicator
- **THEN** the progress indicator SHALL update in real-time as bytes are received

### Requirement: Concurrent download limit

The system SHALL limit concurrent downloads to prevent network saturation.

#### Scenario: User starts multiple downloads

- **WHEN** user starts downloading songs while others are in progress
- **THEN** the system SHALL queue additional downloads
- **THEN** queued downloads SHALL start automatically when an active download completes
