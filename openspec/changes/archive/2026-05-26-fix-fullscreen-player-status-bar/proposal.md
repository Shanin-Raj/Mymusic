## Why

The previous `fix-ui-boundaries-and-loading` change resolved safe area issues for the main screen layout, but the full-screen now playing player (`FullScreenPlayer`) still renders its content behind the system status bar. When the user opens the now playing view, the album art, controls, and text are drawn underneath the status bar, making them partially obscured.

## What Changes

- Remove `extendBodyBehindAppBar: true` from the `FullScreenPlayer`'s `Scaffold` and/or wrap its body in a `SafeArea` to constrain content below the status bar.
- Ensure proper status bar styling (icon brightness, color) when the full-screen player is visible.

## Capabilities

### New Capabilities
- `fullscreen-player-safe-area`: Handles the safe area constraints and status bar styling specifically for the full-screen now playing view.

### Modified Capabilities

## Impact

- `main_screen.dart`: The `FullScreenPlayer` widget's layout constraints.
