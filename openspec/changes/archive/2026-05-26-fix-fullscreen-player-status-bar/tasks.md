## 1. Full-Screen Player Safe Area Fix

- [x] 1.1 Add `AnnotatedRegion<SystemUiOverlayStyle>` wrapper to the `FullScreenPlayer`'s root `Container` to set appropriate status bar styling.
- [x] 1.2 Remove `extendBodyBehindAppBar: true` from the `FullScreenPlayer`'s `Scaffold`.
- [x] 1.3 Wrap the `FullScreenPlayer`'s body content in a `SafeArea` widget to constrain it below the system status bar.
