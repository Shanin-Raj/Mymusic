## Context

During audio playback, high-frequency position ticks from the audio player were triggering global state invalidation, causing constant layout invalidation and visible application-wide UI and image flickering. 

## Goals / Non-Goals

**Goals:**
- Eliminate screen-wide flickering by removing global state invalidation from position updates.
- Keep progress bars in `MiniPlayer` and `FullScreenPlayer` updating smoothly in real-time.

**Non-Goals:**
- Removing the capability to seek or update current song metadata.

## Decisions

- **Remove notifyListeners() from Position Stream Listener**:
  - *Decision*: Removed the global rebuild trigger `notifyListeners()` from the position change listener inside `PlayerProvider`. The private `_position` state is still updated, but does not invalidate the provider state.
  - *Rationale*: Rebuilding the entire widget tree 5-10 times a second is an anti-pattern that leads to severe layout thrashing and repaint issues. Localizing updates to seek sliders and progress indicators via direct `StreamBuilder` streams provides the perfect balance of high-frequency precision and premium rendering performance.

## Risks / Trade-offs

- **[Risk] Initial Stale Value** → If a widget relies on the getter `player.position` without a stream, it might show a stale value.
  - *Mitigation*: Handled by ensuring that all components that need real-time position updates connect directly to `player.positionStream` using standard `StreamBuilder` widgets, falling back safely to `player.position` only for initial data in the builder snapshot.
