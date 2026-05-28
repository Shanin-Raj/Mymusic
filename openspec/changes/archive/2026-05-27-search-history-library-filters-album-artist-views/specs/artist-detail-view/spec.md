## ADDED Requirements

### Requirement: Artist Detail View Layout
The application SHALL provide a dedicated dynamic screen for viewing artist details, styled with a high-fidelity blue-to-black background gradient: `[const Color(0xFF1E3264), const Color(0xFF14142B), const Color(0xFF121212)]`. It MUST show a circular profile image, the artist's name in a large bold Montserrat header, and a list of all songs contributed to by that artist.

#### Scenario: User navigates to artist detail
- **WHEN** the user selects an artist in their library
- **THEN** the application transitions to the custom Artist detail screen, displaying the corresponding profile picture, bold artist title, and a list of all their songs filtered dynamically from Firebase.

### Requirement: Artist Shuffle Playback
The Artist detail screen SHALL include a green play/shuffle button which, when pressed, triggers shuffled playback of all songs contributed to by this specific artist.

#### Scenario: Shuffling artist tracks
- **WHEN** the user taps the play/shuffle button on the Artist screen
- **THEN** the audio player starts playing the first track of a randomized queue containing only this artist's songs.
