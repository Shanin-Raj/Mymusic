## Context

The `FullScreenPlayer` widget at `main_screen.dart:1133` is displayed as a modal bottom sheet when the user taps the mini player. It currently sets `extendBodyBehindAppBar: true` on its internal `Scaffold`, which causes the entire body (album art, controls, text) to render behind the system status bar. The body padding is only `EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0)` — insufficient to clear the status bar height.

This was missed in the previous `fix-ui-boundaries-and-loading` change, which only addressed the main screen layout.

## Goals / Non-Goals

**Goals:**
- Ensure the full-screen player body content is constrained below the status bar safe area.
- Ensure status bar icon brightness is appropriate for the player's dark/light themes.

**Non-Goals:**
- Changing the layout, spacing, or visual design of the full-screen player.
- Fixing the bottom safe area (already handled by `extendBody` usage).

## Decisions

1. **Safe Area Approach:**
   - **Decision:** Remove `extendBodyBehindAppBar: true` from the `Scaffold` and wrap the body in a `SafeArea` widget.
   - **Rationale:** `extendBodyBehindAppBar` was likely used to allow the gradient background to fill the screen edge-to-edge, but it causes content to bleed behind the status bar. Removing it and using `SafeArea` is the standard Flutter approach. The gradient is applied to the outer `Container`, not the body, so removing it from the `Scaffold` won't break the gradient.

2. **Status Bar Styling:**
   - **Decision:** Add an `AnnotatedRegion<SystemUiOverlayStyle>` to the outer `Container` of the `FullScreenPlayer` to set the correct status bar icon brightness based on the current theme (light icons for dark theme, dark icons for light theme).
   - **Rationale:** When the player opens as a modal, the status bar icon style from the previous screen persists. The `AnnotatedRegion` ensures proper contrast.

## Risks / Trade-offs

- [Risk] Removing `extendBodyBehindAppBar` could cause a slight visual shift in the vertical positioning of content.
  → **Mitigation:** The outer `Container` still fills the full screen, and `SafeArea` only constrains the body content; the visual shift will be minimal and correct.
