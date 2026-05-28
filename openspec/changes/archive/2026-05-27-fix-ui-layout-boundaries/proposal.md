## Why

The recent Spotify UI redesign introduced layout regressions where application content overlaps with the transparent system navigation bar at the bottom and the status bar at the top (specifically on the Now Playing screen). This impacts usability and visual integrity by obscuring interactive elements and metadata.

## What Changes

- Adjust the global application shell to respect bottom safe area insets, ensuring the navigation bar and mini player are fully visible above the system navigation bar.
- Refactor the Full Screen Now Playing view to properly account for the top status bar height and safe area, preventing content overlap with system icons.
- Standardize safe area management across all primary screens (Home, Search, Library) to ensure consistent padding from system UI elements.

## Capabilities

### New Capabilities
<!-- No new capabilities, focusing on fixing existing layout logic -->

### Modified Capabilities
- `ui-layout-boundaries`: Update requirements to strictly enforce safe area insets for both status bar and navigation bar.
- `fullscreen-player-safe-area`: Refine requirements to ensure the player UI (especially the top collapse button and metadata) avoids status bar occlusion.
- `ui-edge-to-edge`: Clarify that edge-to-edge rendering must still preserve interactive zones through proper use of `SafeArea` or calculated insets.

## Impact

- **UI/UX**: Improved readability and touch target accessibility for the navigation bar and player controls.
- **Main Screen**: Adjustments to `Scaffold` and `SafeArea` wrapping in `lib/screens/main_screen.dart`.
- **Now Playing**: Padding/Margin adjustments in `FullScreenPlayer` widget.
- **System Overlay**: Potential tweaks to `SystemUiOverlayStyle` to ensure high-contrast visibility of system icons.
