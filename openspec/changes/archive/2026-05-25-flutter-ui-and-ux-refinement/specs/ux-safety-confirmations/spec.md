## ADDED Requirements

### Requirement: Destructive Action Confirmation
The system SHALL display a modal confirmation dialog when a user initiates a destructive action, such as deleting a track from the library or removing a song from a playlist.

#### Scenario: User swipes to delete
- **WHEN** the user performs a swipe-to-delete gesture on a track
- **THEN** the system SHALL NOT delete the track immediately
- **AND** SHALL display a dialog asking "Are you sure you want to delete this track?" with "Cancel" and "Delete" options

#### Scenario: User confirms deletion
- **WHEN** the user selects "Delete" in the confirmation dialog
- **THEN** the system SHALL proceed with the deletion and show a success toast
