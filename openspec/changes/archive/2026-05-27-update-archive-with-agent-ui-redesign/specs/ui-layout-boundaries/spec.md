## MODIFIED Requirements

### Requirement: Global Safe Area Constraints
The application UI MUST respect the device's safe areas (status bar at the top, navigation bar at the bottom) to prevent content overlap. The bottom navigation shell MUST wrap padding around the bottom safe area while matching the application surface background color to ensure the system navigation bar zone has a solid, cohesive appearance. Additionally, list/carousel containers for content cards (e.g. `MixCard`) MUST have a height of at least `240` to avoid typographic vertical clipping of multi-line text (e.g., artist names).

#### Scenario: App rendering on devices with notches or system navigation bars
- **WHEN** the application is launched on a device with a system status bar or gesture navigation bar
- **THEN** the main layout must be constrained between these safe areas so that no UI elements (such as the now playing bar) are rendered underneath the system UI.

#### Scenario: Bottom navigation safe area coloring
- **WHEN** the bottom navigation bar is rendered on an edge-to-edge system navigation device
- **THEN** the system navigation bar background color matches the bottom navigation container background, preventing translucent content overlap.

#### Scenario: Content card height limits
- **WHEN** a Carousel of cards with multiple lines of text is displayed
- **THEN** the carousel height must be set to at least 240, ensuring that all header and metadata text lines are fully visible without clipping.
