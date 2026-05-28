## Context

Currently, the `MiniPlayer` widget resides inside a vertical column in both the `AlbumDetailScreen` and `ArtistDetailScreen` layouts. Since it doesn't wrap itself in safe area margins at the bottom of these pages, it rendering overlaps with the system navigation elements. Also, the bottom-most song tile is obstructed since the list container bottom padding is set to a default `16 px` instead of leaving room for the player.

## Goals / Non-Goals

**Goals:**
- Add `SafeArea` bottom coverage to the `MiniPlayer` widget instance within `AlbumDetailScreen` and `ArtistDetailScreen`.
- Ensure songs list bottom padding is adjusted to at least `90 px` so that user can scroll past the last list item and view it in its entirety above the player.

**Non-Goals:**
- Change the overall UI styling, background color, or functionality of the `MiniPlayer` itself.
- Change general routing or song playback logic.

## Decisions

- **Wrap the `MiniPlayer` widget instance inside detail screens rather than internally in the MiniPlayer widget class:** This maintains consistent layout control on screens containing the MiniPlayer (e.g. main shell page has a BottomNavigationBar that handles SafeArea, detail pages don't).
- **Increase SliverPadding to 90 px:** Evaluated list spacing, `90 px` provides a comfortable gap clearing both the 70 px height of the player and safe-area margins.

## Risks / Trade-offs

- None expected.
