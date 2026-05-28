## MODIFIED Requirements

### Requirement: Safe content padding
#### Scenario: Global navigation bar and player padding
- **WHEN** the application is rendered in edge-to-edge mode
- **THEN** the bottom-most interactive elements (specifically the custom `BottomNavigationBar` container) MUST include bottom padding equivalent to the system navigation bar inset.
