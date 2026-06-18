## Context

The backend `/api/rooms` endpoints are already implemented and tested with the web client. The goal is to bring this experience to the Flutter mobile app. Mobile clients face unique challenges such as background execution, potential latency spikes, and audio stuttering if we try to naively seek every time the server broadcasts a position update. 

## Goals / Non-Goals

**Goals:**
- Enable Flutter users to create, join, and leave listening rooms.
- Synchronize playback state (playing, paused, current song, seek position) with the room host/other users.
- Ensure audio playback remains smooth (no stuttering) during normal playback.

**Non-Goals:**
- Implementing a voice chat or text chat in the room.
- Changing the backend room logic (we will adapt to the existing SSE backend).

## Decisions

**1. SSE Implementation:**
*Decision:* We will handle Server-Sent Events by sending an HTTP `GET` request using the `http` package and listening to the stream directly (e.g., `request.send().then((response) => response.stream...)`).
*Rationale:* Avoids adding unnecessary third-party packages for a simple line-delimited stream.
*Alternative:* Use a package like `flutter_client_sse`. We might use this if parsing raw bytes proves too complex, but custom parsing is usually lightweight enough.

**2. Soft Synchronization Strategy:**
*Decision:* When receiving a state update via SSE:
- If `currentSongId` changes, load the new song.
- If `isPlaying` changes, play or pause accordingly.
- If `position` is received, we calculate the expected current position: `server_position + (current_time_ms - server_updatedAt_ms)`. If our local `just_audio` player's position differs from this calculated position by more than **2000 milliseconds** (2 seconds), we call `seek()`. Otherwise, we ignore it to prevent micro-stutters.
*Rationale:* Network latency means the `position` sent by the server is already stale by the time we receive it. We use the `updatedAt` timestamp (if the server uses standard UTC timestamps) to compensate. A 2-second threshold strikes a balance between keeping clients "together" and allowing seamless playback.

**3. State Broadcasting:**
*Decision:* Any play, pause, or manual seek action by a user currently in a room will trigger a `POST /api/rooms/:roomId/update` call before (or parallel to) executing locally.
*Rationale:* Keeps all clients in the room updated.

**4. UI Integration:**
*Decision:* Add a "Room" icon button on the `HomeScreen` app bar and the `NowPlayingScreen`. Tapping it opens a `BottomSheet` where the user can either "Create Room" or enter a code to "Join Room". Once connected, the room code is displayed.

**5. Development Workflow (Safety Feature):**
*Decision:* All code changes for this feature will be developed in a separate new Git branch (e.g., `feature/listening-room`). 
*Rationale:* Ensures that the current working state of the app is completely unaffected on the main branch. If any issues arise or if the feature breaks existing functionality, we can safely and easily revert to the previous state by abandoning or reverting the branch.

## Risks / Trade-offs

- **Risk:** Time drift between server clock and client clock. 
  *Mitigation:* If `updatedAt` relies on absolute server time, and the client clock is wildly off, the offset calculation will be wrong. We can mitigate this by ignoring `updatedAt` calculation and just assuming network transit is negligible (e.g., ~100ms), checking if the difference between local position and server `position` > 2 seconds. Given the typical use case, ignoring the exact `updatedAt` diff might actually be safer if clocks are desynced. We will test this.
- **Risk:** Infinite loop of state updates. (Server sends "Play", client plays, client broadcasts "Play" back to server, etc.)
  *Mitigation:* Set a local flag `isSyncingFromServer = true` when applying a server update, so we don't broadcast that resulting local state change back to the server.
