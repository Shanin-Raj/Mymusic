## 1. Fix Queue Atomicity in updateQueue

- [x] 1.1 In `SonicAudioHandler.updateQueue()`, move `queue.add(newQueue)` to execute before `_playlist.clear()` — this ensures the `queue` notifier reflects the new list before any audio player index changes that listeners react to.
