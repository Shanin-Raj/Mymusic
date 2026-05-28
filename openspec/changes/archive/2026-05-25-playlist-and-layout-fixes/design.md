## Context

The Music app is a Flutter-based application that needs to look polished and work correctly across various devices. Currently, there is a bug where songs added to a playlist are not immediately visible in the UI, indicating a state management or cache synchronization issue. Additionally, the app's layout is rigid and doesn't always account for system UI elements like notches and gesture bars, leading to potential layout clipping or awkward spacing.

## Goals / Non-Goals

**Goals:**
- Fix the playlist visibility bug by ensuring UI reactivity.
- Implement a responsive layout architecture using `SafeArea` and flexible layout widgets.
- Ensure consistent positioning and theming of top and bottom bars across all device types.

**Non-Goals:**
- Redesigning the playlist data structure in the backend.
- Changing the overall design language of the app.

## Decisions

- **Decision: Use `Provider` or `Riverpod` for Playlist State (depending on current stack)**
  - **Rationale**: The UI needs to listen to a stream or a notifier that updates when the local playlist data changes.
  - **Alternatives**: Manual `setState` (hard to manage across screens), full Bloc (might be overkill if not already used).
  
- **Decision: Audit and Refactor root `Scaffold` for `SafeArea`**
  - **Rationale**: Wrapping the main content area in `SafeArea` is the standard Flutter way to handle notches and system bars.
  - **Alternatives**: Manually calculating padding using `MediaQuery` (less maintainable).

- **Decision: Use `Expanded` and `Flexible` for dynamic content sizing**
  - **Rationale**: This allows the middle section of the app (the "safe middle area") to occupy all available space while bars stay fixed.

## Risks / Trade-offs

- **[Risk]**: State synchronization between the API and the local provider might lead to "ghost" entries if not handled correctly.
  - **Mitigation**: Optimistically update the UI but ensure the local state is refreshed from the API after the call succeeds.
- **[Risk]**: Layout changes might break custom animations or hardcoded pixel values.
  - **Mitigation**: Use `LayoutBuilder` for complex components and avoid hardcoded heights where possible.

## Migration Plan

1.  **Playlist Fix**: Identify the current playlist state management and wrap the track list in a reactive consumer.
2.  **Layout Audit**: Check the main `app.dart` or `main_screen.dart` and ensure `SafeArea` is applied at the correct level.
3.  **Flexible Refactor**: Update the main navigation structure to use `Column` with `Expanded` for the content area.
