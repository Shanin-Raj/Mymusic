## 1. Typography and Theme System Integration

- [x] 1.1 Add `google_fonts` package dependency to `pubspec.yaml`
- [x] 1.2 Refactor `MyColors` and `AppTextStyles` inside `lib/clone_widgets/constants.dart` with Montserrat typeface and enlarged webapp scale sizes
- [x] 1.3 Update global theme settings in `lib/main.dart` supporting high-fidelity off-white light mode and pure-black `#121212` dark mode

## 2. Layout Boundaries and Spacing Refinement

- [x] 2.1 Implement safe area bottom padding around the bottom navigation bar shell inside `lib/screens/main_screen.dart` to prevent overlap with hardware/gesture system bars
- [x] 2.2 Adjust container carousel heights to 240 in `_SectionCarousel` to ensure artist names and other metadata text never suffer visual clipping
- [x] 2.3 Overhaul custom widgets (`SongTile`, `MixCard`, `RecentPlaysChip`, `SearchBox`) using the responsive Figma-extracted specifications

## 3. Now Playing Routing Refactor

- [x] 3.1 Re-architect `FullScreenPlayer` (Now Playing screen) as a dedicated fullscreen `Scaffold` page route pushed onto the navigation stack via standard `Navigator.push`
- [x] 3.2 Verify status bar overlapping and safe area constraints, adjusting system overlays for dark and light modes
