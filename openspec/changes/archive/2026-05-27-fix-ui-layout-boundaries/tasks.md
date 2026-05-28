## 1. Global Shell Fixes

- [x] 1.1 Wrap the `bottomNavigationBar` in `lib/screens/main_screen.dart` with a `SafeArea` (bottom only) to prevent overlap with the system gesture bar.
- [x] 1.2 Add `SafeArea` to the bottom of the `MiniPlayer` or the `Column` containing the `IndexedStack` to ensure it clears the bottom boundary.
- [x] 1.3 Ensure the `Scaffold` background is consistent and doesn't show light "gaps" during safe area transitions.

## 2. Full Screen Player Fixes

- [x] 2.1 Replace hardcoded top padding in `FullScreenPlayer` (inherited from reference `top: 50`) with `MediaQuery.of(context).padding.top` or a `SafeArea` to avoid status bar overlap.
- [x] 2.2 Re-position the "Playing / Lyrics" toggle and artwork to be relative to the top safe area inset (replacing hardcoded `top: 90`).
- [x] 2.3 Verify that the collapse icon and metadata are fully interactive and not occluded by system icons.

## 3. Screen-Specific Boundary Checks

- [x] 3.1 Audit `HomeView` and `SearchView` headers to ensure they use `SliverSafeArea` or proper top padding.
- [x] 3.2 Fix the `SearchBox` positioning so it remains below the status bar when the view is at the top.
- [x] 3.3 Verify that list content in `LibraryView` doesn't get cut off by the mini player's new safe area padding.
