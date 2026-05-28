# Full-Screen Player Layout Optimization

## Purpose

Optimize the full-screen player layout to maximize screen real estate for essential controls and information by reducing unnecessary spacing.

## Requirements

### Requirement: Full-Screen Player Layout Spacing

The full-screen player MUST have a minimal and optimized top spacing between the app bar and the album art to maximize screen real estate for track information, progress slider, and playback buttons.

#### Scenario: Verify layout spacing above the album art

- **WHEN** the user opens the full-screen player
- **THEN** the spacing between the app bar and the top of the album art container MUST be minimal (using a small fixed vertical margin instead of an expansive Spacer) to increase the visibility of the playback controls at the bottom of the screen.
