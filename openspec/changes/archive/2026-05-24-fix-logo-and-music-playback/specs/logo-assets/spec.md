## ADDED Requirements

### Requirement: Logo assets use the brand vinyl record image
The system SHALL use the `musiclogo.jpeg` vinyl record logo (resized to 192×192 and 512×512) as the PWA icons referenced in `manifest.json`. The lightning bolt placeholder SHALL NOT appear as the app icon or splash screen image.

#### Scenario: App icon on home screen shows vinyl record
- **WHEN** a user installs the PWA or TWA on their Android device
- **THEN** the home screen launcher icon SHALL display the vinyl record logo, not the lightning bolt

#### Scenario: Splash screen shows vinyl record on app open
- **WHEN** a user opens the installed app from the home screen
- **THEN** the TWA/PWA splash screen SHALL display the vinyl record logo

#### Scenario: Icon files are valid PNGs at correct sizes
- **WHEN** `icon-192.png` and `icon-512.png` are served at `/icons/`
- **THEN** each file SHALL be a valid PNG, 192×192px and 512×512px respectively, containing the vinyl record design

### Requirement: Audio stream starts within acceptable latency
The `/api/stream/:id` endpoint SHALL begin delivering audio data to the client within **30 seconds** of the request. If the Telegram download does not complete within 30 seconds, the server SHALL respond with HTTP 503 and a JSON error body `{ error: true, type: "TIMEOUT", message: "..." }`.

#### Scenario: Cached track plays immediately
- **WHEN** a user clicks a track that has been previously streamed (cache file exists at `/tmp/music-cache/<id>.m4a`)
- **THEN** the server SHALL begin streaming audio bytes within **500ms**

#### Scenario: Uncached track streams after Telegram download
- **WHEN** a user clicks a track that is not yet cached
- **THEN** the server SHALL download the file from Telegram, cache it, and begin streaming
- **THEN** audio SHALL start playing in the browser within 30 seconds on a normal connection

#### Scenario: Stream timeout returns error
- **WHEN** the Telegram download does not complete within 30 seconds
- **THEN** the server SHALL abort the download and respond with HTTP 503 `{ error: true, type: "TIMEOUT" }`

#### Scenario: Range requests are honoured for seek support
- **WHEN** the browser sends a `Range` header (e.g. for seeking)
- **THEN** the server SHALL respond with HTTP 206 and the correct `Content-Range` bytes

### Requirement: Telegram client is ready before first stream request
The Telegram client SHALL be initialized at server startup (inside `start()`), not lazily on the first stream request. If initialization fails at startup, the server SHALL log the error and retry; stream requests during this window SHALL return HTTP 503.

#### Scenario: First track click does not wait for Telegram init
- **WHEN** the server has been running for at least 10 seconds and a user clicks a track
- **THEN** the Telegram client SHALL already be connected and the stream SHALL begin without an additional init delay

#### Scenario: Telegram init failure returns 503
- **WHEN** Telegram fails to connect and a stream request arrives
- **THEN** the server SHALL return HTTP 503 `{ error: true, type: "BUSY", message: "Telegram client is not ready" }`
