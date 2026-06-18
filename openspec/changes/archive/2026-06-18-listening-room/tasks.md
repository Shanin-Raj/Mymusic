## 1. Foundation & Backend Connection

- [x] 1.1 Create a new Git branch `feature/listening-room` for all development work.
- [x] 1.2 Add `http` based SSE parser or integrate an SSE package if needed, to connect to `/api/rooms/:roomId/stream`.
- [x] 1.3 Create `RoomService` in `flutter_app/lib/services/room_service.dart` with `createRoom`, `joinRoom`, `leaveRoom`, `updateState`, and `roomStream` methods.

## 2. State Management

- [x] 2.1 Create `RoomProvider` (or update `AudioProvider`) to hold the active `roomId` and expose connection state.
- [x] 2.2 Wire up the `roomStream` to listen to incoming state updates and call a `_handleRoomUpdate(RoomState state)` method.
- [x] 2.3 Implement "Soft Sync" logic in `_handleRoomUpdate`: compare `currentSongId`, `isPlaying`, and `position` (+ timestamp math) with the local `just_audio` player and apply changes if desync > 2000ms.

## 3. Broadcasting Actions

- [x] 3.1 Intercept `play()`, `pause()`, `seek()`, `skipToNext()`, `skipToPrevious()` in `AudioProvider` or `MyAudioHandler`.
- [x] 3.2 If `roomId` is active and `isSyncingFromServer` is false, broadcast these actions to `/api/rooms/:roomId/update`.

## 4. UI Implementation

- [x] 4.1 Create a `RoomBottomSheet` widget to allow creating or joining a room.
- [x] 4.2 Add a "Room" icon to the AppBar of `HomeScreen` to open the `RoomBottomSheet`.
- [x] 4.3 Add a "Room" icon or indicator to the `NowPlayingScreen` (possibly showing the room code).
- [x] 4.4 Add a "Leave Room" option when connected.

## 5. Testing & Verification

- [x] 5.1 Test room creation and verify the backend SSE connection opens successfully.
- [x] 5.2 Test joining a room from another device (or simulator + physical device) and ensure state syncs.
- [x] 5.3 Verify "Soft Sync" prevents audio stuttering during playback.
- [x] 5.4 Test edge cases: leaving room, losing network connection, host disconnects.
