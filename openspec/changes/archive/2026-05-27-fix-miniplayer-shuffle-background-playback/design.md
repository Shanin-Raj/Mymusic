## Context

During previous testing and usage sessions, we identified 4 key issues:
- The MiniPlayer was absent from detail pages, forcing users to navigate back to Library/Home to pause or skip tracks.
- Rapidly shuffling playlists triggered double-shuffling because the manual randomized queue was subjected to another shuffle command via just_audio, leading to mismatched song indices.
- The client-side manual song adder UI was cluttered, legacy code, and needed cleanup.
- Android background playback would suspend shortly after switching applications due to lack of a configured AudioSession.

## Goals / Non-Goals

**Goals:**
- Add MiniPlayer component dynamically to all details screens.
- Fix index alignment on shuffle play by disabling double shuffling.
- Delete all unused legacy `UniversalAdderDialog` UI components and triggers.
- Integrate `audio_session` library to claim OS audio focus.

**Non-Goals:**
- Changing primary database/sync endpoints or yt-dlp downloader codebase.

## Decisions

- **Decision 1: Scaffold wrapping for MiniPlayer**
  - *Choice*: Wrap existing CustomScrollView/FutureBuilder bodies inside a Column with Expanded + MiniPlayer widget.
  - *Rationale*: Reuses the existing standalone `MiniPlayer` widget and guarantees it stays docked at the bottom.
- **Decision 2: Disable just_audio shuffle mode in manual shuffle**
  - *Choice*: Set shuffle mode to `none` after manually pre-shuffling the queue.
  - *Rationale*: Solves the double-shuffle mismatch seamlessly.
- **Decision 3: Android AudioSession configuration**
  - *Choice*: Run `session.configure()` using music playback parameters and explicitly invoke `session.setActive(true)` on handler startup.
  - *Rationale*: Re-acquires system audio focus dynamically.

## Risks / Trade-offs

- *Risk*: Multiple MiniPlayer states.
  - *Mitigation*: Controlled centrally via Provider state.
