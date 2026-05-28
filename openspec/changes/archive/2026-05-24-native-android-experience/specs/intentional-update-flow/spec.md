## ADDED Requirements

### Requirement: Intentional App Update Trigger
The system SHALL provide a UI mechanism to detect and apply application updates, ensuring that users can transition to a new version of the app without relying on browser-native pull-to-refresh gestures.

#### Scenario: Service Worker update detected
- **WHEN** a new Service Worker version is found and reaches the `waiting` state
- **THEN** the system SHALL display a non-intrusive "New Version Available" notification or button in the UI
- **AND** the system SHALL NOT force an immediate reload that would interrupt current audio playback

#### Scenario: User clicks update button
- **WHEN** the user taps the "Update" or "Refresh App" button
- **THEN** the system SHALL trigger a full page reload (`window.location.reload()`) to activate the new version
- **AND** the system SHALL clear any temporary playback state if necessary to ensure the new code executes cleanly
