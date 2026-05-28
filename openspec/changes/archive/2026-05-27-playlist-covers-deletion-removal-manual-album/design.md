## Context

To make the playlist feature set complete and premium, we decided to:
- Expose an API endpoint `GET /api/images` that reads all files in the images folder and exposes them.
- Introduce a cover selector widget in the new playlist creation dialog.
- Add a delete icon in the Appbar actions of the playlist detail view.
- Wrap song rows in the playlist detail view with `Dismissible` to allow swipe-to-remove.
- Clean up album-level grouping checks so `"Manual Addition"` behaves as a regular first-class album instead of being mapped to `"Spotify Songs"`.

## Goals / Non-Goals

**Goals:**
- Dynamically fetch and display custom covers inside the creation modal.
- Allow deletion of playlists.
- Support swipe-to-dismiss song removal from a playlist.
- Align empty-state padding at the bottom.
- Separate "Manual Addition" songs from "Spotify Songs".

**Non-Goals:**
- Adding song upload forms or library-level song deletions during swipe-to-remove.

## Decisions

- **Decision 1: GET /api/images backend endpoint**
  - *Choice*: Add GET `/api/images` route returning JSON arrays of cover images with absolute host paths.
  - *Rationale*: Safe, decoupled, and fast.
- **Decision 2: StatefulBuilder for AlertDialog cover previews**
  - *Choice*: Wrap AlertDialog content with StatefulBuilder to allow dynamic selection highlights without rebuilding the whole dialog hierarchy.
  - *Rationale*: High performance UI update.
- **Decision 3: Swipe left Dismissible confirmation**
  - *Choice*: Use `Dismissible.confirmDismiss` callback returning a Dialog prompt.
  - *Rationale*: Prevents accidental deletion of tracks.

## Risks / Trade-offs

- *Risk*: Empty images folder on server.
  - *Mitigation*: Fallback silently to empty array list; playlist creation still works without images.
