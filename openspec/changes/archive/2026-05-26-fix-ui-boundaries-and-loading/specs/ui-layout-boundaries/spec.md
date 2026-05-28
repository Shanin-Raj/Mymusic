## ADDED Requirements

### Requirement: Global Safe Area Constraints
The application UI MUST respect the device's safe areas (status bar at the top, navigation bar at the bottom) to prevent content overlap.

#### Scenario: App rendering on devices with notches or system navigation bars
- **WHEN** the application is launched on a device with a system status bar or gesture navigation bar
- **THEN** the main layout must be constrained between these safe areas so that no UI elements (such as the now playing bar) are rendered underneath the system UI.
