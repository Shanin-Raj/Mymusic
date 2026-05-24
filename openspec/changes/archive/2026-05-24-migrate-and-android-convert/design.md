## Context

The "Music Vault" is a premium PWA running on Google Cloud Run. As credits expire, a migration to a platform like Render is planned. However, the immediate priority is converting the PWA into a native Android application. Previous attempts with Capacitor failed because it creates a isolated WebView that often breaks Service Worker caching and MediaSession controls. To avoid this, we will use **Trusted Web Activity (TWA)**, which uses the system's actual Chrome browser to render the app, guaranteeing 100% feature parity.

## Goals / Non-Goals

**Goals:**
- Wrap the live Cloud Run PWA in a **TWA container** via Google's **Bubblewrap**.
- Implement the **Digital Asset Links** trust protocol on the current server to hide the URL bar.
- Generate a signed Android APK using **Android Studio Panda**.
- Ensure the backend code is portable and ready for a future Render migration.

**Non-Goals:**
- Migrating to Render *immediately* (only once Cloud Run expires).
- Rewriting any PWA logic for native Android.

## Decisions

- **Conversion Strategy**: **Bubblewrap (TWA)**. Unlike Capacitor, TWA is a verified link between a website and a native app. It uses the installed browser engine directly, which means things like "Save to Homescreen," "Background Playback," and "Offline Caching" work exactly as they do in Chrome.
- **Phased Implementation**:
  - **Phase 1 (Now)**: Android Shell + Trust Verification on Cloud Run.
  - **Phase 2 (Future)**: Porting Docker/Secrets to Render and re-verifying the Asset Links.
- **Trust Handshake**: We will add a JSON endpoint in `server.js` to serve `assetlinks.json`. This is required by Android to confirm the app owner is the same as the website owner.

## Risks / Trade-offs

- **[Risk] Browser Dependency**: TWA requires Chrome to be installed on the user's phone.
  - *Mitigation*: Chrome is the default on 99% of Android devices.
- **[Risk] Future Domain Change**: If the URL changes during the Render migration, the Android app will need a minor update.
  - *Mitigation*: We will use environment variables for the production URL in the Android config to make updates quick.

## Migration Plan (Phased)

1.  **Server Hardening**: Add the `assetlinks.json` route to `server.js` and deploy to Cloud Run.
2.  **Android project**: Initialize **Bubblewrap** against the current Cloud Run URL.
3.  **Local Build**: Open the project in **Android Studio Panda**, generate a signing key, and build the APK.
4.  **Verification**: Update the server with the APK's SHA256 fingerprint to enable full-screen mode.
5.  **Final Polish**: Verify background play and PWA syncing work perfectly within the Android shell.
