## 1. Branding & Identity Lockdown

- [x] 1.1 Update `index.html` title tag to "Mixtape" and ensure the favicon/app-icon references the vinyl record logo.
- [x] 1.2 Overwrite `manifest.json` application name to "Mixtape" and confirm all icon sizes point to the latest vinyl assets.
- [x] 1.3 Sync `android/twa-manifest.json` with the name "Mixtape" and verify the `iconUrl` and `maskableIconUrl` are correct for production.

## 2. Audio State Preservation (Frontend)

- [x] 2.1 Refactor `app.js` to extract `renderFavoriteIcon()` from `playSong()`, allowing purely visual updates to the Like button.
- [x] 2.2 Refactor the Theme toggle logic in `app.js` to exclude any calls to `playSong()`, ensuring the audio context remains untouched.
- [x] 2.3 Update the Favorite button click handler to perform the Firestore update and call `renderFavoriteIcon()` without restarting the stream.

## 3. Dark Mode & Visibility Polish

- [x] 3.1 In `styles.css`, audit the `body.dark-mode` block and explicitly set the color of all `.player-extras` buttons to ensure 100% visibility.
- [x] 3.2 Verify that the "Like" icon uses a high-contrast theme (Primary Red or White) when dark mode is active.

## 4. Lockscreen Hardening & Pre-caching

- [x] 4.1 Update `app.js` to trigger the `precache` fetch 45 seconds before the current track finishes.
- [x] 4.2 Hardened `MediaSession` integration: ensure `playbackState` is updated to 'playing' or 'paused' every time the engine state changes.
- [x] 4.3 **SAFETY RETHINK**: Double-check the `ended` listener registration to ensure only one listener exists globally, preventing multiple track skips in the background.

## 5. Android Finalization & Deploy

- [x] 5.1 Re-run `bubblewrap build` in the `android/` directory to generate the APK with finalized branding.
- [x] 5.2 Provide instructions for the user to generate the signed production APK in **Android Studio Panda 4**.
- [x] 5.3 Deploy the updated application to Cloud Run with a `v41` cache-busting version.
- [x] 5.4 **REGRESSION AUDIT**: Manually verify:
    - [x] Library still loads and re-renders on song addition.
    - [x] Playlists still support custom track collections.
    - [x] Search functionality remains instant.
