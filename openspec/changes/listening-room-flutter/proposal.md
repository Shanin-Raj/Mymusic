## Why

1. **Native Client Sync:** Following the successful deployment of the playback synchronization feature to the Web App / TWA client, we want to enable the exact same real-time Listening Room capabilities inside the native Flutter APK client.
2. **Backend Reusability:** The existing REST and Server-Sent Events (SSE) endpoints deployed on our backend are completely client-agnostic and will be reused without any server-side changes.

## What Changes

- **Frontend Services (`flutter_app/lib/services/api_service.dart`):**
  - Add `fetchSongDetail` to retrieve single song metadata by ID.
  - Add helper methods to create a room, fetch room state, update room state, and fetch server time.
- **Frontend State (`flutter_app/lib/providers/room_provider.dart`):**
  - Create `RoomProvider` to manage room lifecycle, subscription to SSE stream, latency/clock-offset calculation, and sync locks.
  - Listen to `MyAudioHandler`'s streams (`appPlaybackStateStream`, `appMediaItemStream`, `appPositionStream`). When user triggers actions (and `isSyncing` is false), publish updates to backend.
  - Apply room SSE stream changes to `MyAudioHandler` programmatically (unloading/loading songs, play/pause, seeks) while using `isSyncing = true` locks.
- **Frontend UI (`flutter_app/lib/screens/share_room_screen.dart`):**
  - Build a Listening Room settings screen with options to create or join rooms.
  - Match the theme, contrast styles, and typography of the current app, with a pulsing green indicator.
- **Frontend Shell (`flutter_app/lib/screens/main_screen.dart` & `flutter_app/lib/main.dart`):**
  - Add Room screen entry button (using `Icons.group_outlined` action button) to `HomeView`'s app bar.
  - Register `RoomProvider` in the `MultiProvider` configuration in `main.dart`.

## Capabilities

### Modified Capabilities
- `listening-room`: Fully implement the Listening Room capability (real-time sync and room controls) inside the native Flutter application.
