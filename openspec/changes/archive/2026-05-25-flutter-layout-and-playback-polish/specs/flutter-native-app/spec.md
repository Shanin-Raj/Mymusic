## MODIFIED Requirements

### Requirement: Native Flutter Application Skeleton
The system SHALL provide a fully native Flutter application skeleton that mirrors the current HTML/CSS PWA structure, using a centralized `ThemeData` to perfectly match the existing visual identity. The application SHALL be optimized for portrait orientation and correctly handle system UI elements, including the top status bar and bottom navigation bar, ensuring the app content does not overlap with system controls or indicators.

#### Scenario: App Initialization
- **WHEN** the user launches the Flutter app
- **THEN** the app SHALL present the same login and home feed screens as the current PWA
- **AND** the app SHALL communicate with the existing Firebase and Node.js backend seamlessly

#### Scenario: System Bar Handling
- **WHEN** the app is running on a device with a status bar or navigation bar
- **THEN** the layout SHALL reserve space for these elements to prevent content overlap
- **AND** the app background SHALL extend appropriately behind them if immersive mode is used
