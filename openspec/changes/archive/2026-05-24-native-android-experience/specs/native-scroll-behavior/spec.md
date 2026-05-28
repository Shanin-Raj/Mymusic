## ADDED Requirements

### Requirement: Native Scrolling Constraint
The system SHALL establish CSS constraints on the root document that disable the default browser pull-to-refresh behavior, ensuring the application feels like a native mobile app without accidental reloads.

#### Scenario: User swipes down from top of application
- **WHEN** the user performs a downward swipe gesture from the absolute top of the screen
- **THEN** the browser SHALL NOT trigger a page refresh
- **AND** the application UI SHALL remain perfectly static without showing a loading spinner or reloading audio state
