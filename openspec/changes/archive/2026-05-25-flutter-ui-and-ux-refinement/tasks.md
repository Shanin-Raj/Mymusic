## 1. Playback Engine Refinement

- [x] 1.1 Rethink playback indexing: In `PlayerProvider.playSong`, ensure the correct index of the selected song is passed to the `AudioHandler`.
- [x] 1.2 Fix "Safar" bug: Update the `playSong` logic to use the `skipToQueueItem` method with the exact index from the filtered context.

## 2. UX Safety: Delete Confirmations

- [x] 2.1 Refactor track deletion in `LibraryView`: Integrate `confirmDismiss` into the `Dismissible` widget.
- [x] 2.2 Implement `DeleteConfirmationDialog`: Create a reusable modal dialog that asks for confirmation before proceeding with API deletion.

## 3. Playlist Enhancement

- [x] 3.1 Implement "Add to Playlist" UI: Add a context menu button to track tiles that opens a bottom sheet listing available playlists.
- [x] 3.2 Wire up `addSongToPlaylist` API: Connect the bottom sheet selection to the `ApiService.addSongToPlaylist` method.

## 4. Search Page Logic Update

- [x] 4.1 Update `SearchView` initial state: Modify the UI so when the query is empty, it displays a "Start browsing" header and a `GridView` of colorful category containers (e.g., Music, Podcasts) that visually match the provided design. Clicking these containers should currently be placeholders for future playlist redirection.
- [x] 4.2 Fix Search result interaction: Ensure tapping a song in search results correctly triggers contextual playback of the filtered list.

## 5. General UI Polish

- [x] 5.1 Audit spacing and padding: Perform a visual sweep of the `MainScreen`, `HomeView`, and `PlayerScreen` to ensure consistency with the web app reference.
- [x] 5.2 Polish transitions: Ensure smooth entry/exit animations for the full-screen player and modals.
- [x] 5.3 Verify Dev Mode: Confirm `applicationId` remains `com.example.sonic_vault_flutter.dev`.
