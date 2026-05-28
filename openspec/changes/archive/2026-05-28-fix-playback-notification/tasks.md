## 1. Setup Permissions and Configurations

- [x] 1.1 Add permission_handler package and trigger runtime notification prompts on startup
- [x] 1.2 Update compile and target SDK versions inside gradle build properties to comply with Android 14

## 2. Sync Streams and Render Drawables

- [x] 2.1 Bind playbackEventStream and playerStateStream to ensure immediate notification updates
- [x] 2.2 Synchronously emit playing/paused state updates in play() and pause() to bypass Android 12+ Foreground Service blocks
- [x] 2.3 Retain stenciled vector drawable ic_notification.xml to comply with status bar transparency rules
- [x] 2.4 Refresh the notification channel ID to audio_v3 to override old silent/minimized system profiles

## 3. Layout Padding & MiniPlayer Polish

- [x] 3.1 Remove SafeArea wrappers from MiniPlayer inside AlbumDetailScreen and ArtistDetailScreen
- [x] 3.2 Implement flat bottom paddings on empty playlist and add songs triggers to clear the MiniPlayer without safe area black blocks
- [x] 3.3 Keep the "Add Songs" bottom sheet open during multiple additions to allow continuous song adding
- [x] 3.4 Integrate a functional three-dot PopupMenuButton globally to add songs to Liked Songs, custom Playlists, or active Play Queue
- [x] 3.5 Build the "Liked Songs" library filter view to list only favorites with a shuffle-play header
- [x] 3.6 Display active green heart status toggles next to the three-dot options on all liked songs listing items

## 4. Verification

- [x] 4.1 Verify release APK compiles successfully
