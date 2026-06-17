# streaming-and-cache-fixes

Fixes the song streaming lag (30-second delays) and playback mismatch issues on the backend by introducing an active download promise map and atomic file renaming. Also replaces the manual 30-second TTL-based cache refresh mechanism with Firestore real-time snapshot listeners (`onSnapshot`) for instant library and playlist updates.
