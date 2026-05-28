## Why

The current playlist implementation has a state synchronization issue where adding a song to a playlist is successful but the changes are not immediately visible to the user. Additionally, the application layout is currently too rigid, failing to adapt gracefully to different device screen sizes, aspect ratios, and system UI elements (like notches and navigation bars).

## What Changes

- **Reactive Playlist State**: Fix the bug where newly added songs don't appear in the playlist UI. This will involve implementing reactive state management for playlist contents.
- **Dynamic Responsive Layout**: Refactor the Flutter layout tree to use `SafeArea`, `Flexible`, and `Expanded` widgets to ensure the app occupies the "safe middle area" of any device and correctly handles system bars.
- **System Bar Integration**: Ensure status bars and navigation bars are correctly themed and accounted for in the layout.

## Capabilities

### New Capabilities
- `responsive-layout-system`: Implements a layout architecture that dynamically adapts to device safe areas and screen dimensions.

### Modified Capabilities
- `flutter-playlist-management`: Update the playlist capability to require immediate UI updates upon song addition.

## Impact

- **Frontend (Flutter)**: `PlaylistDetailScreen` (or equivalent) and the root layout structure (`MainScreen` and related wrappers).
- **Providers**: `PlayerProvider` or a dedicated Playlist provider for state management.
