# Local Audio Cache

## Purpose

Pre-download upcoming songs to local storage for zero-latency playback, and manage the cache lifecycle through inactivity timeouts and app lifecycle events.

## Requirements

### Requirement: Pre-download next song to local storage
When a song starts playing in `AudioHandler`, the system SHALL immediately begin downloading the next queued song's audio to local storage at `{appDocDir}/audio_cache/{songId}`. Once the download is complete, the `AudioSource` for that song SHALL be replaced from a streaming URL to a local file source.

#### Scenario: Next song cached on current song start
- **WHEN** a new song begins playback (current index changes)
- **THEN** the system SHALL trigger `AudioCacheService.downloadSong()` for the next song in the queue
- **THEN** the downloaded audio SHALL be saved to `{appDocDir}/audio_cache/{songId}`

#### Scenario: Playback uses local file when cached
- **WHEN** the pre-downloaded song is about to play and the local file exists
- **THEN** the `AudioHandler` SHALL use `AudioSource.file(localPath)` instead of the streaming URL
- **THEN** playback SHALL read from the local file with zero network latency

### Requirement: Auto-clear cache on inactivity
The `AudioCacheService` SHALL track playback activity via a `touch()` method called on every playback action. If no activity is detected for 15 consecutive minutes, the cache directory SHALL be cleared. The timer SHALL reset on every touch.

#### Scenario: Cache cleared after inactivity
- **WHEN** no playback activity occurs for 15 minutes
- **THEN** all cached audio files under `{appDocDir}/audio_cache/` SHALL be deleted

#### Scenario: Activity resets inactivity timer
- **WHEN** `touch()` is called during a download or playback action
- **THEN** the 15-minute inactivity timer SHALL be reset

### Requirement: Clear cache on app lifecycle event
The Flutter app SHALL clear the audio cache when the app lifecycle transitions to `detached` (removed from recents / task switcher).

#### Scenario: Cache cleared on app removal
- **WHEN** the app is removed from the recents list (swiped away)
- **THEN** the `AppLifecycleState.detached` event SHALL trigger cache cleanup
- **THEN** all cached audio files under `{appDocDir}/audio_cache/` SHALL be deleted
