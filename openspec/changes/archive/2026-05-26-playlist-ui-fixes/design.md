## Context

The current playlist screen (likely `flutter_app/lib/screens/playlist_screen.dart` or similar) displays both a play and a shuffle button, which is redundant. Furthermore, there's a layout bug hiding the top content under the app bar, and a state/logic bug where the shuffle button does not always start playback from the first song in the shuffled list, or sometimes fails to shuffle entirely.

## Goals / Non-Goals

**Goals:**
- Remove the redundant Play button from the playlist header.
- Ensure the Shuffle button correctly shuffles the playlist and initiates playback starting with the first song of the newly shuffled list.
- Fix UI padding/margin issues causing the top of the playlist to be hidden beneath the top navigation bar.
- Add visual padding between the top controls (Shuffle button) and the first song in the list.

**Non-Goals:**
- Redesigning the entire playlist view.
- Changing the underlying audio player package or architecture.
- Modifying how playlists are fetched or saved.

## Decisions

- **UI Adjustments:** We will modify the playlist view's widget tree. We will remove the Play button widget and only keep the Shuffle button widget. We will add a `SizedBox` or padding above the list view to push it down below the navigation bar, and another padding widget between the shuffle button and the list of songs.
- **Shuffle Logic:** We will review `playlist_provider.dart` or `audio_handler.dart` to ensure that when `shuffle()` is called, the audio queue is shuffled, the current index is reset to 0, and playback starts from that new index. If the shuffle logic is already present, we will fix the bug preventing it from working consistently.

## Risks / Trade-offs

- **Risk**: Modifying the shuffle logic might affect shuffle behavior elsewhere (e.g., in the main player screen).
  - **Mitigation**: We will ensure changes to the shuffle behavior are isolated to the playlist-level initiation, or if they are in the shared audio handler, they are tested to not break normal shuffle toggling during playback.
