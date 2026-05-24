## 1. Phase 1: Android Shell & Trust Verification (Now)

- [x] 1.1 Implement the `/.well-known/assetlinks.json` endpoint in `backend/server.js` to serve the TWA trust verification file.
- [x] 1.2 Update `backend/public/manifest.json` with the required `related_applications` and `prefer_related_applications: true` properties.
- [x] 1.3 Update metadata in `index.html` (theme-color, manifest link) to ensure perfect Android blending.
- [x] 1.4 Perform a \"Pre-Android\" deployment to Cloud Run to make the trust file live.

## 2. Phase 2: Android Project Generation (Bubblewrap)

- [x] 2.1 Initialize the **Bubblewrap** configuration locally using the current production Cloud Run URL (`bubblewrap init`).
- [x] 2.2 Generate the Android project structure, including icons and splash screens automatically derived from the PWA manifest (`bubblewrap build`).
- [x] 2.3 Provide a \"Manual Handover Guide\" for opening this project in **Android Studio Panda** and creating the initial **Signing Keystore**.

## 3. Phase 3: Locking the Trust Handshake

- [x] 3.1 Extract the **SHA256 Fingerprint** from the new keystore.
- [x] 3.2 Update the `assetlinks.json` on the server with the actual fingerprint to hide the browser bar.
- [x] 3.3 Re-deploy the backend to Cloud Run one last time to finalize the native lock.

## 4. Phase 4: Future Migration Readiness (Render)

- [x] 4.1 Update `backend/firebase.js` to support loading Service Account keys from the `FIREBASE_KEY_JSON` environment variable (prepping for Render).
- [x] 4.2 Verify the `Dockerfile` is portable and does not rely on GCP-specific metadata services.
- [x] 4.3 Create a \"Migration Checklist\" for Render to ensure all 12+ secrets are correctly ported when credits expire.
