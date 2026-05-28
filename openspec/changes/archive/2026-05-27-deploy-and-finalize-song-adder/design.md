## Context

During manual song addition from the mobile client, the backend server processes Spotify/YouTube metadata, downloads the track, and uploads the `.m4a` file to Telegram. In a serverless production environment (Google Cloud Run), long-lived TCP connections get suspended or dropped when the CPU goes idle between client requests. Re-using a stale `TelegramClient` socket throws `TIMEOUT` errors, causing song syncs to fail silently. 

## Goals / Non-Goals

**Goals:**
- Implement an ephemeral socket connection model where `TelegramClient` is created fresh for every transaction and cleanly disconnected/destroyed immediately after.
- Streamline the Cloud Build packaging process to ignore massive non-production directories (like the entire Flutter workspace build artifacts).
- Deploy the finalized image to both the regional `music-vault` service (serving production traffic) and `sonic-vault`.

**Non-Goals:**
- Changing local DB schemas or modifying client-side API logic.
- Eliminating general Telegram upload size restrictions (e.g. 2GB max file limits).

## Decisions

### Decision: Ephemeral vs. Persistent Telegram Socket
- **Decision:** Spawn a fresh `TelegramClient` inside `telegram.js` for each transaction (`uploadToTelegram` and `deleteFromTelegram`), then disconnect/destroy in a `finally` block.
- **Alternatives Considered:** Persistent connection with auto-reconnect logic. *Rejected* because Cloud Run container execution is suspended entirely when requests are zero, causing auto-reconnect tasks to fail to run.
- **Rationale:** Ephemeral connections are 100% immune to serverless CPU suspension issues.

### Decision: Cloud Build `.gcloudignore` Optimization
- **Decision:** Explicitly ignore `flutter_app/`, `.gemini/`, `.opencode/`, and `.idea/` during GCP Cloud Builds.
- **Rationale:** Excludes 2.3+ GB of local Gradle/Flutter build artifacts, resulting in instantaneous tarball archiving and major cost/bandwidth savings.

## Risks / Trade-offs

- **[Risk]** Slightly higher latency per sync due to initial Telegram client handshake overhead.  
  *Mitigation:* Handshake takes less than 1.5 seconds, which is negligible compared to the 10-20 seconds required for media download.
