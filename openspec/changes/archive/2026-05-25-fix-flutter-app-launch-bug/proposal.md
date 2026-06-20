## Why

The newly built Flutter APK is crashing immediately on launch on physical Android devices. This is a critical blocker. Additionally, we need to ensure that the Flutter app remains isolated from the live TWA app during the development phase to avoid overwriting the working production app. We must "Rethink" our configuration to ensure stability before we eventually merge.

## What Changes

- **Android Manifest Updates**: Add mandatory `<service>` and `<receiver>` entries required by the `audio_service` package.
- **Permission Grants**: Explicitly add the `INTERNET` permission to the `AndroidManifest.xml` to allow the app to fetch songs and stream audio in release mode.
- **RETHINK: Application ID Isolation**: Revert the `applicationId` to a development-only ID (e.g., `com.example.sonic_vault_flutter`) so the Flutter app can be installed alongside the existing TWA app for parallel testing.
- **Metadata Update**: Fix the application name in the manifest to match "Mixtape" instead of the default scaffold name.

## Capabilities

### New Capabilities
- `android-native-stability`: Fixes the launch-time crash by aligning the Android native configuration with the requirements of the Flutter plugin ecosystem.
- `isolated-testing-config`: Configures the app to run in parallel with the production TWA app using a unique package identity.

### Modified Capabilities
- `flutter-audio-service`: Updating the implementation requirements to include the mandatory native Android service declarations.

## Impact

- **Stability**: The app will launch successfully on physical devices without "App has bug" warnings.
- **Functionality**: Streaming and background audio will become operational.
- **Safety**: The production TWA app will NOT be overwritten by the experimental Flutter build.
- **Code**: Changes are localized to the `flutter_app/android/` directory.
