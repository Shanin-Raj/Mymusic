## Why

The current playlist view has a few UI and UX issues that hinder the user experience. The play button is redundant and clutters the interface, the shuffle button behavior is inconsistent (sometimes not shuffling, or not starting with the first song), and there is a layout issue where the top of the playlist content is hidden underneath the top navigation bar. Addressing these issues will make the playlist view cleaner and ensure playback functions as expected.

## What Changes

- Remove the Play button from the playlist view entirely.
- Ensure only the Shuffle button is displayed for playback controls.
- Add padding between the first song in the playlist and the shuffle button.
- Fix shuffle playback logic: when shuffle is pressed, it must always start with the first song in the list.
- Fix bug: ensure songs actually shuffle when the shuffle button is pressed.
- Fix layout issue: Adjust the top padding/margin of the playlist view so it is not hidden behind the top navigation bar.

## Capabilities

### New Capabilities
- `playlist-ui-refinement`: Adjusts the playlist UI layout, replaces play with shuffle-only controls, and resolves shuffle playback behavior issues.

### Modified Capabilities

## Impact

- `flutter_app/lib/screens/playlist_screen.dart` (or equivalent playlist UI file): Layout, padding, and button changes.
- `flutter_app/lib/providers/playlist_provider.dart` and `flutter_app/lib/services/audio_handler.dart`: Shuffle logic adjustments.
