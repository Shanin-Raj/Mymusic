## Why

1. **R8/Proguard Resource Stripping:** In release builds, the Android compiler runs resource shrinking (`shrinkResources true`). Because `audio_service` references its built-in media control icons (play, pause, next, previous) dynamically via Dart strings rather than static XML, R8 identifies them as unused and strips them, making them appear as blank or missing spaces in notifications.
2. **MediaSession Actions Compatibility:** Android 13+ and some custom Android skins (like Xiaomi's MIUI/HyperOS) build their media control widgets directly from the advertised actions of the native `MediaSession`. If the session does not explicitly declare support for `MediaAction.play`, `MediaAction.pause`, and `MediaAction.stop` in its active state capabilities (systemActions), the system UI may fail to display the play/pause toggle button or hide the control panel buttons entirely.

## What Changes

- Update [keep.xml](file:///d:/music/flutter_app/android/app/src/main/res/raw/keep.xml) to keep all drawables (`tools:keep="@drawable/*"`) instead of just `ic_notification`, protecting the dynamically loaded `audio_service` button icons from release-mode tree-shaking.
- Modify [audio_handler.dart](file:///d:/music/flutter_app/lib/audio_handler.dart) to explicitly add `MediaAction.play`, `MediaAction.pause`, and `MediaAction.stop` to the `systemActions` sets in both `_init()` and `_transformState()`.
- Update the native background audio service specification in `openspec` to reflect these requirements.

## Capabilities

### Modified Capabilities
- `native-background-audio-service`: Updated requirements for notification icon, keeping drawable resources from R8 tree-shaking, and advertising explicit play/pause/stop actions to the native MediaSession for full Android device compatibility.
