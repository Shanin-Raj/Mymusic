## Why

The current Flutter application is operational but requires several UI and UX refinements to achieve professional parity with the original web app. Specifically, the swipe-to-delete gesture is too sensitive and needs a confirmation dialog to prevent accidental data loss. The playlist management is incomplete, lacking the ability to add songs. The search functionality is inefficient as it shows all songs by default, and a critical bug in the playback engine causes music to always start from the first track in the library regardless of what the user selected. These issues collectively hinder the "native" feel and usability of the app.

## What Changes

- **UI/UX Improvements**: General aesthetic polish and refinement across the app.
- **Delete Confirmation**: Implement a modal confirmation dialog when a user swipes to delete a track.
- **Playlist Song Addition**: Add the capability for users to add songs to their playlists within the Flutter app.
- **Playback Index Fix**: Fix the bug where playback always starts from the first song in the list ("Safar").
- **Search Logic Refinement**: Update the search page so that when the query is empty, instead of showing a blank screen or all songs, it displays a "Start browsing" grid of colorful category cards (e.g., Music, Podcasts, Live Events) matching the provided UI design. Clicking these will redirect to playlists (to be wired up later).
- **Dev Mode Maintenance**: Ensure all configurations remain in development mode (unique `applicationId`) to avoid conflicts with the production TWA.

## Capabilities

### New Capabilities
- `ux-safety-confirmations`: Requirements for modal dialogs and safe interaction patterns.
- `contextual-playback-logic`: Requirements for ensuring selected tracks play immediately within their specific context.

### Modified Capabilities
- `flutter-playlist-management`: Adding requirements for song insertion and playlist modification.
- `flutter-search`: Modifying requirements to hide results until a query is entered.
- `spotify-ui-redesign`: Expanding UI requirements for better polish and consistency.

## Impact

- **UX**: Significant improvement in safety (deletions) and intuitive behavior (search and playback).
- **Functionality**: Complete playlist management loop.
- **Stability**: Fixing the critical playback index bug.
- **Code**: Refinement of `PlayerProvider`, `SearchView`, and `LibraryView`.
