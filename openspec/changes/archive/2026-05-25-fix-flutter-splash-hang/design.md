## Context

The `audio_service` plugin requires a persistent `FlutterEngine` to run background tasks even when the main Flutter Activity is destroyed (e.g., when the app is swiped away but music is still playing). By default, a standard `FlutterActivity` creates its own engine that dies with the Activity. 

## Goals / Non-Goals

**Goals:**
- Fix the `PlatformException` during `AudioService.init()`.
- Bridge the `AudioServicePlugin` to the `MainActivity`'s engine lifecycle.

## Decisions

- **Decision 1: `provideFlutterEngine` Override**
  - *Rationale*: By overriding this method in `MainActivity.kt`, we tell the Android system to use the persistent engine managed by `audio_service` rather than creating a temporary one. This satisfies the plugin's requirement and stops the crash.

## Risks / Trade-offs

- **Risk**: Kotlin syntax errors during the modification.
- **Mitigation**: We will ensure the correct imports (`io.flutter.embedding.engine.FlutterEngine` and `com.ryanheise.audioservice.AudioServicePlugin`) are added to the file.
