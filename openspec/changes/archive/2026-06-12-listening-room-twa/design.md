## Context

- Playback synchronization across separate mobile devices needs real-time communication, low latency, and clock alignment.
- Setting up full WebSocket services (like socket.io) can be prone to proxies/restrictions on Render's free tier.
- Clock offsets between devices can lead to drifting playback sync if positions are not compensated.

## Decisions

- **Server-Sent Events (SSE) over HTTP:** We use SSE on the Express server combined with Firestore's native `onSnapshot` listener. This delivers real-time pushed updates to clients over a standard HTTP connection. It is simple, highly compatible with Render, and has minimal resource overhead.
- **Client-Agnostic REST/SSE Architecture:** The room endpoints (`POST /api/rooms`, `GET /api/rooms/:roomId/stream`, etc.) are built completely separate from the web app interface, making them fully reusable by the native Flutter client later without backend modifications.
- **Clock Sync Handshake (`/api/time`):** Compute device clock skew against the backend time to adjust the seek positions:
  `targetPosition = position + (isPlaying ? (serverNow - updatedAt) : 0)`.
- **Sync Lock Flag:** We implement an `isSyncingFromServer` boolean flag. While programmatically applying SSE updates to the local player, we set this flag to `true` to discard the player's own `playing`/`pause`/`seeked` event callbacks, preventing infinite update feedback loops.
