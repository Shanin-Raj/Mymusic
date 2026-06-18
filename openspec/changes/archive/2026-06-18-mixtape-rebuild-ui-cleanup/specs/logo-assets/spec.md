# logo-assets Specification

## Purpose
Define the app icon, branding assets, and launch configurations for the Mixtape application.

## Requirements
### Requirement: Native launcher icons use the Mixtape logo brand asset
The system SHALL use the `assets/mixtapelogo.jpeg` (the Mixtape logo) as the launcher icons for the Android and iOS apps. This configuration is maintained through the `flutter_launcher_icons` package in `pubspec.yaml`, which automatically generates and replaces launcher icons across native platforms.

#### Scenario: App icon on home screen shows Mixtape logo
- **WHEN** the Flutter client is built and installed on an Android or iOS device
- **THEN** the home screen launcher icon SHALL display the Mixtape logo, not the default Flutter icon

#### Scenario: Splash screen shows Mixtape logo on app open
- **WHEN** a user opens the installed app from the home screen
- **THEN** the Android/iOS splash screen and bootstrap loading state SHALL display the Mixtape logo

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

