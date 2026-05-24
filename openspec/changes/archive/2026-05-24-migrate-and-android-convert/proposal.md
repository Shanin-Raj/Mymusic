## Why

The current deployment on Google Cloud Run is fully functional, but credits are nearing depletion. To maximize the remaining credits while preparing for the future, we will maintain Cloud Run as the primary host until exhaustion, at which point we will migrate to **Render** (CC-free tier). Simultaneously, the application requires a native Android presence. Since previous attempts with Capacitor failed to preserve PWA features, we will implement a **Trusted Web Activity (TWA)** wrapper. This ensures the Android app is a perfect mirror of the PWA, preserving background playback and cloud syncing.

## What Changes

- **Phased Hosting Strategy**: Keep Cloud Run for current operations; prepare Render migration as a "switch-over" event.
- **Android TWA Shell**: Use Google's **Bubblewrap** CLI to generate a native Android container that loads the live Cloud Run PWA.
- **Trust Handshake**: Implement `/.well-known/assetlinks.json` on the current Cloud Run domain (and later on Render) to remove the browser UI and enable "Standalone" mode.
- **Manifest Hardening**: Update `manifest.json` to include Android-specific metadata required for TWA verification.
- **Local Signing**: Leverage **Android Studio Panda** to generate the final signed APK/AAB and extract the SHA256 fingerprint.

## Capabilities

### New Capabilities
- `android-twa-shell`: Establishes the native Android project structure using the TWA standard.
- `cloud-migration-readiness`: Ensures the backend is portable and ready for a zero-downtime switch to Render.

### Modified Capabilities
- `spotify-ui-redesign`: (Modified) Refine PWA manifest and meta tags for native Android compatibility.

## Impact

- **Mobile UX**: Dedicated app icon and full-screen experience on Android devices.
- **Server**: Addition of the `assetlinks.json` route to `server.js`.
- **Project Structure**: Addition of an `android/` directory containing the Bubblewrap project.
- **Future-Proofing**: The app is ready to move to Render the moment Cloud Run credits hit zero.
