## Context

Our Flutter application currently features a functional music player but lacks the premium visual polish of the official Spotify app. To achieve higher fidelity, we will utilize the `Mohammad-Nikmard/Spotify-Clone` repository as a direct reference for UI components and screen layouts. The reference code will be cloned locally to enable detailed inspection of widget properties, styling, and animations.

## Goals / Non-Goals

**Goals:**
- Implement a pixel-perfect Spotify UI by adapting widgets from the reference repository.
- Extract only the presentation layer (Dart widgets) to ensure they are decoupled from the reference repo's BLoC state management.
- Re-wire adapted widgets to use our existing `Provider` architecture (`PlayerProvider`, `PlaylistProvider`, etc.).
- Maintain existing backend integrations and playback logic while completely transforming the visual experience.

**Non-Goals:**
- Migrating our application's state management from Provider to BLoC.
- Adopting the reference repo's data models or network service architecture.
- Re-implementing features not currently present in our application (e.g., if a reference widget supports social features we don't have, we omit or disable them).

## Decisions

- **Local Reference Cloning:** The reference repository will be cloned into `reference/spotify-clone/`. *Rationale:* Direct file access ensures that we can copy widget code precisely and analyze complex UI structures that are difficult to infer from screenshots alone.
- **Surgical Widget Extraction:** We will identify and copy only the `.dart` files representing UI components into `lib/clone_widgets/`. *Rationale:* This keeps our codebase clean and prevents bloating the project with unused reference files or conflicting architectural patterns.
- **Provider-Based Injection:** Extracted widgets will be refactored to accept data via standard constructor parameters or by directly consuming our existing `Provider` classes. *Rationale:* This preserves our stable state management while allowing for a radical UI overhaul.
- **Vanilla CSS & Flutter Theming:** We will manually map the reference repo's custom styling (colors, gradients, border radii) to our existing `ThemeData` and `SystemUiOverlayStyle`. *Rationale:* This ensures system-level consistency (e.g., status bar icons) while applying the Spotify aesthetic.

## Risks / Trade-offs

- [Risk] **Tight Coupling in Reference Code** → Reference widgets might be heavily dependent on specific utility classes or external packages.
  *Mitigation:* We will manually "strip" dependencies during extraction, replacing them with standard Flutter primitives or our own local equivalents.
- [Risk] **Performance Impact of High-Fidelity UI** → Authentic Spotify designs often involve complex blurs and nested slivers that can impact frame rates.
  *Mitigation:* We will perform incremental profiling of each screen and optimize adapted widgets (e.g., using `const` where possible, simplifying nested containers).
- [Risk] **Package Version Conflicts** → The reference repository might use older or conflicting versions of common Flutter packages.
  *Mitigation:* We will selectively adopt only necessary UI packages and ensure they are compatible with our current `pubspec.yaml` environment.
