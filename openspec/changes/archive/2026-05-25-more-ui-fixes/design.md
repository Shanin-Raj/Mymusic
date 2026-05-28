## Context

The Flutter app currently has a few lingering UX issues. The shuffle functionality needs to properly communicate with the `audio_service` queue. The playlist view lacks a direct way to add songs and doesn't re-fetch or update its state when a song is added from elsewhere. Lastly, the manual add song UI is obsolete due to the backend CLI tools (`main.js`, `manual_add.js`).

## Goals / Non-Goals

**Goals:**
- Fix shuffle queue randomization.
- Add an "Add Songs" button to `PlaylistDetailView` (or equivalent).
- Ensure `PlaylistDetailView` state updates when songs are added.
- Remove the manual add song button/form from the app.

## Decisions

- **Decision 1: Use `AudioService.setShuffleMode`**
  - *Rationale*: We must ensure the shuffle command actually updates the `AudioService` queue, not just local UI state.
- **Decision 2: Reactive Playlist State**
  - *Rationale*: When a song is added to a playlist via the library, we need to either re-fetch the playlist or update the local provider state so the `PlaylistDetailView` updates instantly.
- **Decision 3: "Add Songs" button in Playlist**
  - *Rationale*: A button at the bottom (or top) of the playlist track list that opens a bottom sheet or navigates to a selection screen to add existing library songs to the playlist.
- **Decision 4: Remove Manual Add**
  - *Rationale*: Just delete the FAB or button triggering the `ManualAddDialog`.

## Risks / Trade-offs

- **Risk**: Shuffle logic might conflict with contextual playback (playing a specific song in a list).
- **Mitigation**: Ensure shuffle creates a new shuffled queue but keeps the currently playing song at index 0.
