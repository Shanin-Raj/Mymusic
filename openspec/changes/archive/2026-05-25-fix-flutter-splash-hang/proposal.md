## Why

The newly built Flutter APK is throwing a `PlatformException` on launch: *"The Activity class declared in your AndroidManifest.xml is wrong or has not provided the correct FlutterEngine."* This is a known requirement for the `audio_service` plugin on Android. The plugin needs direct access to the Flutter engine via the `MainActivity` to keep audio running in the background when the UI is detached.

## What Changes

- **Android MainActivity Override**: Update `flutter_app/android/app/src/main/kotlin/com/example/sonic_vault_flutter/dev/MainActivity.kt` to explicitly override `provideFlutterEngine` and return the `AudioServicePlugin.getFlutterEngine(context)`.

## Capabilities

### Modified Capabilities
- `flutter-audio-service`: Add the necessary Android engine bridging required by the `audio_service` plugin.

## Impact

- The Flutter app will successfully initialize the audio service and boot past the splash screen without crashing.
- Background audio controls will function correctly because the native service is now properly linked to the Flutter engine.
