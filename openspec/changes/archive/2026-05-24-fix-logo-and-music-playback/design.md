## Context

The app is a PWA (Mixtape) deployed on Cloud Run and wrapped as an Android TWA. Two issues exist:

1. **Wrong logo**: The icon files (`icon-192.png`, `icon-512.png`) contain a lightning bolt placeholder. The actual brand logo (`musiclogo.jpeg` — vinyl record with waveform signature) needs to replace them. These icons are used by the PWA manifest for the home screen launcher, the splash screen on load, and the TWA/Android app icon.

2. **Music not playing**: The `/api/stream/:id` endpoint fetches the audio file from Telegram using `tgClient.downloadMedia()`, which **downloads the entire file into memory** before writing it to disk and only then responding to the HTTP request. On Cloud Run (with cold starts and network latency to Telegram), this means the browser's `<audio>` element sits waiting for 10–30 seconds with no data — it may time out or the user gives up. Additionally, `initTelegram()` is called lazily (on first stream request), adding 3–5 seconds to the very first play.

## Goals / Non-Goals

**Goals:**
- Replace lightning bolt icons with the actual vinyl record brand logo at 192×192 and 512×512 PNG
- Make audio start playing within 2–3 seconds of clicking a track
- Fix Telegram client cold start delay by initializing eagerly at server startup
- Stream audio progressively so the browser can start buffering immediately

**Non-Goals:**
- Redesigning the player UI (it works well)
- Changing the audio format (M4A/MP4 stays)
- Handling offline/service-worker audio caching (future work)
- Building a transcoding pipeline

## Decisions

### Decision 1: Icon generation via Node.js `sharp` (or PowerShell fallback)

`musiclogo.jpeg` is already square and visually clean. It needs to be resized to 512×512 and 192×192 and saved as PNG.

- **Chosen**: Use PowerShell `System.Drawing` or a simple Node.js script with `sharp` (installed as a dev dependency) to resize and convert. If `sharp` is unavailable, use ffmpeg which is available on Cloud Build.
- **Alternative**: Upload the JPEG as-is and reference it in the manifest. Rejected — manifest requires PNG for maximum compatibility, and 512px is needed for Play Store.

### Decision 2: Stream Telegram audio progressively via `downloadMedia` with a writable stream

The `gramjs` (`telegram` npm package) `downloadMedia` API supports a `outputFile` parameter that can be a writable stream path or a `Buffer`. The current code writes to `/tmp` and then responds.

- **Chosen**: Download to the cache file path as before, but use a **streaming approach**: pipe the download to the response simultaneously using `fs.createWriteStream` piped to `res` while writing. Since `gramjs` doesn't natively support piping to a writable stream mid-download, the most reliable fix is:
  1. If cache file already exists → serve it immediately with range support (already works ✅)
  2. If not cached → start download, write to temp file, then stream the completed file
  3. Add a **timeout of 25 seconds** — if Telegram doesn't respond, return a 503 with a user-friendly error instead of hanging
  4. Add **response headers early** (`Transfer-Encoding: chunked` or just respond after download) — this is acceptable since Cloud Run has a 60s timeout
- **Alternative**: Use Telegram Bot API `getFile` + direct HTTPS proxy to stream bytes. More complex, requires bot token flow. Rejected for now.
- **Alternative**: Use `gramjs` iterator-based download (`iterDownload`) to chunk bytes and pipe them live. This is the ideal long-term solution but adds complexity. Deferred to future.

### Decision 3: Eager Telegram client initialization

Currently `initTelegram()` is called on the first stream request. This causes a 3–8 second delay on the first play.

- **Chosen**: Call `initTelegram()` inside `start()` before the server starts accepting requests (already structured this way in `start()` — just reorder). The server will be "ready" faster since Cloud Run health checks don't wait for Telegram; we accept the tradeoff that if Telegram is slow to connect, the first N seconds of server life may return 503s on stream.
- **Alternative**: Keep lazy init but warm it up via a periodic health ping. Adds complexity. Rejected.

## Risks / Trade-offs

- **[Risk] Large file download blocking response**: If a song is 8MB and Telegram download takes 15s, the browser waits 15s before audio starts.
  → **Mitigation**: 25s timeout on stream endpoint; serve from cache on subsequent plays (works perfectly once cached).

- **[Risk] Cloud Run instance eviction clears `/tmp/music-cache`**: Cache is lost on each new instance, causing re-downloads.
  → **Mitigation**: Accepted trade-off. Cache works well per-instance. Long-term fix is GCS — not in scope.

- **[Risk] Sharp not available as prod dependency**
  → **Mitigation**: Use PowerShell `Add-Type System.Drawing` locally to generate PNGs before deploying; commit PNG files directly to the repo.

## Migration Plan

1. Generate icon PNGs locally from `musiclogo.jpeg`
2. Replace `backend/public/icons/icon-192.png` and `icon-512.png`
3. Fix `server.js` — add stream timeout, reorder `initTelegram()` to be called eagerly
4. Redeploy to Cloud Run
5. Verify: open app → see new logo on splash → click a track → audio starts within 5s
