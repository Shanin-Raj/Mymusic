## Context

`audio_service` requires specific configuration to keep an app running in the background. The media notification must be actively updated with `MediaItem` changes and playback state. Currently, the notification isn't showing, which causes Android to kill the background service.

## Goals / Non-Goals

**Goals:**
- Display a persistent media notification during playback.
- Prevent background playback from stopping.
- Fix the shuffle logic in the player provider.
- Fix the `PlayerScreen` to dynamically update its UI and adhere to Dark Mode.
- Implement `SafeArea` across major views to prevent overlap with system navigation bars.
- Make the playlist view reactive so it updates when populated.
- Fix audio duration parsing for manually added tracks.

## Decisions

- **Decision 1: Broadcast MediaItem and PlaybackState**
  - *Rationale*: For the notification to appear, `audio_service` must have `MediaItem` and `PlaybackState` correctly broadcasted in the `SonicAudioHandler`. We will ensure `playbackEventStream` maps to `PlaybackState`.
- **Decision 2: Define Android Notification Icon**
  - *Rationale*: A missing `ic_launcher` or notification icon can prevent the notification from launching, breaking background mode entirely. We will explicitly define `androidNotificationIcon: 'mipmap/ic_launcher'` in `AudioServiceConfig`.
- **Decision 3: Reactive Player Screen**
  - *Rationale*: The `PlayerScreen` needs to wrap its core UI in a `StreamBuilder` listening to `audioHandler.mediaItem` to prevent it from getting stuck on the first tapped song.
- **Decision 4: Ensure Shuffle Mode sets `just_audio` state**
  - *Rationale*: Calling `_player.setShuffleModeEnabled(true)` and `_player.shuffle()` is required for native randomization.
- **Decision 5: System UI Safe Areas**
  - *Rationale*: Flutter draws behind status and navigation bars by default. Using `SafeArea` ensures all UI elements remain accessible.
- **Decision 6: Robust Duration Parsing**
  - *Rationale*: Non-Spotify tracks might lack a `duration_ms` or have it in a different format. Ensure `SonicAudioHandler` provides a fallback or safely parses duration to prevent the seek bar from breaking.

## Risks / Trade-offs

- **Risk**: Android 13+ requires explicit POST_NOTIFICATIONS permission.
- **Mitigation**: Add the necessary permission to `AndroidManifest.xml` and request it at runtime if needed (or rely on Flutter defaults).
