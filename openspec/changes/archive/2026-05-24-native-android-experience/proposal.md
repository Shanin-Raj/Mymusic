## Why

The current Android application is a PWA wrapper, which causes web-specific artifacts that detract from a perfect native experience. Most notably, standard web gestures like pull-to-refresh inadvertently reload the app (restarting playback) and the lack of robust Media Session metadata prevents optimal lockscreen and hardware media controls. We need to implement proper web APIs (MediaSession) and CSS constraints (overscroll-behavior) within the PWA to bridge this gap, ensuring it behaves perfectly like a native Android app without sacrificing any existing UI or UX.

## What Changes

- **Overscroll Behavior Constraints**: We will disable browser-native pull-to-refresh using CSS to prevent accidental app reloads.
- **Intentional Update Mechanism**: To ensure app updates can still be applied without pull-to-refresh, we will implement a Service Worker update listener that prompts the user to refresh when a new version is detected.
- **Media Session Integration**: We will fully integrate the standard Web Media Session API to synchronize app playback state with the Android OS lockscreen, notification shade, and Bluetooth devices.
- **App Manifest Enhancements**: We will verify and enforce standalone display modes and theme colors to ensure the browser chrome is completely hidden and status bars match the UI.

## Capabilities

### New Capabilities
- `native-scroll-behavior`: Disables browser pull-to-refresh and establishes native-like scrolling constraints to prevent accidental page reloads on Android.
- `intentional-update-flow`: Provides a UI mechanism to refresh the app when updates are available, replacing the need for browser-native pull-to-refresh.
- `media-session-integration`: Enforces system-level media controls (lockscreen, notifications, and hardware keys) using the Web Media Session API.

### Modified Capabilities
- `android-twa-shell`: Expanding requirements to ensure the shell perfectly handles system UI insets and standalone display modes without fallback browser UI.

## Impact

- **UI/UX**: Vastly improved native feel on Android; no accidental restarts from pulling down.
- **System Integration**: Users can control music from the lockscreen and Bluetooth devices perfectly.
- **Code**: CSS updates for `body` and main container scroll behavior; JavaScript updates to audio playback initialization to sync with `navigator.mediaSession`.