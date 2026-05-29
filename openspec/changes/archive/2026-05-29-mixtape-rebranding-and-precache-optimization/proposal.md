## Why

1. **App Rebranding**: The user requested that the app be renamed to **MixTape** and use their custom green logo on a black background for launch and UI headers, establishing a premium look.
2. **UI Flickering**: Interactive actions (play, pause, skip, liked toggles) triggered widget rebuilds that recreated `FutureBuilder` futures, causing instant loading transitions and aggressive UI flashing.
3. **Release Crash**: The Android Gradle compiler's resource shrinker stripped the dynamically referenced `'drawable/ic_notification'` resource, throwing an `IllegalArgumentException` and crashing the release build on startup.
4. **Pre-Caching Lag**: The old background audio system polled track positions constantly (wasting CPU) and only started pre-caching the next track in the final 44 seconds of playback.

## What Changes

- Add `flutter_launcher_icons` to dev dependencies.
- Configure `flutter_launcher_icons` inside `pubspec.yaml` to process `assets/mixtape_logo.jpeg` with a `#000000` (black) background for Android adaptive icons.
- Rename visible `MaterialApp` title in `main.dart` and the application `android:label` in `AndroidManifest.xml` to **MixTape**.
- Update queue and notification album tags in `player_provider.dart` from **Sonic Vault** to **MixTape**.
- Refactor `ApiService` to cache and return the exact same synchronous `Future` instances for `fetchSongs()` and `fetchPlaylists()` to prevent `FutureBuilder` from resetting its connectionState, achieving flicker-free list rebuilds.
- Create [keep.xml](file:///d:/music/flutter_app/android/app/src/main/res/raw/keep.xml) to explicitly preserve `@drawable/ic_notification` during resource shrinking in release builds.
- Refactor `audio_handler.dart` to trigger next-track pre-caching **instantly at play start** via the `currentIndexStream` change event, completely removing the old position-based 44-second listener.

## Capabilities

### Modified Capabilities
- `brand-asset-sync`: Fully rebranded the app metadata, labels, and launch graphics to **MixTape**.
- `uninterrupted-ui-state`: Stabilized future rebuilds using Future Caching, preventing loading indicators and list flickering.
- `background-audio-notification`: Prevented release-mode foreground service launcher crashes via resource keeping.
- `playback-responsiveness`: Aggressively pre-cache upcoming tracks at playback start, guaranteeing instant, lag-free transitions.
