## Why

Over the course of development, the agent has executed a major high-fidelity UI redesign of the SonicVault Spotify-clone application, integrated proprietary Figma layouts, optimized typographic scaling with the Montserrat font (to emulate "Spotify Mix"), refined dark/light mode toggle palettes, and solved several layout regressions (such as the mini player bleeding and text cutting off in mix cards). 

To ensure these changes are preserved as a permanent dated reference for the agent's long-term memory, we need to formally update the OpenSpec archive with a proposal, design specification, and delta specs detailing the implementation.

## What Changes

- **Global Typography**: Added `google_fonts` package and integrated the geometric `Montserrat` font family as the primary application typeface. Font sizes were scaled up across all styles to align with premium webapp layouts.
- **High-Fidelity Theme Toggles**: Implemented specific dark/light theme color tokens: dark mode uses `#121212` backgrounds and `#111111` surfaces; light mode uses off-white `#F5F5F7` backgrounds; accent colors use brand Spotify green (`#1ED760` / `#1DB954`).
- **Component Redesigns**: Overhauled component structures including `MiniPlayer`, `MixCard` (height adjusted to `240` to avoid text clipping), `SongTile` (artwork dimensions, metadata layouts), `RecentPlaysChip` (square thumbnails, active play states), and `SearchBox` (pill shape and magnifier elements).
- **Navigation & Routing Overhaul**: Re-architected the `FullScreenPlayer` (Now Playing) from a sliding bottom sheet modal to a fullscreen Scaffoled page pushed via standard `Navigator.push`.
- **System Padding & Safe Areas**: Configured the bottom navigation shell to wrap padding around the system safe areas, ensuring the main screen bottom bar colors the system navigation zone cleanly.

## Capabilities

### New Capabilities
<!-- None: This change documents and archives the visual refinements of existing features -->

### Modified Capabilities
- `spotify-design-system`: Updated specs to formalize the Montserrat typography, enlarged font scaling, and high-fidelity dark/light mode color palettes.
- `spotify-ui-redesign`: Documented the full integration of Figma layouts across the 5 primary views while preserving background logic, audio providers, and state sync.
- `spotify-now-playing`: Defined the navigation structure change from a modal sheet to a full Scaffold route with custom status bar/safe area handling.
- `ui-layout-boundaries`: Prescribed the updated layout limits, such as bottom nav safe area color boundaries and carousel height parameters to avoid font clipping.

## Impact

- **pubspec.yaml**: Added `google_fonts: ^6.2.1`.
- **lib/clone_widgets/constants.dart**: Major updates to `MyColors` and `AppTextStyles`.
- **lib/main.dart**: Global theme integration with Montserrat and theme toggles.
- **lib/screens/main_screen.dart**: Complete visual overhaul of primary and detail screens, player integration, navigation adjustments, and spacing fixes.
- **lib/clone_widgets/**: Refined widgets (`song_tile.dart`, `mix_card.dart`, `recent_plays_chip.dart`, `search_box.dart`, etc.).
