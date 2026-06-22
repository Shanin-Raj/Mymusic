## ADDED Requirements

### Requirement: System auto-detects network connectivity

The system SHALL use connectivity_plus to monitor network status changes.

#### Scenario: Network becomes available

- **WHEN** the device connects to a network
- **THEN** the system emits an online event
- **THEN** the full song catalog is displayed

#### Scenario: Network becomes unavailable

- **WHEN** the device loses network connectivity
- **THEN** the system emits an offline event
- **THEN** the UI switches to show only downloaded songs

### Requirement: UI shows offline indicator

The system SHALL display a visual indicator when in offline mode.

#### Scenario: Offline mode is active

- **WHEN** the app is in offline mode
- **THEN** a banner or chip SHALL appear indicating "Offline Mode"
- **THEN** the indicator SHALL be visible on all screens

#### Scenario: Online mode is restored

- **WHEN** the app transitions from offline to online
- **THEN** the offline indicator SHALL disappear
- **THEN** the full song catalog SHALL be restored

### Requirement: Content is filtered in offline mode

When offline, the system SHALL only show songs that are available for offline playback.

#### Scenario: Browsing in offline mode

- **WHEN** the app is offline and user views the home screen
- **THEN** only downloaded songs SHALL be shown
- **THEN** a message explaining offline mode SHALL be visible

#### Scenario: Searching in offline mode

- **WHEN** the app is offline and user searches for songs
- **THEN** results SHALL be filtered to downloaded songs only

#### Scenario: Viewing library in offline mode

- **WHEN** the app is offline and user views the library
- **THEN** only playlists/artists/albums containing downloaded songs SHALL be shown

### Requirement: Downloaded songs are playable offline

The system SHALL enable full playback of downloaded songs without any network connection.

#### Scenario: Playing a downloaded song offline

- **WHEN** the app is offline
- **WHEN** user taps a downloaded song
- **THEN** the song SHALL play from the local file
- **THEN** all transport controls (play, pause, seek, next, previous) SHALL work normally

#### Scenario: Attempting to play non-downloaded song offline

- **WHEN** the app is offline
- **WHEN** user taps a non-downloaded song
- **THEN** the system SHALL show an error message indicating no internet connection
- **THEN** the app SHALL NOT attempt to stream the song
