## Why

1. **Listen Together Requirement:** The user wants to listen to music in sync with a partner in real-time, matching active songs, playback states (play/pause), and seek positions.
2. **Instant Delivery via TWA:** Because the APK is a Trusted Web Activity (TWA) that dynamically loads the web app hosted on Render, implementing the synchronization feature in the Web App codebase (`backend/public/`) allows the feature to be immediately live on the APK without requiring users to reinstall a new APK.

## What Changes

- **Backend (`backend/server.js`):**
  - Expose `GET /api/songs/:id` to fetch metadata for a single song.
  - Expose `GET /api/time` to retrieve the current server epoch time (for clock skew estimation).
  - Expose `POST /api/rooms` to create a new Firestore room document with a unique 5-character code.
  - Expose `GET /api/rooms/:roomId` to read room state.
  - Expose `POST /api/rooms/:roomId/update` to update room playback state.
  - Expose `GET /api/rooms/:roomId/stream` to pipe real-time room state changes via Server-Sent Events (SSE) using Firestore `onSnapshot`.
- **Frontend HTML & CSS (`backend/public/`):**
  - Add group icon navigation button to the home feed header.
  - Add screen markup `div#screen-room` to manage room states (create, join, active room with pulsing sync dot, leave).
  - Add CSS classes and keyframes for the pulsing sync dot.
- **Frontend JS (`backend/public/app.js`):**
  - Connect to SSE stream on room entry and parse incoming room updates.
  - Calculate server clock offset on load and compute latency-compensated playback seek target: `position + (isPlaying ? (now - updatedAt) : 0)`.
  - Use `isSyncingFromServer` flag to prevent feedback loop echo of updates.
  - Intercept local audio player event listeners (`playing`, `pause`, `seeked`) to push state changes to the room API.

## Capabilities

### New Capabilities
- `listening-room`: Created the Listening Room synchronization specification for playback control sync.
