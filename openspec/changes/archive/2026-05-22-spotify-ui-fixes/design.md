## Context

Following the transition to a Spotify-style layout, the UI currently suffers from uneven background colors and gradient mismatches. Additionally, users are encountering a "Failed to connect to server" error when trying to add new music. From a UX perspective, a dedicated "Create" tab is unnecessary. Instead, the add music functionality can be moved to the "Library" tab, and users need explicit features to delete songs both globally (from the vault/Telegram) and locally (from specific playlists).

## Goals / Non-Goals

**Goals:**
- Fix the CSS theme tokens to perfectly match Spotify's `#191414` background and resolve any gradient issues.
- Debug and fix the `/api/add-song` endpoint connection error.
- Remove the "Create" nav tab and move the "Add Music" trigger to a `+` icon in the Library header.
- Implement permanent song deletion (Firestore + Telegram) from the library with a confirmation dialog.
- Implement playlist-specific song removal.

**Non-Goals:**
- Completely rewriting the backend logic for `addSong`, only fixing the specific error causing the connection failure.

## Decisions

- **Color Standardization**: We will enforce `--bg: #191414` globally and remove or adjust any hardcoded linear gradients in `index.html` or `styles.css` that fade into black or other off-colors.
- **Add Music Bug**: The error "Failed to connect to server" suggests the backend might be crashing during the add operation or the request is timing out. During implementation, we will inspect `adder.js` and `server.js` to add better error handling and fix the root cause.
- **Global Delete Implementation**:
  - We will add a new `DELETE /api/songs/:id` endpoint to `server.js`.
  - It will remove the song document from Firebase.
  - It will use the Telegram client to delete the corresponding message from the Telegram channel (to free up storage and fully remove the song).
  - The frontend will show a native `confirm()` dialog before calling this endpoint.
- **Playlist Remove Implementation**:
  - We will add a `DELETE /api/playlists/:id/songs/:songId` endpoint (or modify the existing add endpoint to handle removals).
  - It will simply remove the song ID from the `songs` array in the Firebase playlist document.
- **DOM Placement**: 
  - The `+` icon will be placed in the `.header-actions` div of the `#screen-library` header.
  - The delete icons will be added to the `.track-right` container of `.track-item` elements. We will use a trash can icon for global delete and a minus/remove icon for playlist removal.

## Risks / Trade-offs

- **Risk: Deleting from Telegram might fail.** If the Telegram message is already gone or the client is disconnected, the deletion might throw an error.
  - *Mitigation*: Wrap the Telegram deletion in a try/catch block and ensure we still delete the song from Firestore even if the Telegram deletion fails, to avoid orphaned UI records.
- **Risk: Breaking the playlist UI when removing songs.**
  - *Mitigation*: Ensure the frontend properly updates the `activePlaylist` object and re-renders the track list immediately after a successful removal.
