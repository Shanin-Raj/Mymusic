## MODIFIED Requirements

### Requirement: Full-Screen Native Mode
The system SHALL support launching in a native "Standalone" mode that completely removes all browser chrome (URL bars, navigation buttons) and prevents fallback UI, ensuring the PWA perfectly bounds to Android system UI insets when opened from the home screen.

#### Scenario: App Launch
- **WHEN** the user taps the app icon on an Android device
- **THEN** the system SHALL load the PWA in a full-screen view identical to a native application
- **AND** the browser SHALL NOT render any fallback address bar or top UI chrome under any scrolling condition
