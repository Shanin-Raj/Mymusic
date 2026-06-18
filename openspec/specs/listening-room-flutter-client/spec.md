# listening-room-flutter-client Specification

## Purpose
TBD - created by archiving change listening-room. Update Purpose after archive.
## Requirements
### Requirement: Room Connection and Lifecycle
The Flutter client SHALL provide a mechanism to interact with the backend room API.

#### Scenario: User creates a new room
- **WHEN** user requests to create a room
- **THEN** the client sends a POST request to `/api/rooms` and begins an SSE connection to `/api/rooms/:roomId/stream` using the returned room ID.

#### Scenario: User joins an existing room
- **WHEN** user requests to join a room with a specific code
- **THEN** the client verifies the room exists via GET `/api/rooms/:roomId` and then begins an SSE connection to `/api/rooms/:roomId/stream`.

#### Scenario: User leaves a room
- **WHEN** user requests to leave the room
- **THEN** the client closes the SSE connection and stops broadcasting or receiving state updates.

### Requirement: Soft Sync Audio Playback
The Flutter client SHALL update its local playback state based on incoming SSE room updates without introducing audio stutter.

#### Scenario: Receiving song change
- **WHEN** the SSE stream broadcasts a new `currentSongId` that differs from the local `currentSongId`
- **THEN** the client fetches and plays the new song.

#### Scenario: Receiving play state change
- **WHEN** the SSE stream broadcasts an `isPlaying` state that differs from the local state
- **THEN** the client plays or pauses the audio player to match the server state.

#### Scenario: Receiving position update within threshold
- **WHEN** the SSE stream broadcasts a `position` and the calculated expected position differs from the local player's position by LESS than 2000 milliseconds
- **THEN** the client ignores the seek request to prevent stuttering.

#### Scenario: Receiving position update outside threshold
- **WHEN** the SSE stream broadcasts a `position` and the calculated expected position differs from the local player's position by MORE than 2000 milliseconds
- **THEN** the client calls `seek()` to the expected position to regain synchronization.

### Requirement: State Broadcasting
The Flutter client SHALL broadcast local playback actions to the room if connected.

#### Scenario: User performs playback action while in a room
- **WHEN** a user who is connected to a room performs a play, pause, or seek action locally
- **THEN** the client sends a POST request to `/api/rooms/:roomId/update` containing the new `currentSongId`, `isPlaying`, and `position` before or immediately alongside performing the local action.

#### Scenario: Preventing infinite update loops
- **WHEN** the client receives an SSE update and applies it locally (e.g., calling `seek` or `play`)
- **THEN** the client MUST NOT trigger a recursive broadcast back to the server for that specific automated action.

