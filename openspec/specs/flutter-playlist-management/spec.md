# flutter-playlist-management Specification

## Purpose
Handles playlist creation, modification, and display within the Flutter application.
## Requirements
### Requirement: Add Songs to Playlist from Detail View
The system SHALL provide a button within the playlist detail view to add songs to that specific playlist.

#### Scenario: User clicks "Add Songs"
- **WHEN** the user is viewing a playlist's details
- **AND** clicks the "Add Songs" button
- **THEN** the system SHALL present a selection UI with all available library songs

### Requirement: Reactive Playlist Updates
The system SHALL ensure the playlist detail view updates immediately when a song is added to it, without requiring an application restart. The UI SHALL be synchronized with the underlying state provider to reflect changes in real-time.

#### Scenario: Song added to playlist
- **WHEN** a song is added to the current playlist
- **THEN** the track list in the playlist detail view SHALL refresh immediately to include the new song
- **AND** the change SHALL be reflected across all views displaying that playlist

### Requirement: Custom Cover Image Selection
The system SHALL display a selection of custom cover images during playlist creation. Users MUST be able to preview and pick from local files served by the backend's image endpoint, highlighting the selected thumbnail.

#### Scenario: Choose a cover image
- **WHEN** the user opens the "New Playlist" form
- **THEN** the form dynamically lists available cover images
- **WHEN** the user selects one and taps "Create"
- **THEN** the new playlist is saved with the chosen cover image

### Requirement: Playlist Deletion
The system SHALL provide a delete option inside the playlist details view. Tapping this option MUST request user confirmation via a modal dialog and delete the playlist record from the system on approval.

#### Scenario: Confirm and delete playlist
- **WHEN** the user is inside a playlist detail view and taps "Delete"
- **AND** confirms the deletion in the prompt dialog
- **THEN** the playlist is deleted and the user is redirected back to the library

### Requirement: Swipe-to-Remove Song
The playlist track list SHALL support swipe-to-dismiss functionality from right to left to remove a song from the active playlist. The system MUST confirm the action, informing the user that the track is only removed from the playlist but remains in the main song library.

#### Scenario: Swipe left to remove song
- **WHEN** the user swipes a song left on the playlist detail page
- **AND** clicks "Remove" on the confirmation prompt
- **THEN** the song is removed from the playlist and the list reactive updates immediately
- **AND** the song is NOT deleted from the library

### Requirement: Playlist UI Padding
The empty playlist detail placeholder page SHALL include safe bottom area padding so that the "ADD SONGS" action button is fully visible and not clipped by device boundaries or mini player widgets.

#### Scenario: Empty playlist display
- **WHEN** the user opens an empty playlist
- **THEN** the empty state controls and the "ADD SONGS" button are rendered with proper bottom padding safety

