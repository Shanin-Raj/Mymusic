## Why

The full-screen player's top content (AppBar with back button and title) overlaps with the system status bar instead of being correctly inset below it. This is because `AnnotatedRegion` sets `statusBarColor: Colors.transparent` (triggering edge-to-edge layout), but the `SafeArea` is only applied to the body content — the `AppBar` region itself lacks proper safe area handling, causing it to sit behind the status bar.

## What Changes

- Move the `SafeArea` to wrap the entire full-screen player widget (including the `AppBar`), instead of only the body content.
- Remove `extendBody: true` from the `Scaffold` since it's not needed and may interfere with correct safe area insets.

## Capabilities

### New Capabilities
- `fullscreen-safe-area-statusbar`: Ensures the entire full-screen player layout (AppBar and body) is properly inset below the system status bar without overlapping.

### Modified Capabilities

## Impact

- `lib/screens/main_screen.dart`: Adjust the `SafeArea` position and remove `extendBody: true` in the `FullScreenPlayer` widget.
