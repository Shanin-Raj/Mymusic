## Why

The Mixtape application has introduced several high-fidelity layout and player enhancements to elevate user experience. Playlists previously suffered from missing cover images due to packaging directory isolation on Cloud Run (sibling `../images` directory was not packaged). In addition, different playlist pages shared a hardcoded static background gradient rather than custom-tailored aesthetics, the bottom player suffered from progress bar crashes when track durations were zero or loading, and the now-playing visualizer caused page flickering due to high-frequency layout repainting. 

To resolve these visual and stability issues, we have deployed robust folder fallbacks, dynamic HSL-based seeded playlist gradients, math protection for progress calculation, static layout boundaries for visual equalizer animations, and a premium Library refresh action. These updates must be formally recorded in the OpenSpec archive.

## What Changes

- **Robust Playlist Cover Images**: Bundled the `images/` directory inside the `backend/` folder and configured `server.js` to look at both sibling and internal paths, guaranteeing Cloud Run production containers have full access to cover assets.
- **Dynamic Seeded HSL Gradients**: Overhauled the playlist details background to dynamically generate uniquely-tailored, harmonized linear gradients using a stable HSLColor hash based on the playlist's unique ID.
- **Bottom Player Progress Safeguard**: Guarded the millisecond division inside `MiniPlayer`'s progress bar with a duration check to prevent `NaN` or `Infinity` layout crashes.
- **Flickering Visualizer Layout-Isolation**: Wrapped dynamic equalizer bars inside static `SizedBox` and `Align` containers, preventing animation repaints from triggering layout thrashing on parent widgets.
- **Library Refresh Action**: Added a refresh button in the Library app bar actions to clear local caches, fetch manual additions immediately, and confirm status with a premium SnackBar.

## Capabilities

### New Capabilities
<!-- None: This change refines existing features and fixes UI/player bugs -->

### Modified Capabilities
- `playlist-ui-refinement`: Dynamic seeded HSL-based linear gradients for unique, consistent, premium playlist page aesthetics.
- `spotify-mini-player`: Safe division-by-zero checks inside bottom player progress bar to support uninitialized track durations.
- `playback-visualizer`: Static boundary layout-isolation for animated equalizer visualizer to eliminate high-frequency layout repaints and image flickering.
- `universal-library-adder`: Added a visual refresh action to easily invalidate cached songs and pull newly added tracks.

## Impact

- **d:/music/backend/server.js**: Implemented robust image resolving from internal `backend/images/` and sibling paths.
- **d:/music/backend/images/**: Added all 5 local images into the backend package for Cloud Run compatibility.
- **d:/music/flutter_app/lib/widgets/now_playing_animation.dart**: Refactored equalizer bars with dynamic height limits inside a static layout boundary.
- **d:/music/flutter_app/lib/screens/main_screen.dart**: Fixed progress calculation division, added HSL gradient generator, and integrated a Library refresh button with SnackBar messaging.
