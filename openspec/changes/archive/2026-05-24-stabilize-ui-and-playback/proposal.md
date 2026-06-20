## Why

The current build of "Mixtape" contains lingering branding inconsistencies where the old logo and name persist in the Android APK and Web PWA. Additionally, critical functional bugs are impacting the user experience: music incorrectly restarts when toggling Dark Mode or liking a track, and automatic track advancement consistently stalls on the lockscreen. This change is essential to finalize the professional identity of the app and ensure reliable, uninterrupted playback in all device states.

## What Changes

- **Branding Uniformity**: Update the app name and vinyl record logo assets across `index.html`, `manifest.json`, and the Android `twa-manifest.json`.
- **Playback State Preservation**: Refactor the Dark Mode and "Like" button logic in `app.js` to decouple UI state updates from the audio engine, preventing unnecessary track restarts.
- **Dark Mode Visibility**: Adjust CSS rules to ensure the "Like" button and other player controls remain high-contrast and fully visible when the dark theme is active.
- **Lockscreen Hardening**: Implement a more robust "next-track" transition that utilizes the `MediaSession` API and pre-caching more aggressively to bypass mobile OS background throttling.
- **Zero-Regression Mandate**: Every change must be verified against the core "working" features (Telegram streaming, Firestore sync) to ensure no functional loss.

## Capabilities

### New Capabilities
- `brand-asset-sync`: Synchronization of "Mixtape" naming and vinyl logo across Web and Android packages.
- `uninterrupted-ui-state`: Preservation of audio playback position and state during theme transitions and metadata updates.

### Modified Capabilities
- `background-audio-continuity`: Hardening requirements for track advancement while the device is locked or the app is in the background.

## Impact

- **Frontend JS**: Significant logic cleanup in `app.js` (Theme toggle, Like binding, Audio event listeners).
- **Frontend CSS**: Color and visibility refinements in `styles.css` specifically for dark mode.
- **Android Configuration**: Version and branding update in `android/twa-manifest.json`.
- **Deployment**: New Cloud Run revision and a final APK rebuild in Android Studio.
