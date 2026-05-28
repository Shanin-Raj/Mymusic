## Why

The full-screen music player has excessive top padding/margin above the album art, which pushes down critical UI elements (such as song titles, progress sliders, and control buttons) and reduces their overall visibility. Decreasing this top spacing to align with standard music player designs (like Image 2) optimizes screen utilization, making playback controls more accessible and visually balanced.

## What Changes

- Reduce the top spacing/padding within the `FullScreenPlayer` body content.
- Restructure the top area layout so that the album art is positioned higher, maximizing screen real estate for player controls.
- Maintain consistent status bar integration using safe area spacing.

## Capabilities

### New Capabilities
- `fullscreen-player-layout-optimization`: Ensures the full-screen player layout has optimized spacing, with the album art correctly elevated and maximum screen space dedicated to playback controls.

### Modified Capabilities

## Impact

- `lib/screens/main_screen.dart`: Modify padding/margin parameters around the `FullScreenPlayer`'s top widgets and layout container.
