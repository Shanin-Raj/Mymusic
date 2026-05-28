## 1. Native Scrolling and PWA Manifest Enhancements

- [x] 1.1 Update global CSS (e.g., `styles.css`) to add `overscroll-behavior-y: none;` to the `body` and `html` tags.
- [x] 1.2 Verify that main scrollable containers (like lists/playlists) still scroll properly with `overflow-y: auto;`.
- [x] 1.3 Audit `public/manifest.json` to ensure `display: "standalone"` and `theme_color` / `background_color` are correctly configured to match the UI.

## 2. Intentional Update Mechanism

- [x] 2.1 Update Service Worker registration in `index.html` to listen for the `updatefound` event and track the installing worker.
- [x] 2.2 Implement a UI notification (e.g., a \"New Version\" button in the Settings or a toast) that appears when a Service Worker is in the `waiting` state.
- [x] 2.3 Bind a click handler to the update button that calls `window.location.reload()`.

## 3. Web Media Session Integration

- [x] 3.1 Update the audio playback initialization logic (e.g., in `app.js` or `player.js`) to set `navigator.mediaSession.metadata` with the current track's title, artist, and artwork.
- [x] 3.2 Register Media Session action handlers for `play` and `pause` to interact with the internal player state.
- [x] 3.3 Register Media Session action handlers for `previoustrack` and `nexttrack`.
- [x] 3.4 Register a Media Session action handler for `seekto` to update the audio element's `currentTime`.

## 4. End-to-End Verification

- [x] 4.1 Test the application in a mobile environment or Chrome DevTools to ensure pull-to-refresh is disabled.
- [x] 4.2 Verify the update notification appears by simulating a Service Worker update in DevTools.
- [x] 4.3 Test Media Session integration using Chrome's global media controls or an Android device to confirm lockscreen metadata and button functionality perfectly mirror the app's state.