## Context

Currently in `FullScreenPlayer.build()`:

```dart
return AnnotatedRegion<SystemUiOverlayStyle>(
  value: SystemUiOverlayStyle(statusBarColor: Colors.transparent, ...),
  child: Container(
    child: Scaffold(
      extendBody: true,
      appBar: AppBar(...),
      body: SafeArea(top: true, bottom: true,
        child: Padding(...)
      ),
    ),
  ),
);
```

The `AnnotatedRegion` enables edge-to-edge mode (transparent status bar), and since `SafeArea` only wraps the `body` but not the `AppBar`, the AppBar's back button and title text sit under the system status bar. Removing spacing or adjusting body padding alone doesn't fix this because the root issue is structural — the status bar safe area isn't applied to the AppBar at all.

## Goals / Non-Goals

**Goals:**
- Ensure the AppBar (back button, title) is inset below the system status bar.
- Keep the transparent status bar styling for a modern, immersive look.
- Preserve the body layout spacing (already optimized in previous changes).

**Non-Goals:**
- Changing the visual appearance (gradient, colors, icons) of the player.
- Altering body padding/spacing that was already tuned.

## Decisions

1. **Wrap entire player widget in SafeArea instead of only the body:**
   - **Decision:** Move `SafeArea` to wrap the `Container` (or `Scaffold`) at the root level, so both the `AppBar` and the `body` are inset from the status bar.
   - **Rationale:** The `AppBar` currently has no safe area handling. Wrapping only the body means the top portion (AppBar + status bar area) is exposed. Moving `SafeArea` up ensures everything is inset correctly.
   - **Alternatives considered:** Adding top padding to the AppBar manually — less clean, more fragile across devices.

2. **Remove `extendBody: true`:**
   - **Decision:** Remove the `extendBody: true` property from the `Scaffold`.
   - **Rationale:** This property extends the body behind the bottom navigation bar, but this player doesn't have a bottom navigation bar — it's a full-screen overlay. It's unnecessary and may conflict with bottom safe area handling since `SafeArea(bottom: true)` already handles that.

## Risks / Trade-offs

- [Risk] Moving `SafeArea` up may slightly shift the album art or controls.
  → **Mitigation:** The `body` already has `SafeArea(top: true, bottom: true)` plus additional `Padding(horizontal: 32, top: 40, bottom: 24)`. After the change, the body `SafeArea` will be redundant but harmless (SafeArea is idempotent when the area is already safe). We can keep it or remove it without visual difference.
