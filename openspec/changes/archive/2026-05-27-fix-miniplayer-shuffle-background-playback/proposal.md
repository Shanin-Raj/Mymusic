## Why

This change addresses multiple outstanding user experience and playback stability issues:
1. The mini player was missing from detail screens (album, artist, playlist), making playback controls inaccessible while browsing.
2. Rapid shuffle toggles caused a mismatch where the UI showed one song but played another.
3. The manual song add interface was cluttered, redundant, and needed to be deprecated in favor of a clean, fully server-side sync architecture.
4. Background playback would cease on Android due to missing foreground focus session configuration.

## What Changes

- Wrap all detail screens (Album, Artist, Playlist Detail Screens) in a Scaffold layout that includes the MiniPlayer at the bottom.
- Fix the double-shuffle bug in `PlayerProvider` to prevent `just_audio` from re-shuffling an already-randomized queue.
- Remove the "Add Song (Sync Library)" UI dialogs, plus menu action triggers, and the `UniversalAdderDialog` class entirely.
- Activate the native `audio_session` in `SonicAudioHandler` to request correct music playback focus and prevent Android OS suspension.

## Capabilities

### New Capabilities

### Modified Capabilities
- `spotify-mini-player`: Extend the mini player display requirements so that the mini player is persistently visible on all secondary detail screens (album, playlist, and artist detail pages) and not just the main library view.
- `contextual-playback-logic`: Ensure shuffle initialization does not double-shuffle tracks, maintaining accurate sync between active queue indexes and display items.
- `universal-library-adder`: Deprecate and remove the client-side adder dialog requirements, keeping only the backend sync and download modules.
- `background-audio-continuity`: Add requirements for claiming Android OS audio session focus during playback to prevent foreground service termination when the app loses focus.

## Impact

- Modified files: `album_detail_screen.dart`, `artist_detail_screen.dart`, `main_screen.dart`, `player_provider.dart`, `audio_handler.dart`.
- Deprecated and deleted the `UniversalAdderDialog` widget.
