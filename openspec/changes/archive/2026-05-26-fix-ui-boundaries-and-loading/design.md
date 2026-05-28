## Context

The Flutter application (`flutter_app`) currently does not properly constrain the UI to the device's safe areas (status bar and navigation bar). As a result, components like the "now playing" bar are drawn behind the system navigation bar, rendering them unusable. Also, when a user starts playing a song, the UI displays a loading state for an extended duration before showing the updated view. This is likely due to an inefficient state management update or blocking asynchronous work tied to the playback initiation event.

## Goals / Non-Goals

**Goals:**
- Wrap the main application screens (or the root `Scaffold`) within a `SafeArea` widget, or use `EdgeInsets` on specific containers, to prevent overlap with the system UI boundaries (top status bar, bottom nav bar).
- Ensure the "now playing" bar remains visible above the bottom navigation bar without relying on transparent background hacks.
- Identify and eliminate the long UI blocking/loading state that occurs upon initiating audio playback.

**Non-Goals:**
- Completely redesigning the application UI.
- Switching state management solutions (e.g., from Provider to Riverpod/Bloc) if not strictly necessary to fix the bug.

## Decisions

1. **Safe Area Implementation:** 
   - **Decision:** Use Flutter's `SafeArea` widget at the top-level structure of the app (such as the main `Scaffold` body or the wrapper for the tab view) rather than modifying padding manually everywhere.
   - **Rationale:** Standard and robust way to adapt to various device shapes and system UI elements automatically.

2. **Fixing Playback Loading State:**
   - **Decision:** Decouple audio player initialization/buffering from the immediate UI update. The UI should instantly reflect a "playing" or "buffering" state locally while the audio player loads asynchronously, rather than showing a full-screen loading spinner.
   - **Rationale:** Ensures immediate feedback to the user, improving perceived performance.

## Risks / Trade-offs

- **Risk:** Implementing `SafeArea` globally might introduce unwanted letterboxing or background color mismatches on screens where elements (like images) were supposed to bleed into the system status bar area.
  - **Mitigation:** Test the layout on standard screens and edge-to-edge displays. If specific screens require drawing behind the status bar, apply `SafeArea` conditionally or use `AnnotatedRegion` combined with customized padding.
- **Risk:** Optimizing the playback state could lead to edge cases where the UI shows playing but audio fails to start.
  - **Mitigation:** Ensure error handling in the audio playback logic correctly transitions the UI back to a stopped/error state.
