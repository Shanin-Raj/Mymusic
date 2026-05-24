## Why

The app currently shows a lightning bolt icon (the old default) instead of the actual Limitless brand logo (vinyl record with waveform signature). Additionally, music does not play when a track is clicked — the UI opens the player screen correctly but audio never starts. This breaks the core value of the app.

## What Changes

- **Replace app icons**: Swap `icon-192.png` and `icon-512.png` in `backend/public/icons/` with the actual `musiclogo.jpeg` brand logo (vinyl record design), resized and converted to PNG.
- **Update splash screen logo**: The TWA splash screen / PWA splash shown on app open uses these same icon files — updating them fixes the startup logo too.
- **Fix music playback**: The `/api/stream/:id` endpoint downloads the full audio file from Telegram before sending any bytes to the browser. On Cloud Run, this causes a long silent wait (or timeout) before audio starts. Fix by streaming the Telegram download directly to the HTTP response in chunks, instead of buffering the entire file first.
- **Fix Telegram client lazy init**: `initTelegram()` is called lazily on first stream request, adding several seconds of delay. Pre-warm the client at server startup instead.

## Capabilities

### New Capabilities
- `logo-assets`: Updated icon assets (192px, 512px PNG) derived from `musiclogo.jpeg`, used by the PWA manifest, splash screen, and TWA/Android launcher.

### Modified Capabilities
- `audio-streaming`: The stream endpoint (`/api/stream/:id`) must begin sending audio bytes to the client as Telegram downloads them, not after the full file is buffered. This is a behavioral requirement change — the endpoint must support progressive/range streaming.

## Impact

- `backend/public/icons/icon-192.png` — replaced
- `backend/public/icons/icon-512.png` — replaced
- `backend/server.js` — `/api/stream/:id` rewritten to pipe/stream instead of buffer; `initTelegram()` called eagerly at startup
- `backend/public/manifest.json` — no structural changes needed (already references `/icons/icon-512.png`)
- Requires redeploy to Cloud Run for changes to take effect
