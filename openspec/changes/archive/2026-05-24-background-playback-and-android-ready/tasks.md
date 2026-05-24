## 1. Background Playback Hardening

- [x] 1.1 Refactor the `ended` event listener in `app.js` to ensure it holds a high-priority "Audio Context" lock during the transition between tracks.
- [x] 1.2 Implement "Predictive Pre-loading": start loading the next track's URL into a secondary hidden buffer when the current track has 45 seconds remaining.
- [x] 1.3 Standardize all `MediaSession` metadata updates to occur *before* the song finishes, ensuring the Android notification panel never "loses" the app.
- [x] 1.4 **RETHINK CHECK**: Verify that `triggerPreCacheNext` still functions for both shuffle and sequential modes without breaking current "Smart Auto-Fix" metadata logic.

## 2. Android TWA Project Finalization

- [x] 2.1 Update the `android/twa-manifest.json` file to ensure the package name and app title are correctly synchronized for production.
- [x] 2.2 Run `bubblewrap update` and `bubblewrap build` to generate the latest Java source and Gradle build files.
- [x] 2.3 Guide the user through **Android Studio Panda 4** to generate the signed production APK (`Build > Generate Signed Bundle / APK`).
- [x] 2.4 **SAFE BUILD**: Ensure that the `store_icon.png` and splash screens are correctly mirrored from the latest vinyl brand logo.

## 3. Production Deployment & Verification

- [x] 3.1 Deploy the updated `app.js` and server logic to the live Cloud Run service.
- [x] 3.2 Extract the SHA256 certificate fingerprint from the final production keystore.
- [x] 3.3 Update the server's `/.well-known/assetlinks.json` with the new production fingerprint to remove the browser address bar.
- [x] 3.4 **REGRESSION AUDIT**: Verify that:
    - [x] Library still loads and re-renders on song addition.
    - [x] Playlists still support custom track collections.
    - [x] Dark Mode toggle works on all screens.
    - [x] Sideloaded APK supports automatic track advancement while the device is locked.

## 4. Future Migration Readiness (Render)

- [x] 4.1 Update `backend/firebase.js` to support loading Service Account keys from the `FIREBASE_KEY_JSON` environment variable (prepping for Render).
- [x] 4.2 Verify the `Dockerfile` is portable and does not rely on GCP-specific metadata services.
- [x] 4.3 Create a \"Migration Checklist\" for Render to ensure all 12+ secrets are correctly ported when credits expire.
