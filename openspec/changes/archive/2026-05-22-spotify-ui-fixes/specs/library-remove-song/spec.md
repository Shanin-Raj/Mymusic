## ADDED Requirements

### Requirement: Permanent Song Removal
The application MUST allow users to completely delete a song from their vault. This action MUST delete the record from the database and the physical audio file from Telegram.

#### Scenario: User deletes a song from the library
- **WHEN** the user clicks the "Remove" icon on a track in the Library
- **THEN** the system prompts for confirmation
- **WHEN** the user confirms
- **THEN** the song is permanently removed from the application and Telegram
