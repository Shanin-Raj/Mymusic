## Why

This change fixes a layout issue where the bottom sheets triggered from the library view (including the library add sheet, playlist option dialog, artist option dialog, and album option dialog) clip under the system navigation bar on devices with hardware or software nav bars.

## What Changes

- Update `_showLibraryAddBottomSheet()`, `_showPlaylistOptionDialog()`, `_showArtistsOptionDialog()`, and `_showAlbumsOptionDialog()` in `main_screen.dart` to calculate and apply `MediaQuery.of(context).padding.bottom + 20` to the container padding.

## Capabilities

### New Capabilities

### Modified Capabilities
- `spotify-library-view`: Add requirement that all modular bottom sheets and lists triggered from the library screen actions must respect device safe areas and apply bottom paddings.

## Impact

- Modified file: `main_screen.dart` (specifically the 4 dialog helper methods).
