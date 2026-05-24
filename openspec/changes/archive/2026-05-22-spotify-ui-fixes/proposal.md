## Why

The current UI contains uneven component color matching and inconsistent gradients that detract from the premium feel. Furthermore, users are experiencing connection errors when trying to add new music. To streamline the user experience, the dedicated "Create" page is unnecessary; the add functionality belongs more naturally in the "Library" page via a plus icon. Finally, users need the ability to remove songs—both permanently from their vault/Telegram and selectively from specific playlists.

## What Changes

- **Fix Component Colors**: Standardize all component colors to eliminate uneven gradients and use the official Spotify background color (`#191414`).
- **Fix Add Music Error**: Investigate and resolve the "Failed to connect to server" error when adding new music.
- **Remove Create Page**: Remove the standalone "Create" tab from the bottom navigation.
- **Relocate Add Music Feature**: Add a plus (`+`) icon to the Library page header to trigger the "Add Music" modal.
- **Library Song Removal**: Add a "Remove Song" button in the library view. Clicking it will show a confirmation prompt and then completely delete the song from the database and Telegram.
- **Playlist Song Removal**: Add a "Remove from Playlist" icon for songs within a playlist view. This will only remove the song from the playlist without deleting it from the library.

## Capabilities

### New Capabilities
- `color-standardization`: Fix uneven gradients and colors, use `#191414` for the background.
- `add-music-fix`: Resolve the server connection error when adding new music.
- `library-add-action`: Relocate the add music action to a plus icon on the Library page and remove the Create page.
- `library-remove-song`: Allow users to permanently delete a song (from DB and Telegram) via the library, with a confirmation prompt.
- `playlist-remove-song`: Allow users to remove a song from a specific playlist without deleting it from the vault.

### Modified Capabilities
_(none - building upon the previous redesign)_

## Impact

- **Frontend**: `styles.css`, `index.html`, `app.js` will be updated for color fixes, removing the Create tab, adding the new buttons, and handling the removal logic.
- **Backend**: `server.js` and potentially `firebase.js` / Telegram client code will need new or updated endpoints to support permanent song deletion. The add song API error will be debugged and fixed.
