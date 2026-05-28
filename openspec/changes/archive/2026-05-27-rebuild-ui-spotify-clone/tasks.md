## 1. Setup and Reference Acquisition

- [x] 1.1 Clone the `Mohammad-Nikmard/Spotify-Clone` repository into `reference/spotify-clone/`. (Cloned to `D:\music\reference\Spotify-Clone`)
- [x] 1.2 Identify the target UI widgets in the reference repo (e.g., in `lib/ui/` and `lib/widgets/`) that correspond to our Home, Search, Library, and Player views.
- [x] 1.3 Create the `lib/clone_widgets/` directory for adapted components.

## 2. Core Layout & Navigation

- [x] 2.1 Update `lib/screens/main_screen.dart` to use the reference repo's bottom navigation bar layout and styling.
- [x] 2.2 Rebuild the Mini Player using the reference repo's widget structure, ensuring it sits correctly above the new navigation bar.
- [x] 2.3 Align system UI overlays (status bar/navigation bar) with the new Spotify dark theme colors.

## 3. Home Screen Redesign

- [x] 3.1 Adapt the "Recently Played" 2-column grid from the reference repo's home screen.
- [x] 3.2 Extract and refactor the reference repo's carousel/horizontal list widgets for "Jump back in" and "Your mixes".
- [x] 3.3 Re-wire Home screen widgets to our existing `PlayerProvider` for track playback actions.

## 4. Search & Browse Screen Redesign

- [x] 4.1 Implement the rounded Spotify search bar from the reference repo.
- [x] 4.2 Adapt the colorful category cards grid for the browse view.
- [x] 4.3 Update the search result list items to match the reference repo's high-fidelity list tile design.

## 5. Library View Redesign

- [x] 5.1 Implement the reference repo's filter chip row (Playlists, Podcasts, etc.) at the top of the Library screen.
- [x] 5.2 Rebuild the playlist and song lists using the high-fidelity vertical list items from the reference code.

## 6. Full Screen Now Playing Redesign

- [x] 6.1 Redesign the full-screen player layout (Artwork, Metadata, Seek Bar, Transport Controls) based on the reference repo's implementation.
- [x] 6.2 Ensure the Seek Bar correctly syncs with our existing `audioHandler` streams.
- [x] 6.3 Integrate our custom `NowPlayingAnimation` (visualizer) into the new player layout without breaking the aesthetic.
