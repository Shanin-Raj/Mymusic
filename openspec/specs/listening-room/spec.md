# Capability: listening-room

## Purpose
Enables real-time, low-latency synchronized music listening between multiple devices utilizing WebSockets and predictive future-scheduled playback.

## Requirements

### Requirement: Room Lifecycle
- A user MUST be able to create a new room. The server will generate a unique 5-character uppercase room code.
- A user MUST be able to join an existing room using the 5-character room code.
- A user MUST be able to copy the room code to the clipboard by clicking it.
- A user MUST be able to leave the room, closing the real-time WebSocket connection.
- If all users leave a room, or if the host disconnects, the server MUST delete the room.

### Requirement: Real-time Communication (WebSockets)
- Room states and events MUST be managed via a WebSocket server (implemented using Socket.io).
- Active room configurations MUST be held in an in-memory Map on the backend server for ultra-low latency reads/writes.
- Connections MUST be authenticated using Firebase Auth tokens in the handshake headers/auth payload.

### Requirement: Event Sourcing & Latency Compensation
- When the host performs a playback control action (Play, Pause, Seek, Track Change), the host client MUST emit a `sync_intent` message over WebSockets instead of directly modifying local playback.
- The server processes the intent, calculates a `targetTimestamp` representing the future millisecond timestamp when all clients should execute the action (typically +500ms for play/seek, +1000ms for track change to allow buffer pre-fetch).
- The server MUST broadcast a corresponding `sync_execute` event to all clients in the room containing the target time and track metadata.
- Non-host users' intents are ignored to enforce host-controlled playback.

### Requirement: Clock Synchronization
- The client and server MUST participate in a custom Ping-Pong clock sync protocol.
- The client measures round-trip latency by sending `ping` frames and receiving the server's time in response.
- The client calculates and maintains a median time offset to determine the exact Server Time.
