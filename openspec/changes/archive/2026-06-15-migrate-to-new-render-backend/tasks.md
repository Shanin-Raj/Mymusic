# Tasks - Migrate to New Render Backend

- [x] Backend: Add `ignoreUndefinedProperties: true` setting to Firestore config in `backend/firebase.js`
- [x] Backend: Add `image || null` fallback inside `backend/spotify.js` and `backend/manual_add.js`
- [x] Backend: Implement 30-second TTL cache in `backend/server.js` for `getLibrary` and `getPlaylists`
- [x] CLI: Execute `node backend/main.js` and successfully add 7 songs to Firestore and Telegram
- [x] CLI: Run `node backend/backfill_images.js` and successfully fetch Spotify cover images for all 7 songs
- [x] Deployment: Set up new Render Web Service using minified single-line `FIREBASE_KEY_JSON` env variable
- [x] Configuration: Update the base backend URL to `https://mymusic-ibgr.onrender.com` in `api_service.dart`, `manifest.json`, and `twa-manifest.json`
- [x] Git: Commit changes and push to GitHub
- [x] Verification: Rebuild the Flutter release APK locally pointing to the new backend
