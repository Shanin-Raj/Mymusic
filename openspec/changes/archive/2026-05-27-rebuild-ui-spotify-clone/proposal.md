## Why

The current Flutter app UI lacks the authentic Spotify aesthetic and high-fidelity presentation found in modern music applications. By rebuilding the UI layer using a proven reference—the `Mohammad-Nikmard/Spotify-Clone` repository—we can achieve a pixel-perfect Spotify look and feel while leveraging our existing stable business logic and state management.

## What Changes

- Overhaul the application shell, including the bottom navigation bar and mini player.
- Redesign the Home, Search, and Library screens to match the high-fidelity widgets from the reference repository.
- Rebuild the Full Screen Now Playing view with authentic Spotify layouts and controls.
- Extract pure UI widgets from the reference repository and adapt them to use our current `Provider` state management.
- Ensure the new UI elements seamlessly integrate with existing features like edge-to-edge rendering and dark mode support.

## Capabilities

### New Capabilities
- `spotify-clone-widgets`: Extraction and adaptation of reusable UI components (cards, lists, buttons) from the reference clone repository.

### Modified Capabilities
- `spotify-ui-redesign`: Core layout and typography updates to utilize the newly imported clone widgets.
- `spotify-home-feed`: Replacement of current carousels and grids with authentic feed widgets.
- `spotify-library-view`: Implementation of high-fidelity list and grid items for playlists and songs.
- `spotify-search-browse`: Adaptation of the search input and category browse grid to match the reference styling.
- `spotify-now-playing`: Reconstruction of the full-screen player using authentic layouts while retaining custom visualizer logic.

## Impact

- **UI/UX**: Complete transformation of the visual layer for a professional Spotify experience.
- **Project Structure**: Addition of a `reference/` directory for the cloned repository and a `lib/clone_widgets/` directory for adapted components.
- **Dependencies**: Potential addition of UI-focused packages found in the reference repo (e.g., `auto_size_text`, `animations`).
- **Development Workflow**: Implementation will now be informed by direct inspection of the cloned reference source code.
