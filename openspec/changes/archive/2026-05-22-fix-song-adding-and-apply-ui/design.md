## Context

The backend uses the GramJS library to interact with Telegram for music storage. Recent logs show frequent `ETIMEDOUT` errors during the initialization and file upload phases, likely due to regional network restrictions or Data Center (DC) flakiness. The frontend is currently using an older "Bright Editorial" design that doesn't align with the desired Spotify-style visual language.

## Goals / Non-Goals

**Goals:**
- Improve GramJS connection stability by optimizing client configuration and retry logic.
- Replace the current frontend design with the "Sonic Immersion" (Spotify-style) dark theme.
- Implement clear, user-friendly error messages for the song adding process.

**Non-Goals:**
- Moving away from Telegram as the primary storage backend.
- Adding social features or multi-user accounts in this phase.

## Decisions

### 1. Robust GramJS Configuration
**Decision:** Configure the `TelegramClient` with higher `connectionRetries` (15) and explicitly handle connection events.
**Rationale:** The default settings are insufficient for high-latency or unstable networks. Increasing retries and monitoring connection status helps the server recover without crashes.
**Alternatives:** Swapping to a different Telegram library (e.g., MTProto), but GramJS is already integrated and mostly functional.

### 2. Standardized API Error Schema
**Decision:** Update the `/api/add-song` (or equivalent) endpoint to return structured JSON errors: `{ error: true, type: 'TIMEOUT', message: '...' }`.
**Rationale:** The current "Code Error 1" on the frontend is too generic. Specific error types allow the UI to provide better feedback (e.g., "Retrying connection..." vs "Invalid Spotify Link").

### 3. CSS Variable-Driven Redesign
**Decision:** Use CSS custom properties (variables) defined in `:root` for all "Sonic Immersion" tokens.
**Rationale:** Centralizing design tokens makes it easier to maintain consistency across the massive UI overhaul and allows for future theme adjustments.
**Alternatives:** Using a utility-first framework like Tailwind, but the current project is built on Vanilla CSS and a full migration would be too disruptive.

### 4. Component Integration from Stitch Designs
**Decision:** Adapt the HTML/CSS structures found in `Stitchappledesign/` for the new 5-tab navigation and mini-player.
**Rationale:** These designs represent the approved visual direction and can be surgically integrated into the existing `index.html`.

## Risks / Trade-offs

- **[Risk]** Increasing Telegram retries might lead to long-running request hangs. → **Mitigation**: Implement a per-request timeout on the backend that returns a "Slow Connection" status to the client.
- **[Risk]** UI redesign may break existing event listeners in `app.js`. → **Mitigation**: Perform a comprehensive audit of `app.js` selectors and update them to match the new HTML structure.
