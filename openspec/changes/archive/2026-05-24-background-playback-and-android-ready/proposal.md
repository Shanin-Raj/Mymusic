## Why

The application currently fails to transition to the next track automatically when the phone is locked (lockscreen). While the current track continues to play, mobile browsers often suspend the JavaScript execution environment once a song ends, preventing the `ended` event handler from initiating the next `play()` call. Transitioning to a native Android app (TWA) is the intended solution to gain higher process priority, but the app also needs specific logic to "hold" the audio context and metadata across track transitions in the background.

## What Changes

- **Background Transition Logic**: Refactor the track advancement logic to use the `MediaSession` API's `nexttrack` action and ensure the next audio source is pre-loaded before the current one ends.
- **Android Release Finalization**: Configure the existing Android TWA project for a production-ready build, including correct signing and metadata verification.
- **Connectivity Persistence**: Implement logic to handle potential network "hibernation" that occurs when a device is locked for long periods.
- **Safety Mandate**: Every modification to `app.js` or `server.js` must be preceded by a "feature integrity check" to ensure existing PWA capabilities (Firestore sync, Telegram streaming, search) are not compromised.

## Guiding Principle: Zero-Regression Stability

**CRITICAL CAUTION**: The primary objective is to *enhance* background stability without losing *any* current functionality. The implementation must "rethink" every line changed—if a code change risks the current high-fidelity playback or library management, an additive approach (new functions) must be preferred over destructive refactoring.

## Capabilities

### New Capabilities
- `background-audio-continuity`: Requirements for maintaining audio playback and automatic track advancement when the app is in the background or the screen is locked.
- `android-release-readiness`: Requirements for a production-grade Android build, including signing certificates and asset links verification.

### Modified Capabilities
- `audio-streaming`: Update requirements to include pre-loading of the next track to minimize transition gaps.

## Impact

- **Frontend JS**: Significant updates to `app.js` regarding event listeners (`ended`, `timeupdate`) and `MediaSession` handlers.
- **Android Project**: Finalization of the `android/` folder configuration for production signing.
- **Server**: Potential updates to `assetlinks.json` if a new production signing key is generated.
