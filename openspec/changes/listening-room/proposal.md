## Why

Users want to share their listening experience with friends in real-time. Currently, the Node.js backend already has `/api/rooms` endpoints implemented with Server-Sent Events (SSE) support, and the web client has it working. The Flutter mobile app lacks this capability. Adding this feature allows two (or more) mobile clients to join the same room and stay perfectly in sync, enriching the social experience of the app.

## What Changes

- Add a new `RoomService` in the Flutter app to handle SSE streams from `/api/rooms/:roomId/stream`.
- Add a `RoomProvider` (or update `AudioProvider`) to manage the current `roomId` and sync state.
- **Synchronization Logic:** Implement "Soft Sync". The app will listen to server events for `currentSongId`, `isPlaying`, and `position`. To prevent audio stuttering, the client will only call `seek()` if its local position diverges from the server's calculated position (server position + time elapsed since server update) by more than a defined threshold (e.g., 2 seconds).
- UI additions: A "Create Room" / "Join Room" bottom sheet or dialog, accessible from the `HomeScreen` or `NowPlayingScreen`.
- UI updates: Display the active room ID if connected. 
- Overriding playback controls: When in a room, pressing play/pause/seek will send a `POST` request to `/api/rooms/:roomId/update` to broadcast the state to other listeners.

## Capabilities

### New Capabilities
- `listening-room-flutter-client`: The ability to create, join, and leave listening rooms, and manage the SSE connection and audio synchronization logic ("Soft Sync") in the Flutter app.

### Modified Capabilities


## Impact

- **AudioProvider (`flutter_app/lib/providers/audio_provider.dart`)**: Will be heavily modified to intercept play/pause/seek commands and forward them to the room service if active, as well as applying remote state.
- **New Dependency**: May require adding a package for SSE (e.g., `flutter_client_sse` or manually handling stream via `http`).
- **UI (`flutter_app/lib/features/...`)**: `HomeScreen` and `NowPlayingScreen` will need minor additions for Room actions.
