## Context

Mixtape's user interface has undergone a comprehensive high-fidelity redesign, adapting custom layouts exported from Figma. To provide a modern, premium experience, a new typography system, revised layout spacing, and solid color palettes were implemented, preserving all background audio streaming and state providers. This document records the architectural and design decisions behind these visual upgrades to serve as the project's long-term dated memory.

## Goals / Non-Goals

**Goals:**
- Formally document the typography transition to Google Fonts' `Montserrat` to emulate the "Spotify Mix" look.
- Detail the safe area layout adjustments, specifically the bottom navigation system bar padding and the increased height limits for carousels to prevent text clipping.
- Chronicle the navigation overhaul of `FullScreenPlayer` from a bottom sheet to a standard Scaffoled page route.
- Preserve the exact operational logic, providers, and state sync of Mixtape while altering the UI.

**Non-Goals:**
- Introducing new functional features or database changes in this change record.
- Redesigning the underlying audio service playback engine.

## Decisions

- **Montserrat Integration via Google Fonts**:
  - *Decision*: We integrated `google_fonts: ^6.2.1` and applied `GoogleFonts.montserrat()` globally as the primary text theme in `main.dart` and `constants.dart`.
  - *Alternatives Considered*: Bundling custom TTF/OTF files. This was rejected to keep repository size small and avoid asset bundling issues in Flutter build outputs. Montserrat was chosen as the closest, highly readable, free-license geometric sans-serif font matching "Spotify Mix".
  - *Scaling*: Increased typographic weights and sizes globally in `AppTextStyles` to match premium high-density web-app standards.

- **Bottom Navigation Safe Area Wrap**:
  - *Decision*: Configured the bottom navigation shell in `main_screen.dart` with bottom safe area wrapping, and colored the bottom zone to match the background color (#121212 / #FFFFFF).
  - *Rationale*: This ensures that on edge-to-edge screens with system gesture bars, the app contents do not bleed awkwardly behind system bars, and touch controls remain accessible.

- **Carousel Height and Text Clipping Fix**:
  - *Decision*: Increased the height of `_SectionCarousel` containers to `240` and revised `MixCard` layout constraints.
  - *Rationale*: With the enlarged, high-density Montserrat text sizes, artist names (e.g., "Hariharan, A.R.") were getting clipped vertically. The added height accommodates multi-line metadata gracefully without visual overflow or layout errors.

- **FullScreenPlayer Routing Refactor**:
  - *Decision*: Shifted `FullScreenPlayer` from a floating `showModalBottomSheet` to a dedicated `Navigator.push` route displaying a full `Scaffold`.
  - *Rationale*: Modal bottom sheets introduce gesture conflicts (especially vertical drag to collapse interfering with seek bar adjustments) and make safe area status bar insets hard to control. Using a standard Scaffold route guarantees reliable safe area padding, consistent transition animations, and robust system overlay controls.

## Risks / Trade-offs

- **[Risk] Font Dependency Latency** → Relying on `google_fonts` can cause a brief visual font-swap delay if the font is fetched at runtime on a device without internet access.
  - *Mitigation*: The `google_fonts` package automatically caches downloaded fonts, and they can be bundled directly in assets for production releases if necessary.
- **[Risk] Back Button Behavior in Now Playing** → Converting the bottom sheet to a page means the system back button pop behavior is different.
  - *Mitigation*: Handled carefully in the standard Flutter Navigator so that popping from `FullScreenPlayer` maintains correct playback state and smoothly returns to the parent screen.
