## Why

During music playback, high-frequency position ticks from the audio player were triggering global state invalidation and rebuilding the entire application widget tree up to 10 times a second. This constant layout-level and paint-level thrashing resulted in visible screen-wide and image flickering on both local devices and compiled builds. To resolve this issue, we must isolate position stream notifications from global state propagation.

## What Changes

- **Isolate Position Stream from State Invalidation**: Removed `notifyListeners()` from the position stream listener in `PlayerProvider`. The player's active position continues to update privately, but no longer invalidates the global application state.
- **Maintain Reactive Local Seek Bars**: Position streams continue to connect directly to seek bars and progress indicators inside `MiniPlayer` and `FullScreenPlayer` using localized `StreamBuilder` widgets, preserving smooth real-time progress updates.

## Capabilities

### New Capabilities
<!-- None: Refines existing playback states -->

### Modified Capabilities
- `playback-responsiveness`: Ensures playback updates are localized and do not cause global application-level UI thrashing or flickering.

## Impact

- **d:/music/flutter_app/lib/providers/player_provider.dart**: Refactored the `_init` method to update position privately without invoking `notifyListeners()`.
