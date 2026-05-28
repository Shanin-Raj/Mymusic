# Queue Atomicity

## Purpose
Ensures that the application's internal queue and the audio player's playlist state remain synchronized and atomic.

## Requirements

### Requirement: Queue Notifier Atomicity
The `queue` notifier MUST be updated to reflect the new list of media items before any async operation that modifies the audio player's internal playlist. This ensures that any listener reacting to player index changes reads the correct queue.

#### Scenario: Successful queue replacement
- **WHEN** `updateQueue(newQueue)` is called with a new list of `MediaItem`s
- **THEN** the `queue` notifier MUST reflect the new list before `_playlist.clear()` or `_playlist.addAll()` are called.
