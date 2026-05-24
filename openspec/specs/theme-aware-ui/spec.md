# theme-aware-ui Specification

## Purpose
TBD - created by archiving change fix-darkmode-switching. Update Purpose after archive.
## Requirements
### Requirement: Theme-Aware Input Fields
Input fields in the Add Music screen and modals SHALL use `var(--surface)` for their background to adapt to theme switching.

#### Scenario: Inputs visible in light mode
- **WHEN** the app is in light mode
- **THEN** input fields in the Create/Add screen have a visible light background rather than a dark `#282828` background

