## ADDED Requirements

### Requirement: Stream audio progressively from Telegram
The backend SHALL stream audio from Telegram to the client without buffering the entire file in memory. As each chunk is received from Telegram, the server SHALL write it to both the cache file on disk and the HTTP response.

#### Scenario: Progressive streaming on cache miss
- **WHEN** a client requests `/api/stream/:id` for a song not yet cached
- **THEN** the server SHALL start sending response headers immediately with `Content-Type: audio/mp4` and `Content-Length`
- **THEN** the server SHALL begin downloading the file from Telegram via `downloadMedia()` with a custom `Writable` stream
- **THEN** each chunk received from Telegram SHALL be written to both the cache file (`/tmp/music-cache/{id}.m4a`) and the HTTP response
- **THEN** the client SHALL receive audio data progressively as chunks arrive, without waiting for the full download to complete

#### Scenario: Serve from cache on cache hit
- **WHEN** a client requests `/api/stream/:id` for a song that is already cached on disk
- **THEN** the server SHALL serve the file directly via `streamFile()` with range request support (206 Partial Content)

### Requirement: Serialize Telegram downloads with priority queue
The backend SHALL enqueue all Telegram downloads in a FIFO queue with two priority levels. Priority 1 (stream) SHALL execute immediately. Priority 2 (precache) SHALL execute after all priority 1 downloads complete. Concurrent downloads SHALL be prevented.

#### Scenario: Stream takes priority over precache
- **WHEN** a precache download is in progress and a stream request arrives for a different song
- **THEN** the stream request SHALL be enqueued at priority 1 and SHALL execute after the current download completes
- **THEN** the precache download SHALL execute after the stream download completes

### Requirement: Support multiple audio MIME types
The `streamFile()` helper SHALL detect the audio MIME type from the file extension using a configurable map. Supported types SHALL include at least `audio/mp4` (.m4a), `audio/mpeg` (.mp3), `audio/ogg` (.ogg, .opus), `audio/flac` (.flac), `audio/wav` (.wav), `audio/aac` (.aac), and `audio/webm` (.webm). Unknown extensions SHALL default to `audio/mp4`.

#### Scenario: Correct MIME type served
- **WHEN** a file with extension `.mp3` is served
- **THEN** the response `Content-Type` header SHALL be `audio/mpeg`

### Requirement: Use WriteStream for precache downloads
The `/api/precache/:id` endpoint SHALL write downloaded audio directly to a file via `fs.createWriteStream` instead of buffering the full file in memory. The endpoint SHALL use the download queue at priority 2.

#### Scenario: Precache writes directly to file
- **WHEN** `/api/precache/:id` downloads a song
- **THEN** the data SHALL be written directly to `/tmp/music-cache/{id}.m4a` via a `WriteStream`
- **THEN** no full-file `Buffer` SHALL be allocated in memory
