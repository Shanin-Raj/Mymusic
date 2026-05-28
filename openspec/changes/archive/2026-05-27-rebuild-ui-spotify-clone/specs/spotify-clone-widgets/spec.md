## ADDED Requirements

### Requirement: Extract and Adapt Clone Widgets
The system SHALL import and adapt the pure UI presentation widgets from the `Mohammad-Nikmard/Spotify-Clone` repository. These widgets SHALL be decoupled from their original state management (BLoC) and refactored to consume the application's existing `Provider` based state management.

#### Scenario: Extracting a widget
- **WHEN** a UI component (e.g., a music card) is needed
- **THEN** the component SHALL be copied from the clone repository, stripped of BLoC dependencies, and updated to accept data via constructors or Provider.
