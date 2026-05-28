## Context

The current application is a Progressive Web App (PWA) wrapped as a Trusted Web Activity (TWA) via Bubblewrap to create an Android APK. While the initial setup works, the app still exhibits web-like behaviors on Android. Specifically, pull-to-refresh is enabled by default, causing the application to reload if a user swipes down from the top. Additionally, the lack of robust integration with the standard Web Media Session API means that Android system controls (lockscreen, notification shade, hardware keys) do not reliably interact with the playing audio. Our context requires maintaining a single PWA codebase while improving the native Android experience via standard web capabilities that the TWA wrapper respects.

## Goals / Non-Goals

**Goals:**
- Eliminate accidental app reloads on Android by disabling browser-native pull-to-refresh.
- Ensure audio playing in the app correctly displays metadata (title, artist, artwork) on the Android lockscreen.
- Ensure audio playback can be controlled (play, pause, next, previous, seek) via lockscreen controls, notification actions, and Bluetooth/hardware keys.
- Ensure the app launches and operates without any fallback browser UI visible.

**Non-Goals:**
- Rewriting the application in native Android (Kotlin, Jetpack Compose) or Flutter.
- Restructuring the backend logic or audio source infrastructure.
- Introducing a completely new music player UI (maintaining existing UI elements, just fixing behavior constraints).

## Decisions

- **Decision 1: CSS Overscroll Behavior to Prevent Pull-to-Refresh**
  - *Rationale*: We will apply `overscroll-behavior-y: none;` to the `body` and `html` elements. This is a lightweight, standard CSS solution that stops the browser from initiating its default pull-to-refresh action.
  - *Alternatives Considered*: Listening to touch events in JavaScript and calling `preventDefault()` was considered but dismissed as it can interfere with standard vertical scrolling in list views and is generally less performant than the native CSS property.

- **Decision 2: Comprehensive Web Media Session API Implementation**
  - *Rationale*: The `navigator.mediaSession` API is explicitly designed for this use case and is fully supported by Android TWA. We will add a centralized handler that updates `mediaSession.metadata` whenever the track changes and hooks up action handlers (`play`, `pause`, `previoustrack`, `nexttrack`, `seekto`).
  - *Alternatives Considered*: Attempting a native Android service bridge via custom TWA plugins. This was rejected because the standard Web Media Session API is simpler to maintain and natively supported by Chrome/TWA without custom Java/Kotlin code.

- **Decision 3: Intentional Update Mechanism via Service Worker**
  - *Rationale*: Since browser-native pull-to-refresh will be disabled to prevent accidental reloads, we need an intentional way for users to apply app updates. We will modify the Service Worker registration to detect `waiting` workers and show a "New Version Available" toast or button that triggers a clean reload.
  - *Alternatives Considered*: Leaving pull-to-refresh enabled. Rejected as it frequently interrupts playback when users just want to scroll up.

- **Decision 4: Android TWA Manifest Tweaks**
  - *Rationale*: Verify `display: "standalone"` or `"fullscreen"` in `manifest.json` and ensure TWA `twa-manifest.json` is configured properly.
  - *Alternatives Considered*: Continuing with current configurations. This is rejected since we must guarantee a seamless native feel.

## Risks / Trade-offs

- **Risk: Overscroll CSS affects valid scrolling** → *Mitigation*: We will apply `overscroll-behavior-y: none` strictly on the root container/body and allow standard `overflow-y: auto` inside main content areas like playlists.
- **Risk: Users missing updates without pull-to-refresh** → *Mitigation*: The in-app update notification will be more prominent and less destructive than an accidental full-page reload.
- **Risk: MediaSession actions desyncing from internal player state** → *Mitigation*: Ensure all MediaSession action handlers invoke the exact same internal player methods (e.g., `playTrack()`, `pauseTrack()`) as the UI buttons, maintaining a single source of truth.