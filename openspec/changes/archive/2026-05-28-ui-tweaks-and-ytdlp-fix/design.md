## Context

The app lacked a global navigation feel because the AppBottomNav was missing in sub-screens like Album, Artist, and Playlist details. Also, the backend ran into yt-dlp warnings regarding JS runtimes, which could affect the quality of fetched streams.

## Goals / Non-Goals

**Goals:**
- Provide a consistent AppBottomNav across detail screens.
- Keep the MiniPlayer rendering above the bottom navigation bar without system navigation bar overlapping issues.
- Fix backend yt-dlp JS warnings to guarantee successful cipher extraction.

**Non-Goals:**
- Redesigning the MiniPlayer.
- Altering the backend architecture.

## Decisions

- **UI Composition**: Instead of complex nested navigators, we inject a `Column(mainAxisSize: MainAxisSize.min)` into the `bottomNavigationBar` of the Scaffold that stacks the `MiniPlayer` and `AppBottomNav`. This leverages Flutter's built-in Scaffold inset calculations.
- **Backend yt-dlp Runtime**: The `yt-dlp` tool is commanded to use `nodejs` via `--js-runtimes nodejs` as Node is already present in the backend environment.

## Risks / Trade-offs

- **Risk**: Stacked navigation (Pushing from Album back to MainScreen creates a new route).
  - **Mitigation**: Using `Navigator.pushAndRemoveUntil` clears the stack, mimicking a unified bottom nav experience without memory leaks.
