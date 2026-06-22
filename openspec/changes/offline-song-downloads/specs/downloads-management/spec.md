## ADDED Requirements

### Requirement: User can view all downloaded songs

The system SHALL provide a dedicated screen listing all downloaded songs.

#### Scenario: Navigating to downloads screen

- **WHEN** user taps the "Downloads" option in Settings
- **THEN** the system navigates to the Downloads screen
- **THEN** all downloaded songs SHALL be displayed in a list

#### Scenario: Downloaded song list displays metadata

- **WHEN** the Downloads screen is displayed
- **THEN** each song SHALL show its title, artist, album artwork, and download date
- **THEN** each song SHALL be tappable to play it

### Requirement: User can see storage usage

The Downloads screen SHALL display total storage consumed by downloads.

#### Scenario: Viewing storage usage

- **WHEN** the Downloads screen is displayed
- **THEN** the top of the screen SHALL show total storage used by downloaded songs
- **THEN** the storage SHALL be formatted in human-readable units (KB, MB, GB)

### Requirement: User can delete individual downloads

The system SHALL allow users to remove individual downloaded songs from the Downloads screen.

#### Scenario: Swiping to delete a download

- **WHEN** user swipes left on a downloaded song
- **THEN** a delete action SHALL be revealed
- **THEN** when tapped, the system SHALL delete the audio file and metadata
- **THEN** the storage usage SHALL update

#### Scenario: Tapping delete icon on a download

- **WHEN** user taps the delete icon on a song in the Downloads screen
- **THEN** a confirmation dialog SHALL appear
- **THEN** when confirmed, the system SHALL delete the audio file and metadata
- **THEN** the storage usage SHALL update

### Requirement: User can clear all downloads

The Downloads screen SHALL provide a "Clear All" option.

#### Scenario: Clearing all downloads

- **WHEN** user taps "Clear All" in the Downloads screen
- **THEN** a confirmation dialog SHALL appear showing total storage to be freed
- **THEN** when confirmed, the system SHALL delete all downloaded audio files and metadata
- **THEN** the Downloads screen SHALL show an empty state

### Requirement: Downloads screen shows empty state

When no songs are downloaded, the screen SHALL display an appropriate empty state.

#### Scenario: No downloads yet

- **WHEN** the Downloads screen is displayed and no songs are downloaded
- **THEN** an illustration and message SHALL appear indicating no downloads yet
- **THEN** a button to explore songs SHALL be available
