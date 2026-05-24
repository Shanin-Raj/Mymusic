## 1. CSS Color Standardization

- [x] 1.1 Update `--bg` variable in `styles.css` to `#191414`.
- [x] 1.2 Remove or update any background gradients in `styles.css` (e.g., `.screen` background gradients) that conflict with the solid `#191414` background.

## 2. Nav and Header Updates

- [x] 2.1 Remove the \"Create\" button from `#bottom-nav` in `index.html`.
- [x] 2.2 Add a `+` (add) icon to the `.header-actions` within `#screen-library` in `index.html`.
- [x] 2.3 Update `app.js` to bind the new Library `+` icon to open the `#add-modal`.

## 3. Bug Fix: Add Music Error

- [x] 3.1 Investigate `adder.js` and `server.js` `/api/add-song` endpoint to find the root cause of the connection failure.
- [x] 3.2 Apply the fix to ensure adding a song from a link or name successfully processes without crashing.

## 4. Backend: Global Delete API

- [x] 4.1 Implement `DELETE /api/songs/:id` in `server.js`.
- [x] 4.2 In the new endpoint, delete the song document from Firebase.
- [x] 4.3 In the new endpoint, use `tgClient` to delete the audio message from the Telegram channel (if `tg_message_id` exists).

## 5. Backend: Playlist Remove API

- [x] 5.1 Implement `DELETE /api/playlists/:id/songs/:songId` in `server.js`.
- [x] 5.2 Update the playlist document in Firebase to remove the `songId` from the `songs` array.

## 6. Frontend: Remove Actions

- [x] 6.1 Update `renderTrackList` in `app.js` to add a trash/remove icon to each track item when rendered in the Library view.
- [x] 6.2 Update `renderPlaylistDetails` in `app.js` to add a remove (minus) icon to each track item when rendered inside a playlist.
- [x] 6.3 Bind click events for the global delete icon to show a `confirm()` prompt and call `DELETE /api/songs/:id`, then refresh the library.
- [x] 6.4 Bind click events for the playlist remove icon to call `DELETE /api/playlists/:id/songs/:songId`, then refresh the playlist view.
