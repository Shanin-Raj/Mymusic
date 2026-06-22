# listening-room-flutter-client Specification

## Purpose
Specifies the client-side synchronization and playback control mechanics inside the Flutter application.

## Requirements

### Requirement: Room Connection and Lifecycle (WebSockets)
The Flutter client SHALL maintain a persistent Socket.io connection to synchronize playback state.

#### Scenario: Connecting with Authentication
- **WHEN** connecting to the synchronization server
- **THEN** the client retrieves the current Firebase User ID token and attaches it to the authentication payload of the socket handshake.
- **AND** the connection MUST use the `websocket` transport exclusively to bypass mobile carrier HTTP polling issues.

#### Scenario: Room Lifecycle operations
- **WHEN** the user creates a room, the client emits `create_room` and receives the generated 5-character uppercase room code.
- **WHEN** the user joins a room, the client emits `join_room` with the code.
- **WHEN** the user leaves a room, the client emits `leave_room` and disconnects.

---

### Requirement: Future-Scheduled Playback
The Flutter client SHALL schedule playback to trigger at a specific server-defined timestamp to ensure near-zero lag between users.

#### Scenario: Playback Scheduling
- **WHEN** the client receives a `PLAY_EXECUTE` or `TRACK_CHANGE_EXECUTE` event from the socket
- **THEN** the client determines the time difference `delay = targetServerTime - currentServerTime` using the synchronized server clock.
- **IF** `delay > 0`:
  - The client seeks to the target position and starts a timer for `delay` milliseconds, playing the track exactly when the timer fires.
- **IF** `delay <= 0` (the scheduled start was missed due to network delays):
  - The client calculates the offset `missedTime = -delay`.
  - The client seeks directly to `targetPosition + missedTime` and plays immediately to catch up.

---

### Requirement: Dynamic Drift Correction
The Flutter client SHALL continuously monitor and correct audio synchronization drift relative to the server clock without interrupting playback.

#### Scenario: Monitoring Playback Sync
- **WHEN** playing in a room, the client runs a check every 10 seconds.
- **THEN** it calculates `expectedPosition = startPosition + (currentServerTime - startServerTime)`.
- **AND** compares it with `actualPosition = player.position`.

#### Scenario: Drift Correction Actions
- **IF** drift is > 500ms or < -500ms:
  - Perform a hard seek to `expectedPosition`.
- **IF** drift is between 50ms and 500ms (audio is lagging):
  - Set the player playback speed to `1.05` for 2 seconds to catch up, then reset to `1.0`.
- **IF** drift is between -50ms and -500ms (audio is leading):
  - Set the player playback speed to `0.95` for 2 seconds to let others catch up, then reset to `1.0`.

---

### Requirement: State Broadcasting
The Flutter client SHALL route all user playback interactions through WebSocket intents when in an active room.

#### Scenario: User controls playback in a room
- **WHEN** the host presses play, pause, seek, or changes track
- **THEN** the client intercepts the local player control and sends a `PLAY_INTENT`, `PAUSE_INTENT`, `SEEK_INTENT`, or `CHANGE_TRACK_INTENT` event to the backend.
- **AND** does NOT perform the playback action locally until it receives the corresponding `sync_execute` broadcast from the server.
