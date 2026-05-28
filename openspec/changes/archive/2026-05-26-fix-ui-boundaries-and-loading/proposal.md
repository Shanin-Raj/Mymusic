## Why

The application currently suffers from UI layout issues on devices with safe areas (notches, status bars, navigation bars), causing elements like the "now playing" bar to be hidden under the bottom navbar. Additionally, there is a severe performance issue where the UI takes too long to load/update after a song begins playing. These issues degrade the user experience and make the app feel unresponsive and visually broken.

## What Changes

- Add safe area boundaries (top and bottom) to ensure the application UI respects device screen ratios and avoids overlapping with system UI elements (status bar, bottom navbar).
- Fix the layout constraints so that the app correctly fits between the system status bar and navigation bar, instead of using transparent overlays that hide content.
- Investigate and resolve the performance bottleneck occurring immediately after a song starts playing that causes the UI to hang or load indefinitely.

## Capabilities

### New Capabilities
- `ui-layout-boundaries`: Defines safe area handling and responsive screen ratio constraints for the main application view.
- `playback-responsiveness`: Decouples audio player initialization from the immediate UI update to prevent prolonged loading states.

### Modified Capabilities

## Impact

- Main application layout components (likely the root wrapper or main scaffold).
- The "Now Playing" bar layout and positioning.
- Audio playback state management and its corresponding UI update lifecycle.
