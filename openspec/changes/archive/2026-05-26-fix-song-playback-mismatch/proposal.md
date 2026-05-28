## Why

When a user taps a song to play it, the UI shows the correct cover art and title, but a different song's audio plays. This happens because `SonicAudioHandler.updateQueue()` clears the `_playlist` audio source and adds new sources asynchronously, but updates the `queue` notifier (`queue.add(newQueue)`) *after* the audio sources are rebuilt. During the window between clearing and rebuilding, the player's `currentIndexStream` fires with index 0, and the listener reads `queue.value[0]` from the **old** queue — causing `_currentSong` to be overwritten with the wrong media item.

## What Changes

- Reorder `SonicAudioHandler.updateQueue()` to update `queue.add(newQueue)` synchronously at the beginning, before any async operations, so the queue notifier always reflects the correct list when the player's current index changes.
- Ensure the same fix in `addQueueItems()` if it has a similar race.

## Capabilities

### New Capabilities
- `queue-atomicity`: Defines that queue updates must be atomic — the `queue` notifier must reflect the new list before the audio player's sources are modified.

### Modified Capabilities

## Impact

- `audio_handler.dart`: Fix the race condition in `updateQueue()` by moving `queue.add()` before `_playlist.clear()`.
