## Context

The Flutter app currently uses safe areas to prevent drawing behind system UI elements like the Android status bar and navigation bar. This results in harsh, blocky edges on devices with edge-to-edge displays instead of an immersive, modern look. Additionally, while the web version of the application features a dynamic EQ animation when music plays, the Flutter app lacks this visual indicator, making the app feel less "alive."

## Goals / Non-Goals

**Goals:**
- Implement edge-to-edge drawing on Android for a more immersive UI.
- Introduce an animated EQ visualizer component for actively playing tracks.
- Improve parity with the web app's visual polish without heavy performance costs.

**Non-Goals:**
- Redesigning the entire player interface.
- Creating a perfect frequency-mapped EQ (a visual simulation is sufficient for aesthetic purposes).
- Implementing edge-to-edge optimizations for iOS beyond standard `SafeArea` bottom adjustments.

## Decisions

- **Edge-to-edge implementation**: We will use `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` in `main.dart` and configure `SystemUiOverlayStyle` to make navigation and status bars transparent. Scaffold instances across the app will use `extendBody: true` and `extendBodyBehindAppBar: true` where needed. `SafeArea` wrappers at the Scaffold body root will be removed, and manual padding will be used strategically so content does not get permanently covered by the bottom system bar or top notch.
- **Visualizer implementation**: We will build a lightweight `NowPlayingAnimation` widget using standard Flutter animation components (e.g., `AnimatedContainer` or custom `AnimationController` with bars) rather than importing a heavy Lottie animation. This minimizes app size and gives us programmatic control to sync with the `PlayerProvider`'s `isPlaying` state.
- **Provider integration**: The `NowPlayingAnimation` widget will only animate when the `PlayerProvider` is actively playing the associated track.

## Risks / Trade-offs

- **Risk: Content overlapping system buttons** → Mitigation: Use localized `SafeArea` or bottom padding specifically for scrollable content limits and fixed UI overlays, ensuring interactions are not obstructed.
- **Risk: Animation causing jank or battery drain** → Mitigation: The animation will stop completely when `isPlaying` is false or the track changes, and use minimal repaints.
