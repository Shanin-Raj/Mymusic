## MODIFIED Requirements

### Requirement: Global Safe Area Constraints
#### Scenario: Main navigation bar and mini player visibility
- **WHEN** the user navigates between the main tabs (Home, Search, Library)
- **THEN** the `bottomNavigationBar` and the `MiniPlayer` widget MUST be rendered within the device's safe area, ensuring they are not obscured by the system's gesture navigation bar or hardware buttons.
