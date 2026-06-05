# fix-notification-controls

Fixes the issue where notification media control buttons (play, pause, next, previous) are missing or invisible on certain Android devices (especially in release builds on custom Android skins like Xiaomi's MIUI/HyperOS) by updating the resource shrinker keep rules and explicitly advertising play, pause, and stop actions in the MediaSession.
