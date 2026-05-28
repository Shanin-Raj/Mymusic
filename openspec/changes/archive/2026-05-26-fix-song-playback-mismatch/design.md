## Context

`SonicAudioHandler.updateQueue()` currently orders operations as:

1. `_playlist.clear()` (async — resets audio player, fires `currentIndexStream`)
2. Build audio sources
3. `_playlist.addAll(sources)` (async — adds sources, fires `currentIndexStream` with index 0)
4. `queue.add(newQueue)` (sync — updates the queue notifier)

Steps 1 and 3 trigger the player's `currentIndexStream` listener, which reads `queue.value[index]`. But at that point `queue.value` still holds the **old** queue (step 4 hasn't run yet). This causes the wrong `MediaItem` to be emitted via `appMediaItemStream`, overwriting `_currentSong` in `PlayerProvider`.

## Goals / Non-Goals

**Goals:**
- Fix the race where `queue.value` is read while holding stale data during `updateQueue()`.
- Prevent wrong song metadata from being emitted to the UI during queue transitions.
- Keep the fix minimal — no architectural changes.

**Non-Goals:**
- Rewriting queue management or audio handler logic.
- Changing `PlayerProvider` or UI code.

## Decisions

1. **Reorder `updateQueue()` — queue notifier first:**
   - **Decision:** Move `queue.add(newQueue)` to the very first line of the method body, before any `await` calls.
   - **Rationale:** `queue.add` is synchronous (just updates a `ValueNotifier`), so it's safe to call immediately. Any subsequent `currentIndexStream` events will read the correct queue. This is a one-line move with zero risk.

2. **Scope of fix:**
   - **Decision:** Only fix `updateQueue()`. `addQueueItems()` is used for appending (not replacing) and doesn't reset the player index — no race there.
   - **Rationale:** The race only exists when the queue is replaced wholesale and `_playlist.clear()` is called.

## Risks / Trade-offs

- [Risk] If `updateQueue()` throws after updating `queue.value` but before the sources are built, `queue.value` would be out of sync with the audio player.
  → **Mitigation:** The `Error` catch in `PlayerProvider.playSong` will handle this. The discrepancy is temporary — on the next successful play, both will realign. This risk existed before (just in the opposite direction).
