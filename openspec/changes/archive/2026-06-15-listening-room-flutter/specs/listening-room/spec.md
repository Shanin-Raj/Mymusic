# Capability: listening-room

## Purpose
Enables real-time, synchronized music listening between multiple devices.

## Requirements

### Requirement: Room Lifecycle
- A user MUST be able to create a new room with a unique 5-character uppercase room code.
- A user MUST be able to join an existing room using the 5-character room code.
- A user MUST be able to copy the room code to the clipboard by clicking it.
- A user MUST be able to leave the room, closing any real-time connections.

### Requirement: Real-time Playback Sync
- When a user in the room changes the song, plays, pauses, or seeks, the state MUST be published to the room document in Firestore.
- Other connected users in the room MUST receive this state change in real-time via Server-Sent Events (SSE) from the Express backend.
- The receiving clients MUST update their active player state (song ID, play/pause, seek position) to match, applying clock-skew and latency compensation.
- The playback sync MUST use an lock indicator (`isSyncingFromServer`) to prevent infinite feedback loops between clients.
