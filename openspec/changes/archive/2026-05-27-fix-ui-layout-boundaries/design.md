## Context

The application currently uses an edge-to-edge design with transparent system bars. While visually appealing, this has led to layout issues where interactive elements (like the bottom navigation bar and mini player) and metadata (like the top header in Now Playing) overlap with system UI elements (system navigation bar and status bar).

## Goals / Non-Goals

**Goals:**
- Ensure all app content is visible and interactive by respecting system safe area insets.
- Maintain the "Spotify-style" dark theme and transparent bar aesthetic.
- Standardize Safe Area management across the application shell and full-screen views.

**Non-Goals:**
- Removing the transparent status/navigation bar effect.
- Complete redesign of the navigation or player components.

## Decisions

- **Scaffold-Level Safe Area:** We will wrap the `bottomNavigationBar` and the top of `FullScreenPlayer` in `SafeArea` widgets or use `Padding` calculated from `MediaQuery.of(context).padding`.
- **Bottom Navigation Padding:** In `MainScreen`, the `bottomNavigationBar`'s container will be wrapped in a `SafeArea` (bottom only) to ensure it clears the system navigation bar on devices without hardware buttons (gestural navigation).
- **Now Playing Header Adjustment:** The `AppBar` in `FullScreenPlayer` will be reviewed to ensure it properly accounts for the status bar height. We may need to explicitly pad the top of the `Scaffold` body if `extendBodyBehindAppBar` is used (though it doesn't seem to be).
- **Global Theme Injection:** We will verify that `SystemUiOverlayStyle` is correctly applied globally to ensure icons are always visible against our dark background.

## Risks / Trade-offs

- [Risk] **Double Padding** → Using `SafeArea` on a `Scaffold` that already handles safe areas might lead to excessive gaps.
  *Mitigation:* Test on both notch and non-notch devices to ensure padding is minimal but sufficient.
- [Risk] **UI Jumping** → Transitions between screens might show "jumps" if safe areas are handled inconsistently.
  *Mitigation:* Use consistent `SafeArea` configurations (e.g., `bottom: true, top: false` for the shell, `top: true` for full-screen modals).
