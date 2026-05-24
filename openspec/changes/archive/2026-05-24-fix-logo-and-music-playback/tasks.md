## 1. Logo Asset Generation

- [x] 1.1 Install `sharp` as a dev dependency in `backend/` (`npm install --save-dev sharp`) or use PowerShell image resizing
- [x] 1.2 Run resize script: convert `musiclogo.jpeg` → `icon-512.png` (512×512 PNG) and `icon-192.png` (192×192 PNG)
- [x] 1.3 Copy resized PNGs to `backend/public/icons/`, overwriting the lightning bolt placeholders
- [x] 1.4 Verify the PNG files open correctly and show the vinyl record logo (visual check)

## 2. Server — Eager Telegram Initialization

- [x] 2.1 In `server.js`, move `initTelegram()` call to inside `start()` so it runs at boot, before the HTTP server begins accepting requests (or in parallel — just not lazily)
- [x] 2.2 Confirm that the `tgReady` guard in `/api/stream/:id` still returns 503 gracefully if Telegram isn't connected yet

## 3. Server — Stream Endpoint Timeout

- [x] 3.1 Wrap the Telegram download in `server.js` `/api/stream/:id` with a `Promise.race` against a 25-second timeout promise
- [x] 3.2 On timeout: abort and return `res.status(503).json({ error: true, type: 'TIMEOUT', message: 'Telegram download timed out. Try again.' })`
- [x] 3.3 Ensure the existing range-request support (`streamFile`) still works after the timeout wrapper is added

## 4. Frontend — Playback Error Feedback

- [x] 4.1 In `app.js`, update the `audio.play().catch()` handler to show a user-visible toast/alert when stream fails (currently only logs to console)
- [x] 4.2 Add an `audio.addEventListener('error', ...)` handler that shows \"Failed to load track — tap to retry\" message near the mini-player

## 5. Verification & Deploy

- [x] 5.1 Test locally: run `node server.js` and click a track — confirm audio plays within a few seconds
- [x] 5.2 Verify the icons look correct in the browser by opening `/icons/icon-512.png` and `/icons/icon-192.png`
- [x] 5.3 Redeploy to Cloud Run (`gcloud builds submit` + `gcloud run deploy`)
- [x] 5.4 Open the deployed app on Android — confirm vinyl record logo appears on splash and launcher
- [x] 5.5 Click a track on the deployed app — confirm audio plays within 30 seconds on first play, within 1 second on subsequent plays (cached)
