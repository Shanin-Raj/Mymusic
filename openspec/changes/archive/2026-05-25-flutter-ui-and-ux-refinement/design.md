## Context

The Flutter application is currently in active development. While core features exist, there are several UX friction points. The "Safar" playback bug is particularly disruptive as it forces users to manually skip the first track every time they start a new song. The lack of deletion confirmations leads to accidental loss of synced tracks. Playlist management is one-way (users can see them but not populate them).

## Goals / Non-Goals

**Goals:**
- Implement a modal confirmation for swipe-to-delete.
- Fix the `PlayerProvider` to correctly handle the initial playback index.
- Refactor `SearchView` to hide results until a user initiates a query.
- Implement a functional "Add to Playlist" UI component.
- General UI polish to match the Spotify reference app more closely.

**Non-Goals:**
- Changing the backend API.
- Re-architecting the `audio_service` implementation (just fixing the data being sent to it).
- Removing development mode configurations.

## Decisions

- **Decision 1: Use `showDialog` for Deletion Confirmation**
  - *Rationale*: Standard material design pattern that provides a clear "Stop and Think" moment for destructive actions.
  - *Implementation*: Integrate `confirmDismiss` callback in the `Dismissible` widget.

- **Decision 2: Refactor `PlayerProvider.playSong` to accept an `initialIndex`**
  - *Rationale*: The current implementation likely defaults to index 0. By explicitly passing the index of the tapped song, we ensure immediate and correct playback.
  
- **Decision 3: "Start browsing" Category Grid**
  - *Rationale*: Replicates the Spotify search experience where the default state is an inviting grid of categories (Music, Podcasts, Live Events, etc.) rather than a blank screen.
  - *Implementation*: When the search query is empty in `SearchView`, render a `GridView.builder` with colorful rectangular containers (using gradients/colors) angled images, and text. Wrapping them in `GestureDetector` or `InkWell` to navigate to placeholder playlist screens later.

- **Decision 4: "Add to Playlist" Context Menu**
  - *Rationale*: Lowers UI clutter by hiding playlist selection until specifically requested.
  - *Implementation*: A bottom sheet or popup menu attached to each track card.

## Risks / Trade-offs

- **Risk: Index mismatch when filtering** → *Mitigation*: Ensure the `playSong` method uses the filtered list as the new queue context.
- **Risk: Deletion confirmation adding too much friction** → *Mitigation*: Only show for library/playlist deletions, not for non-destructive actions.

## Migration Plan

1. Update `PlayerProvider` to fix the index bug.
2. Update `Dismissible` widgets with confirmation logic.
3. Refactor `SearchView` logic.
4. Implement the "Add to Playlist" service and UI.
5. Perform a general UI polish pass.
