## Context

- Resource shrinking (enabled by default in Flutter release builds) determines resource utility statically. Dynamic resource references via reflection or JNI strings (as done by many Flutter audio packages like `audio_service` to render media control button icons) are missed by static analysis, leading to critical icons being stripped out of release binaries.
- Android 13+ has completely redesigned the media controls widget. Instead of custom notification buttons, the system control panel uses the `MediaSession`'s advertised `PlaybackState` actions (`PlaybackStateCompat.ACTION_PLAY`, `ACTION_PAUSE`, etc.) to dynamically construct play/pause and skip buttons. If these actions are not explicitly enabled in the session's active configuration, some Android devices (particularly Xiaomi's MIUI/HyperOS control center) will hide the controls.

## Decisions

- **Wildcard Keep Rule in keep.xml**: Rather than listing each individual dynamic icon of the audio library, using `tools:keep="@drawable/*"` in `keep.xml` is a robust, lightweight way to prevent the Android compiler from stripping any library-provided media controls.
- **Explicit systemActions Advertisement**: Populate `systemActions` with `MediaAction.play`, `MediaAction.pause`, and `MediaAction.stop` inside the `PlaybackState` configurations of `audio_handler.dart`. This ensures the native MediaSession advertised capabilities always indicate support for these core operations.
