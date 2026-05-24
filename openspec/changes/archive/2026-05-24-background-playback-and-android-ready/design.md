## Context

The "Music Vault" relies on the standard HTML5 `Audio` element and the `MediaSession` API for playback. On mobile devices, especially when locked, the browser's execution context is severely throttled. If a track ends, the `ended` event might not fire immediately, or the subsequent `audio.play()` call might be blocked by the OS's power-saving policies. Wrapping the app as a **Trusted Web Activity (TWA)** grants it more persistence, but the JavaScript logic must still be optimized for background transitions.

## Goals / Non-Goals

**Goals:**
- Fix automatic track advancement on the Android lockscreen.
- Standardize the `MediaSession` lifecycle to prevent the audio engine from sleeping.
- Provide a definitive guide for building the production APK in Android Studio Panda 4.
- **Preservation**: Ensure that the "Bright Editorial" design and Spotify-inspired logic remain 100% intact.

**Non-Goals:**
- Implementing a custom native Android media player (Java/Kotlin).
- Adding complex offline-first playback (keeping focus on the TWA cloud model).

## Decisions

- **Pre-emptive Metadata Injection**: Instead of waiting for a song to end, we will update the `MediaSession` state with the *next* track information 30 seconds before completion. This signals to the Android OS that the audio session is continuous.
- **Background "Heartbeat"**: We will utilize a recurring `setInterval` check that only runs when audio is active. While timers are throttled, an active audio stream usually keeps the tab context "alive" enough for simple logic.
- **Native TWA Packaging**: We will continue using **Google Bubblewrap** to generate the Android project. It is more reliable than Capacitor for PWA-centric apps because it uses the actual Chrome/System WebView engine which has the most mature `MediaSession` support.
- **Android Studio Finalization**:
  - Selection: **Android Studio Panda 4**.
  - Path: Select `Build > Generate Signed Bundle / APK` to create the final release.
  - Verification: The `assetlinks.json` must be re-verified against the production keystore's SHA256 fingerprint.

## Safety & Regression Decisions

- **Rethink Pattern**: Every logic update in `app.js` will be scoped to internal functions. We will not modify the global `audio` object's initialization or the existing `loadAppData` structure to ensure the app's startup remains fast and reliable.
- **Verification Loop**: Before any deployment, a manual verification of:
  1. Login flow
  2. Search responsiveness
  3. Library stats rendering
  ... must be performed to confirm no functional loss.

## Risks / Trade-offs

- **[Risk] Throttled Network in Background** → **Mitigation**: The pre-cache logic (`triggerPreCacheNext`) already implemented will be made more aggressive, starting the fetch earlier in the background.
- **[Risk] Autoplay Blocking** → **Mitigation**: TWA apps usually bypass autoplay blocks if the user has interacted with the app. We will ensure the first track is always user-initiated.

## Migration Plan

1.  **Frontend Logic**: Refactor `playSong` and `triggerPreCacheNext` in `app.js` to specifically target background stability.
2.  **Android Re-build**: Run `bubblewrap update` and `bubblewrap build`.
3.  **Signing**: User opens the project in Android Studio Panda 4 to generate the signed production APK.
4.  **Trust Lock**: Capture the new SHA256 and update the server-side `assetlinks.json`.
